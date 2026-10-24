import Foundation

/// A purchase sheet owns one request until it closes, including cancellation.
struct UnlockContinuation<Destination> {
    var destination: Destination?

    mutating func finish(isMember: Bool) -> Destination? {
        defer { destination = nil }
        return isMember ? destination : nil
    }
}
