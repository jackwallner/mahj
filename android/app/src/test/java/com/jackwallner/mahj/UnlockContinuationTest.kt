package com.jackwallner.mahj

import com.jackwallner.mahj.data.UnlockContinuation
import com.jackwallner.mahj.ui.nav.PracticeMode
import com.jackwallner.mahj.ui.nav.Route
import org.junit.Assert.*
import org.junit.Test

class UnlockContinuationTest {
    @Test
    fun successfulUnlockOpensTheChosenDestinationOnlyOnce() {
        listOf(Route.EndlessPicker, Route.GameNightPrep, Route.Practice(PracticeMode.Timed),
            Route.HandPlay, Route.Drill("tile-room", "plus-tile-quiz")).forEach { destination ->
            val request = UnlockContinuation(destination)
            assertEquals(destination, request.finish(true))
            assertNull(request.finish(true))
        }
    }

    @Test
    fun cancellationDiscardsTheRequestBeforeALaterPurchase() {
        val request = UnlockContinuation<Route>(Route.Practice(PracticeMode.Timed))
        assertNull(request.finish(false))
        assertNull(request.finish(true))
    }
}
