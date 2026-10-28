package com.jackwallner.mahj

import android.content.Intent
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertContentDescriptionEquals
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.assertTextContains
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.swipeRight
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Device coverage of the iOS interactions and their persisted outcomes. */
@RunWith(AndroidJUnit4::class)
class ParityFlowTest {
    @get:Rule
    val compose = createEmptyComposeRule()
    private var scenario: ActivityScenario<MainActivity>? = null

    private fun launch(member: Boolean = false, returning: Boolean = false, onboarded: Boolean = true) {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        scenario = ActivityScenario.launch(
            Intent(context, MainActivity::class.java)
                .putExtra("resetAll", true)
                .putExtra("uiTest", true)
                .putExtra("onboarded", onboarded)
                .putExtra("returningSubscriber", returning)
                .putExtra("skillLevel", if (onboarded) "" else "some")
                .putExtra("forcePro", member)
                .putExtra("appearance", "light"),
        )
        waitFor(if (onboarded) "Your seat at the table." else "onboarding-primary")
    }

    @After
    fun close() { scenario?.close() }

    private fun waitFor(value: String) {
        compose.waitUntil(20_000) {
            compose.onAllNodes(hasText(value, substring = true) or hasContentDescription(value) or hasTestTag(value))
                .fetchSemanticsNodes().isNotEmpty()
        }
    }

    private fun tag(value: String) {
        compose.waitUntil(20_000) { compose.onAllNodes(hasTestTag(value)).fetchSemanticsNodes().size == 1 }
        val node = compose.onNodeWithTag(value)
        if (listOf("room-", "drill-", "tile-", "plan-").any(value::startsWith)) node.performScrollTo()
        node.performClick()
        compose.waitForIdle()
    }

    @Test
    fun deckRequiresFlipThenSupportsSwipeAndUndo() {
        launch()
        tag("room-tile-room")
        tag("drill-meet-tiles")
        waitFor("Craks")
        compose.onNodeWithTag("deck-card").performTouchInput { swipeRight() }
        waitFor("0 of 12 down")
        tag("deck-card")
        compose.onNodeWithTag("deck-card").performTouchInput { swipeRight() }
        waitFor("1 of 12 down")
        compose.onNodeWithContentDescription("Undo last answer").performClick()
        waitFor("0 of 12 down")
        waitFor("Craks")
        tag("deck-card")
        compose.onNodeWithTag("deck-card").performTouchInput { swipeLeft() }
        waitFor("0 of 12 down")
        waitFor("Bams")
    }

    @Test
    fun selfTestGradeCannotBeOverriddenBySwipe() {
        launch()
        tag("room-table-room")
        tag("drill-judgment-cards")
        tag("card-choice-0")
        waitFor("card-verdict")
        compose.onNodeWithTag("deck-card").performTouchInput { swipeRight() }
        waitFor("card-verdict")
        compose.onNodeWithText("0 of 14 down").assertTextContains("0 of 14", substring = true)
        tag("card-next")
        waitFor("0 of 14 down")
    }

    @Test
    fun charlestonRequiresThreeTilesAndShowsCoach() {
        launch()
        tag("room-charleston-room")
        tag("drill-charleston-pass")
        compose.onNodeWithTag("pass").assertIsNotEnabled()
        listOf(6, 9, 10).forEach { tag("rack-tile-$it") }
        compose.onNodeWithTag("pass").assertIsEnabled()
        tag("pass")
        waitFor("coach-headline")
        tag("next")
        compose.onNodeWithTag("pass").assertIsNotEnabled()
    }

    @Test
    fun handMatchingGradesAndFinishesTheFreeSet() {
        launch()
        tag("room-card-room")
        tag("drill-hand-match")
        repeat(9) {
            tag("choice-0")
            waitFor("explanation")
            tag("next")
        }
        waitFor("drill-score")
    }

    @Test
    fun glossarySearchAcceptsTileNicknames() {
        launch()
        compose.onNodeWithContentDescription("Reference and glossary").performClick()
        waitFor("reference-search")
        compose.onNodeWithTag("reference-search").performTextInput("soap")
        waitFor("White Dragon")
    }

    @Test
    fun freePlayerCannotOpenExtraPracticeSet() {
        launch()
        tag("room-tile-room")
        tag("drill-plus-tile-extras")
        waitFor("Get Mahj+")
        waitFor("Restore")
        waitFor("Auto-renews")
    }

    @Test
    fun memberCanOpenExtraPracticeSet() {
        launch(member = true)
        tag("room-tile-room")
        tag("drill-plus-tile-extras")
        tag("choice-0")
        waitFor("explanation")
    }

    @Test
    fun openDrillSurvivesActivityRecreation() {
        launch()
        tag("room-card-room")
        tag("drill-hand-match")
        tag("choice-0")
        waitFor("explanation")
        scenario!!.recreate()
        waitFor("explanation")
        tag("next")
        waitFor("choice-0")
    }

    @Test
    fun handResumesAfterBackNavigation() {
        launch()
        tag("tile-hand-play")
        tag("target-evens2468")
        tag("play-it-out")
        tag("rack-tile-0")
        waitFor("grade-note")
        UiDevice.getInstance(InstrumentationRegistry.getInstrumentation()).pressBack()
        waitFor("Your seat at the table.")
        tag("tile-hand-play")
        waitFor("grade-note")
        tag("next-turn")
        waitFor("2 of 12")
    }

    @Test
    fun invalidReviewerCodeKeepsMembershipLocked() {
        launch()
        compose.onNodeWithContentDescription("Settings").performClick()
        compose.onNodeWithText("Version").performScrollTo().performTouchInput { longClick() }
        waitFor("review-access-code")
        compose.onNodeWithTag("review-access-code").performTextInput("invalid-code")
        compose.onNodeWithText("Unlock", useUnmergedTree = true).performClick()
        waitFor("Code not recognized.")
    }

