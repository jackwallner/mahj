import Combine
import Foundation

final class OfflineProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)) }
    override func stopLoading() {}
}

@main struct FeedbackProbe {
    @MainActor static func main() async {
        let name = "mahj.audit1012.feedback"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [OfflineProtocol.self]
        let service = FeedbackService(endpoint: FeedbackEndpoint(url: URL(string: "https://audit.invalid")!, apiKey: "audit"), defaults: defaults, session: URLSession(configuration: config))
        for index in 1...3 { print("submit", index, await service.submit(kind: .question, message: "offline report \(index)", isMember: false)) }
        print("before retry", service.pendingCount)
        await service.flushPending()
        print("after offline retry", service.pendingCount)
        let data = defaults.data(forKey: "feedback.pending")!
        print(String(data: data, encoding: .utf8)!)
        precondition(service.pendingCount == 1, "Expected bug reproduction")
        defaults.removePersistentDomain(forName: name)
    }
}
