package com.jackwallner.mahj

import android.content.Intent
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.core.view.WindowCompat
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** The first-run path, the free drills, and the paid boundary, on a real device. */
@RunWith(AndroidJUnit4::class)
class AppFlowTest {
    @get:Rule
    val compose = createEmptyComposeRule()

    private var scenario: ActivityScenario<MainActivity>? = null

    private fun launch(onboarded: Boolean, forcePro: Boolean = false, skill: String? = null, appearance: String = "light") {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(context, MainActivity::class.java)
            .putExtra("resetAll", true)
            .putExtra("uiTest", true)
            .putExtra("onboarded", onboarded)
            .putExtra("forcePro", forcePro)
            .putExtra("appearance", appearance)
        skill?.let { intent.putExtra("skillLevel", it) }
        scenario = ActivityScenario.launch(intent)
    }

    @After
    fun tearDown() {
        scenario?.close()
    }

    private fun waitFor(text: String, timeout: Long = 15_000) {
        compose.waitUntil(timeout) {
            compose.onAllNodes(hasText(text, substring = true) or hasContentDescription(text) or hasTestTag(text))
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    /** Waits until exactly one node carries [tag] (transitions briefly show two), then taps it. */
    private fun tag(tag: String) {
        compose.waitUntil(15_000) { compose.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().size == 1 }
        compose.onNodeWithTag(tag).performClick()
        compose.waitForIdle()
    }

    @Test
    fun onboardingSoftExitLandsOnHomeThroughTheTour() {
        launch(onboarded = false)
        waitFor("Make it stick between games")
        repeat(3) { tag("onboarding-primary") }
        tag("skill-played")
        tag("onboarding-primary")
        waitFor("Try Mahj+ free")
        tag("soft-exit")
        waitFor("Four rooms, four skills")
        tag("tour-skip")
        waitFor("Your seat at the table.")
    }

    @Test
    fun darkOnboardingKeepsSystemBarsReadableFromFirstLaunch() {
        launch(onboarded = false, appearance = "dark")
        waitFor("Make it stick between games")
        scenario?.onActivity { activity ->
            val controller = WindowCompat.getInsetsController(activity.window, activity.window.decorView)
            assertFalse(controller.isAppearanceLightStatusBars)
            assertFalse(controller.isAppearanceLightNavigationBars)
        }
    }

    @Test
    fun freeQuizGradesAndFinishes() {
        launch(onboarded = true)
        tag("room-tile-room")
        tag("drill-tile-quiz")
        repeat(16) {
            tag("choice-0")
            waitFor("explanation")
            tag("next")
        }
        waitFor("drill-score")
        tag("drill-done")
        waitFor("The Tile Room")
    }

    @Test
    fun lockedModesOpenThePaywallForFreePlayers() {
        launch(onboarded = true)
        tag("tile-endless")
        waitFor("Get Mahj+")
        waitFor("Restore")
        waitFor("Terms of Use")
        waitFor("Privacy Policy")
    }

    @Test
    fun membersReachEndlessPractice() {
        launch(onboarded = true, forcePro = true)
        tag("tile-endless")
        tag("skill-rackReading")
        waitFor("Which section is this rack chasing?")
        tag("choice-0")
        waitFor("explanation")
    }

    @Test
    fun playAHandRunsTwelveTurnsToAVerdict() {
        launch(onboarded = true)
        tag("tile-hand-play")
        tag("target-evens2468")
        tag("play-it-out")
        repeat(12) {
            tag("rack-tile-0")
            tag("next-turn")
        }
        waitFor("YOUR FINAL RACK")
        waitFor("That was today's free hand")
    }
}