    @Test
    fun allGeneratedSkillsGradeAndDealTheNextQuestion() {
        launch(member = true)
        val device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
        listOf("rackReading", "tileCounting", "charlestonPass", "defense").forEach { skill ->
            tag("tile-endless")
            tag("skill-$skill")
            tag("choice-0")
            waitFor("explanation")
            tag("next")
            compose.onNodeWithTag("choice-0").assertIsEnabled()
            device.pressBack()
            device.pressBack()
            waitFor("Your seat at the table.")
        }
    }

    @Test
    fun generatedQuestionAndGradeSurviveRecreationAndQueueRefill() {
        launch(member = true)
        tag("tile-endless")
        tag("skill-rackReading")
        repeat(10) {
            tag("choice-0")
            waitFor("explanation")
            val explanation = compose.onNodeWithTag("explanation").fetchSemanticsNode()
                .config[SemanticsProperties.Text].joinToString("") { it.text }
            if (it == 0 || it == 6) {
                scenario!!.recreate()
                waitFor("explanation")
                compose.onNodeWithTag("explanation").assertTextEquals(explanation)
            }
            tag("next")
        }
    }

    @Test
    fun membershipWithoutAnActiveSubscriptionKeepsRestoreAndHidesManagement() {
        launch(member = true)
        compose.onNodeWithContentDescription("Settings").performClick()
        compose.onNodeWithText("Mahj+ unlocked").assertExists()
        compose.onNodeWithText("Restore Purchases").assertExists()
        assertTrue(compose.onAllNodes(hasText("Manage Subscription")).fetchSemanticsNodes().isEmpty())
    }

    @Test
    fun returningSubscribersSeeRegularBillingInThePaywall() {
        launch(returning = true)
        tag("tile-endless")
        waitFor("paywall-cta")
        compose.onNodeWithTag("paywall-cta").assertContentDescriptionEquals("Subscribe")
        compose.onNodeWithText("Billed yearly. Auto-renews.").assertExists()
        compose.onNodeWithText("Billed monthly. Auto-renews.").assertExists()
        assertTrue(compose.onAllNodes(hasText("7 days free", substring = true)).fetchSemanticsNodes().isEmpty())
        tag("plan-monthly")
        scenario!!.recreate()
        waitFor("paywall-cta")
        compose.onNodeWithTag("paywall-cta").assertContentDescriptionEquals("Subscribe")
    }

    @Test
    fun returningSubscriberOnboardingDoesNotPromiseAnotherTrial() {
        launch(returning = true, onboarded = false)
        repeat(4) { tag("onboarding-primary") }
        waitFor("Get Mahj+")
        compose.onNodeWithTag("onboarding-primary").assertContentDescriptionEquals("Subscribe")
        assertTrue(compose.onAllNodes(hasText("7 days free", substring = true)).fetchSemanticsNodes().isEmpty())
    }

    @Test
    fun selectedPurchasePlanSurvivesRecreation() {
        launch()
        tag("tile-endless")
        tag("plan-monthly")
        scenario!!.recreate()
        waitFor("plan-monthly")
        compose.onNodeWithTag("plan-monthly").assertIsSelected()
        compose.onNodeWithTag("paywall-cta").assertContentDescriptionEquals("Start 7-Day Free Trial")
    }

    @Test
    fun feedbackDraftSurvivesRecreation() {
        launch()
        compose.onNodeWithContentDescription("Settings").performClick()
        compose.onNodeWithText("Send Feedback").performScrollTo().performClick()
        waitFor("feedback-text")
        compose.onNodeWithTag("feedback-text").performTextInput("Keep this draft")
        scenario!!.recreate()
        waitFor("feedback-text")
        compose.onNodeWithTag("feedback-text").assertTextEquals("Keep this draft")
    }

    @Test
    fun dailyMinuteCompletesAndRecreationDoesNotRecordItTwice() {
        launch(member = true)
        tag("tile-minute")
        tag("start-minute")
        repeat(5) { tag("choice-0"); tag("next") }
        waitFor("minute-score")
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val graph = (context.applicationContext as MahjApplication).graph
        val sessions = graph.progress.totalSessions
        scenario!!.recreate()
        waitFor("minute-score")
        assertEquals(sessions, graph.progress.totalSessions)
    }

    @Test
    fun gameNightPrepCompletesItsTenQuestionSession() {
        launch(member = true)
        tag("tile-game-night")
        compose.onNodeWithTag("start-prep").performScrollTo().performClick()
        repeat(10) { tag("choice-0"); tag("next") }
        waitFor("drill-score")
    }

    @Test
    fun timedChallengeKeepsItsClockAndAnswerAcrossRecreation() {
        launch(member = true)
        tag("tile-timed")
        tag("start-clock")
        tag("choice-0")
        waitFor("explanation")
        fun seconds() = compose.onNodeWithTag("seconds-left").fetchSemanticsNode()
            .config[SemanticsProperties.Text].joinToString("") { it.text }.trim().removeSuffix("s").toInt()
        compose.waitUntil(10_000) { seconds() <= 88 }
        val before = seconds()
        scenario!!.recreate()
        waitFor("explanation")
        val after = seconds()
        assertTrue("Recreation must not reset the challenge to 90 seconds", after <= before)
        assertTrue(after > 0)
        compose.waitUntil(120_000) {
            compose.onAllNodes(hasTestTag("drill-score")).fetchSemanticsNodes().isNotEmpty()
        }
    }
}
