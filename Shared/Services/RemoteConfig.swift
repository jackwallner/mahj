import Foundation

import RevenueCat

/// Everything RevenueCat can change without a release, read from the current
/// offering's metadata (a running Experiment's variant included), the
/// Vitals pattern. Every variant ships in the binary; a missing or unknown
/// value is the control, which is what 1.3.2 shipped. Keys that a switch
/// reads must be set the same on every offering, or an Experiment arm would
/// flip them as a side effect.
///
/// DEBUG builds can pin any key for captures: `-mahj.rc.<key> <value>`.

/// The trial button's wording. Onboarding uses sentence case, the paywall
/// title case, as in 1.3.2.
enum TrialCTA: String, CaseIterable, Sendable {
    static let metadataKey = "trial_cta"

    /// Control: "Start 7-day free trial", as shipped since 1.0.
    case sevenDay = "seven_day"
    case my
    case your

    enum Surface {
        case onboarding, paywall
    }

    static func from(metadata: [String: Any]?) -> TrialCTA {
        RemoteConfig.value(metadataKey, in: metadata, default: .sevenDay)
    }

    func title(_ surface: Surface) -> String {
        switch (self, surface) {
        case (.sevenDay, .onboarding): return "Start 7-day free trial"
        case (.sevenDay, .paywall): return "Start 7-Day Free Trial"
        case (.my, .onboarding): return "Start my free trial"
        case (.my, .paywall): return "Start My Free Trial"
        case (.your, .onboarding): return "Start your free trial"
        case (.your, .paywall): return "Start Your Free Trial"
        }
    }
}

/// The onboarding trial page's headline.
enum TrialTitle: String, CaseIterable, Sendable {
    static let metadataKey = "trial_title"

    /// Control: "Try Mahj+ free".
    case tryFree = "try_free"
    /// Leads with why people learn: their next game.
    case gameNight = "game_night"

    var text: String {
        switch self {
        case .tryFree: return "Try \(Membership.name) free"
        case .gameNight: return "Get ready for game night"
        }
    }
}

/// The onboarding trial page's benefit list.
enum TrialBenefits: String, CaseIterable, Sendable {
    static let metadataKey = "trial_benefits"

    /// Control: opens with the free rooms as reassurance.
    case reassureFirst = "reassure_first"
    /// Opens with what the membership adds, and leaves the free rooms out.
    case paidFirst = "paid_first"

    var lines: [String] {
        switch self {
        case .reassureFirst:
            return [
                "Every beginner room is free, forever",
                "Play coached practice hands, as many as you want",
                "Endless Practice deals a fresh rack every time",
                "Fix My Mistakes and Game Night Prep, from your misses",
                "Extra sets in all four rooms, plus the Master Tables",
            ]
        case .paidFirst:
            return [
                "Play coached practice hands, as many as you want",
                "Endless Practice deals a fresh rack every time",
                "Fix My Mistakes brings back what you miss",
                "Game Night Prep, five minutes built from your misses",
                "Extra sets in all four rooms, plus the Master Tables",
            ]
        }
    }
}

/// Which plan the onboarding trial button buys. The price line and the
/// disclosure always follow it (3.1.2).
enum OnboardingPlan: String, CaseIterable, Sendable {
    static let metadataKey = "onboarding_plan"

    /// Control: monthly, the smaller recurring figure on Apple's sheet.
    case monthly
    /// Yearly, for more value per trial.
    case yearly

    var plan: PaywallPlan {
        switch self {
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }
}

/// What the one-tap trial sheet says under its headline. Tested in the app
/// rather than as a RevenueCat Experiment: Experiments enrol only new
/// customers, one experiment each, so it would split the trial button test's
/// traffic and miss the existing free players who make up most of the sheet's
/// audience. `split` deals each player one arm for good (control or
/// timeline), the arm rides to RevenueCat as the `offer_pitch` attribute,
/// and `scripts/offer-pitch-readout.py` reads trials per sheet viewer by
/// arm. Deploy the winner by setting the key to it on every offering.
enum OfferPitch: String, CaseIterable, Sendable {
    static let metadataKey = "offer_pitch"
    static let armKey = "trialOffer.pitchArm"

