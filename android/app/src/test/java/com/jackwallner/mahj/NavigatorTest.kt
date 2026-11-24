package com.jackwallner.mahj

import com.jackwallner.mahj.ui.nav.Navigator
import com.jackwallner.mahj.ui.nav.PracticeMode
import com.jackwallner.mahj.ui.nav.Route
import com.jackwallner.mahj.ui.nav.SessionPurpose
import org.junit.Assert.assertEquals
import org.junit.Test

/** A reminder tap opens its screen over the one in use, never in place of it. */
class NavigatorTest {
    private val prep = Route.Session(emptyList(), SessionPurpose.GameNightPrep)
    private fun isPrep(route: Route) = route is Route.Session && route.purpose == SessionPurpose.GameNightPrep

    @Test
    fun aRoutedScreenGoesOverTheOpenRun() {
        val navigator = Navigator()
        navigator.push(Route.Practice(PracticeMode.Timed))
        navigator.pushRouted(prep, ::isPrep)
        assertEquals(3, navigator.depth)
        navigator.pop()
        assertEquals("Back returns to the run in progress", Route.Practice(PracticeMode.Timed), navigator.top)
    }

    @Test
    fun routingToTheScreenOnTopChangesNothing() {
        val navigator = Navigator()
        navigator.pushRouted(prep, ::isPrep)
        navigator.pushRouted(prep, ::isPrep)
        assertEquals(2, navigator.depth)
    }
}
