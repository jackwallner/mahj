import Foundation

import RevenueCat

/// The trial button's wording, picked by the current RevenueCat offering's
/// `trial_cta` metadata, the same pattern as Vitals' `PaywallUIVariant`.
/// Every wording ships in the binary; RevenueCat only chooses which one an
/// Experiment arm shows, and promotes the winner by making its offering the
/// default. Missing or unknown metadata is the control, the 1.3.2 wording.
/// Nothing else on the trial flow is remote: only the button text.
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
        guard let raw = metadata?[metadataKey] as? String else { return .sevenDay }
        return TrialCTA(rawValue: raw) ?? .sevenDay
    }

    /// Onboarding uses sentence case, the paywall title case, as in 1.3.2.
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

extension SubscriptionService {
    /// The arm the current offering asks for (a running Experiment's variant
    /// included). `-mahj.trialCTA <raw>` pins one in DEBUG for captures.
    var trialCTAArm: TrialCTA {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let index = args.firstIndex(of: "-mahj.trialCTA"), index + 1 < args.count,
           let pinned = TrialCTA(rawValue: args[index + 1]) {
            return pinned
        }
        #endif
        return TrialCTA.from(metadata: offerings?.current?.metadata)
    }

    func trialCTA(_ surface: TrialCTA.Surface) -> String {
        trialCTAArm.title(surface)
    }
}
