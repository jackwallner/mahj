import Foundation

/// The part of a RevenueCat customer record that matters for noticing someone
/// leaving: are they entitled, is it a trial, and will it renew.
struct MembershipSnapshot: Codable, Equatable, Sendable {
    var isActive: Bool
    var isTrial: Bool
    var willRenew: Bool

    static let none = MembershipSnapshot(isActive: false, isTrial: false, willRenew: false)
}

/// The moment a membership turned toward the exit. Each one is worth exactly
/// one question, asked once, on the next launch where it is noticed.
enum ChurnMoment: String, Codable, Sendable {
    /// Still inside the free week, auto-renew switched off.
    case trialRenewalOff
    /// Paying, auto-renew switched off.
    case paidRenewalOff
    /// The free week ran out without converting.
    case trialLapsed
    /// A paid membership expired.
    case paidLapsed

    var isTrial: Bool {
        self == .trialRenewalOff || self == .trialLapsed
    }
}

/// Pure comparison of two snapshots. Lives apart from RevenueCat so it can be
/// tested without a customer record.
enum MembershipTransitions {
    /// The churn moment between two observations, if any. The first
    /// observation ever (`previous == nil`) yields nothing: a lapse we did not
    /// watch happen is not a moment, it is history.
    static func churnMoment(from previous: MembershipSnapshot?, to current: MembershipSnapshot) -> ChurnMoment? {
        guard let previous, previous.isActive else { return nil }
        if !current.isActive {
            return previous.isTrial ? .trialLapsed : .paidLapsed
        }
        if previous.willRenew && !current.willRenew {
            return current.isTrial ? .trialRenewalOff : .paidRenewalOff
        }
        return nil
    }

    /// A member who comes back (renewal on again, or a fresh purchase) earns
    /// a fresh ask the next time they leave.
    static func resetsAsk(from previous: MembershipSnapshot?, to current: MembershipSnapshot) -> Bool {
        guard let previous else { return false }
        return current.isActive && current.willRenew && !(previous.isActive && previous.willRenew)
    }
}

extension ChurnMoment: Identifiable {
    var id: String { rawValue }
}