    /// Control: three benefit lines.
    case benefits
    /// How the free week runs, with real dates (the Blinkist trial timeline).
    case timeline
    /// Half the players get each arm, kept per install.
    case split

    /// The arm this player sees. `split` deals one on first use and keeps it.
    func arm(defaults: UserDefaults = .standard, coin: () -> Bool = { Bool.random() }) -> OfferPitch {
        guard self == .split else { return self }
        if let kept = defaults.string(forKey: Self.armKey).flatMap(OfferPitch.init(rawValue:)), kept != .split {
            return kept
        }
        let dealt: OfferPitch = coin() ? .timeline : .benefits
        defaults.set(dealt.rawValue, forKey: Self.armKey)
        return dealt
    }
}

/// Remote off switches, for what is worth pausing without a release. On
/// unless the metadata says "off".
enum RemoteSwitch: String, CaseIterable, Sendable {
    /// Apple's tracking prompt for Meta ads.
    case attPrompt = "att_prompt"
    /// Apple's rating prompt after a good drill.
    case ratingPrompt = "rating_prompt"
    /// The monthly challenge: its Home card and the `mahj://challenge` link.
    /// Saved runs are kept, so switching it back on loses nothing.
    case monthlyChallenge = "monthly_challenge"
    /// The one-tap trial sheet rising on its own after a good result.
    /// Tapped Mahj+ cards still open it when this is off.
    case trialOffer = "trial_offer"
}

enum RemoteConfig {
    /// The value for `key`, or `fallback` when it is missing, not a string,
    /// or not one of the shipped variants.
    static func value<T: RawRepresentable>(_ key: String, in metadata: [String: Any]?, default fallback: T) -> T
    where T.RawValue == String {
        #if DEBUG
        if let pinned = launchOverride(key).flatMap(T.init(rawValue:)) { return pinned }
        #endif
        guard let raw = metadata?[key] as? String else { return fallback }
        return T(rawValue: raw) ?? fallback
    }

    static func isOn(_ remoteSwitch: RemoteSwitch, in metadata: [String: Any]?) -> Bool {
        #if DEBUG
        if let pinned = launchOverride(remoteSwitch.rawValue) { return pinned != "off" }
        #endif
        return (metadata?[remoteSwitch.rawValue] as? String) != "off"
    }

    #if DEBUG
    private static func launchOverride(_ key: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-mahj.rc.\(key)"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
    #endif
}

extension SubscriptionService {
    private var remoteMetadata: [String: Any]? { offerings?.current?.metadata }

    var trialCTAArm: TrialCTA { TrialCTA.from(metadata: remoteMetadata) }
    var trialTitle: TrialTitle { RemoteConfig.value(TrialTitle.metadataKey, in: remoteMetadata, default: .tryFree) }
    var trialBenefits: TrialBenefits {
        RemoteConfig.value(TrialBenefits.metadataKey, in: remoteMetadata, default: .reassureFirst)
    }
    var onboardingPlan: OnboardingPlan {
        RemoteConfig.value(OnboardingPlan.metadataKey, in: remoteMetadata, default: .monthly)
    }

    /// The trial sheet's body for this player (an arm, never `split`).
    var offerPitch: OfferPitch {
        RemoteConfig.value(OfferPitch.metadataKey, in: remoteMetadata, default: OfferPitch.benefits).arm()
    }

    func trialCTA(_ surface: TrialCTA.Surface) -> String { trialCTAArm.title(surface) }

    func isOn(_ remoteSwitch: RemoteSwitch) -> Bool { RemoteConfig.isOn(remoteSwitch, in: remoteMetadata) }

    /// Every variant this customer saw, for reading tests by attribute too.
    var remoteVariantAttributes: [String: String] {
        var attributes = [
            TrialCTA.metadataKey: trialCTAArm.rawValue,
            TrialTitle.metadataKey: trialTitle.rawValue,
            TrialBenefits.metadataKey: trialBenefits.rawValue,
            OnboardingPlan.metadataKey: onboardingPlan.rawValue,
        ]
        // Only once the sheet has dealt an arm: a player who never saw it is
        // not in the pitch test.
        if let arm = UserDefaults.standard.string(forKey: OfferPitch.armKey) {
            attributes[OfferPitch.metadataKey] = arm
        }
        return attributes
    }
}
