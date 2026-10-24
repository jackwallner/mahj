package com.jackwallner.mahj.data

/** One requested destination, consumed on success or discarded on cancellation. */
class UnlockContinuation<T>(var destination: T? = null) {
    fun finish(isMember: Boolean): T? {
        val requested = destination
        destination = null
        return if (isMember) requested else null
    }
}
