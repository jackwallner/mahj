import Foundation

/// A teacher's class, as the server describes it. Jack writes these rows by
/// hand (`supabase/migrations/20261125120000_class_codes.sql`); the teacher
/// tells him which room to push this week and he changes `focus_room`.
struct TeacherClass: Codable, Equatable, Sendable {
    let code: String
    let name: String
    let focusRoomID: String

    /// The room the teacher wants this week. Nil for an id this build does
    /// not know, so Home shows nothing rather than a dead card.
    var focusRoom: Room? { DrillLibrary.rooms.first { $0.id == focusRoomID } }
}

/// What players type or scan, cleaned up so "okl-ets " and "OKLETS" are the
/// same code. Letters and digits only, 4 to 12 of them, as the table allows.
enum ClassCode {
    static func normalized(_ raw: String) -> String? {
        let kept = raw.uppercased().unicodeScalars.filter {
            ("A"..."Z").contains($0) || ("0"..."9").contains($0)
        }
        let code = String(String.UnicodeScalarView(kept))
        return (4...12).contains(code.count) ? code : nil
    }

    /// `mahj://class/OKLETS`, or `mahj://class?code=OKLETS`.
    static func code(from url: URL) -> String? {
        guard url.scheme == "mahj", url.host == "class" else { return nil }
        if let path = url.pathComponents.dropFirst().first, let code = normalized(path) {
            return code
        }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "code" }?.value
        return query.flatMap(normalized)
    }
}

/// The class code a player joined, kept on the device and refreshed from the
/// server so a new weekly focus shows up without a release.
///
/// Anonymous by construction, like the challenge standings: the request is
/// the app, the code and a random per-install token, nothing else. The code
/// also rides to RevenueCat and PostHog as `class_code`, which is how trials
/// and members are counted per teacher.
@MainActor
final class ClassCodeService: ObservableObject {
    static let shared = ClassCodeService()

    enum JoinOutcome: Equatable, Sendable {
        case joined
        /// The server answered, and no open class has that code.
        case notFound
        /// Could not reach the server.
        case offline
    }

    @Published private(set) var current: TeacherClass?

    private static let currentKey = "classCode.current"
    private static let tokenKey = "classCode.player"
    private static let refreshInterval: TimeInterval = 15 * 60
    nonisolated private static let url = URL(string: "https://ucoveqbyfuxqvpysmixu.supabase.co/rest/v1/rpc/class_fetch")!
    /// `FeedbackService.appID`, which is main-actor bound.
    nonisolated private static let appID = "mahj"

    private let defaults: UserDefaults
    private let fetcher: @Sendable (String, UUID) async -> FetchResult
    private var lastRefresh: Date?

    enum FetchResult: Equatable, Sendable {
        case found(name: String, focusRoomID: String)
        case notFound
        case offline
    }

    init(defaults: UserDefaults = .standard, fetcher: (@Sendable (String, UUID) async -> FetchResult)? = nil) {
        self.defaults = defaults
        self.fetcher = fetcher ?? Self.fetchFromServer
        current = defaults.data(forKey: Self.currentKey).flatMap { try? JSONDecoder().decode(TeacherClass.self, from: $0) }
        #if DEBUG
        if let pinned = Self.debugPinnedClass() { current = pinned }
        #endif
    }

    func join(_ raw: String) async -> JoinOutcome {
        guard let code = ClassCode.normalized(raw) else { return .notFound }
        switch await fetcher(code, playerToken) {
        case let .found(name, focus):
            let joined = TeacherClass(code: code, name: name, focusRoomID: focus)
            let isNew = joined.code != current?.code
            store(joined)
            lastRefresh = Date()
            if isNew { Analytics.capture("class_joined", ["class_code": code]) }
            return .joined
        case .notFound:
            return .notFound
        case .offline:
            return .offline
        }
    }

    func leave() {
        guard let code = current?.code else { return }
        Analytics.capture("class_left", ["class_code": code])
        store(nil)
    }

    /// On launch and each return to the app, at most every 15 minutes. A class
    /// the server no longer has (Jack switched it off) is dropped; an
    /// unreachable server keeps what the player already sees.
    func refresh(force: Bool = false) async {
        guard let code = current?.code else { return }
        if !force, let lastRefresh, Date().timeIntervalSince(lastRefresh) < Self.refreshInterval { return }
        #if DEBUG
        if Self.debugPinnedClass() != nil { return }
        #endif
        switch await fetcher(code, playerToken) {
        case let .found(name, focus):
            lastRefresh = Date()
            let fresh = TeacherClass(code: code, name: name, focusRoomID: focus)
            if fresh != current { store(fresh) }
        case .notFound:
            // A join or leave while this request was out wins.
            guard current?.code == code else { return }
            lastRefresh = Date()
            store(nil)
        case .offline:
            break
        }
    }

    /// Mirrors the class onto RevenueCat and PostHog. Called on every change
    /// and once RevenueCat is configured, since a join can come first.
    func syncAttribution(to subscriptions: SubscriptionService = .shared) {
        subscriptions.syncClassAttribute(current?.code)
    }

    private func store(_ teacherClass: TeacherClass?) {
        current = teacherClass
        if let teacherClass, let data = try? JSONEncoder().encode(teacherClass) {
            defaults.set(data, forKey: Self.currentKey)
        } else {
            defaults.removeObject(forKey: Self.currentKey)
        }
        syncAttribution()
    }

    private var playerToken: UUID {
        if let kept = defaults.string(forKey: Self.tokenKey).flatMap(UUID.init(uuidString:)) { return kept }
        let token = UUID()
        defaults.set(token.uuidString, forKey: Self.tokenKey)
        return token
    }

    private struct Reply: Decodable {
        let name: String
        let focusRoom: String

        enum CodingKeys: String, CodingKey {
            case name
            case focusRoom = "focus_room"
        }
    }

    nonisolated private static let fetchFromServer: @Sendable (String, UUID) async -> FetchResult = { code, token in
        // Simulator and test runs all count as one member, so they never
        // inflate a class's numbers.
        #if targetEnvironment(simulator)
        let player = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        #else
        let player = token
        #endif
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(FeedbackEndpoint.production.apiKey, forHTTPHeaderField: "apikey")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "p_app": appID,
            "p_code": code,
            "p_player": player.uuidString.lowercased(),
        ])
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return .offline }
        if let reply = try? JSONDecoder().decode(Reply.self, from: data) {
            return .found(name: reply.name, focusRoomID: reply.focusRoom)
        }
        // Only an explicit null means "no such class"; anything else garbled
        // must not drop the class a player already joined.
        let body = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return body == "null" ? .notFound : .offline
    }

    #if DEBUG
    /// Captures only: `-mahj.class OK_Let's_Mahjong,charleston-room` shows a
    /// class without the network (underscores read as spaces).
    private static func debugPinnedClass() -> TeacherClass? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-mahj.class"), index + 1 < arguments.count else { return nil }
        let value = arguments[index + 1]
        guard let comma = value.lastIndex(of: ",") else { return nil }
        let name = value[..<comma].replacingOccurrences(of: "_", with: " ")
        return TeacherClass(code: "PREVIEW", name: name, focusRoomID: String(value[value.index(after: comma)...]))
    }
    #endif
}
