package com.jackwallner.mahj

import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.content.MahjMinuteContent
import com.jackwallner.mahj.content.PracticeSkill
import com.jackwallner.mahj.data.AppClock
import com.jackwallner.mahj.data.ConversionDiagnostics
import com.jackwallner.mahj.data.HandPlayStore
import com.jackwallner.mahj.data.InMemoryStore
import com.jackwallner.mahj.data.MahjMinuteStore
import com.jackwallner.mahj.data.MasteryLevel
import com.jackwallner.mahj.data.PracticeRecordStore
import com.jackwallner.mahj.data.ProgressStore
import com.jackwallner.mahj.data.ReviewPromptTracker
import com.jackwallner.mahj.data.WhatsNewTracker
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.Tile
import java.time.Clock
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Ports of the iOS store tests: the logic that was hand-translated rather than exported. */
class StoreTest {
    private val defaults = InMemoryStore()
    private val clock = AppClock(Clock.fixed(Instant.parse("2026-09-30T12:00:00Z"), ZoneOffset.UTC))
    private val room = "tile-room"

    private fun advanceDays(days: Long) {
        clock.clock = Clock.offset(clock.clock, java.time.Duration.ofDays(days))
    }

    @Test
    fun streakCountsConsecutiveDaysAndResetsOnAGap() {
        val store = ProgressStore(defaults, clock)
        store.recordSession("meet-tiles")
        store.recordSession("meet-tiles")
        assertEquals(1, store.streakCount)
        assertEquals(2, store.completions("meet-tiles"))
        advanceDays(1)
        store.recordSession("tile-quiz")
        assertEquals(2, store.streakCount)
        advanceDays(3)
        store.recordSession("tile-quiz")
        assertEquals(1, store.streakCount)
    }

    @Test
    fun seenAndMissedPersistAndUndoRestoresThem() {
        val store = ProgressStore(defaults, clock)
        store.recordItem("q1", correct = false)
        store.recordItem("other", correct = true)
        val snapshot = store.snapshotItem("missed")
        store.recordItem("missed", correct = false)
        store.recordItem("q1", correct = true)
        val reloaded = ProgressStore(defaults, clock)
        assertTrue("q1" in reloaded.seenItems)
        assertFalse("A correct answer clears the miss", "q1" in reloaded.missedItems)
        reloaded.restoreItem(snapshot)
        val again = ProgressStore(defaults, clock)
        assertFalse("missed" in again.seenItems)
    }

    @Test
    fun resetKeepsOnboardingAndTheQuickSessionRestsForTheDay() {
        val store = ProgressStore(defaults, clock)
        store.setOnboarded(true)
        store.recordSession("a")
        store.markQuickSessionCompleted()
        assertTrue(store.quickSessionCompletedToday())
        advanceDays(1)
        assertFalse(store.quickSessionCompletedToday())
        store.resetAll()
        assertEquals(0, store.streakCount)
        assertTrue("Reset must not re-trigger onboarding", ProgressStore(defaults, clock).hasOnboarded)
    }

    @Test
    fun undoThenReanswerDoesNotCreateMastery() {
        val store = PracticeRecordStore(defaults, clock)
        val snapshot = store.snapshotAnswer("q1")
        store.record("q1", room, correct = true)
        store.restoreAnswer(snapshot)
        assertNull(PracticeRecordStore(defaults, clock).records["q1"])
        store.record("q1", room, correct = true)
        assertEquals(1, store.records["q1"]!!.streak)
        assertFalse(store.records["q1"]!!.isKnown(clock.millis()))
    }

    @Test
    fun missedItemEntersAndLeavesTheQueueWorstFirst() {
        val store = PracticeRecordStore(defaults, clock)
        store.record("q1", room, correct = false)
        assertEquals(listOf("q1"), store.reviewQueue())
        store.record("q1", room, correct = true)
        assertEquals("One correct answer schedules it a day out", emptyList<String>(), store.reviewQueue())
        store.record("q1", room, correct = true)
        assertFalse("Two in a row retires it", store.records["q1"]!!.needsReview)

        repeat(3) { store.record("q2", room, correct = false) }
        store.record("q3", room, correct = true)
        store.record("q3", room, correct = false)
        assertEquals("q2", store.reviewQueue().first())
    }

    @Test
    fun generatedItemsCollapseAndOneOffsStayOutOfReview() {
        val store = PracticeRecordStore(defaults, clock)
        val prefix = PracticeSkill.RACK_READING.itemPrefix
        store.record(prefix + "a", room, correct = false)
        store.record(prefix + "b", room, correct = true)
        store.record("mahj-minute-charleston", "charleston-room", correct = false, isReviewable = false)
        assertEquals(2, store.records[PracticeSkill.RACK_READING.raw]!!.attempts)
        assertEquals(0, store.dueCount())
        store.record("q1", room, correct = false)
        store.record("charleston-scenario", "charleston-room", correct = false)
        assertEquals(2, store.dueCount())
        assertEquals(listOf("q1"), store.reviewQueue(presentable = setOf("q1")))
    }

    @Test
    fun masteryLevelsAndStaleness() {
        assertEquals(MasteryLevel.UNTOUCHED, MasteryLevel.level(0, 10))
        assertEquals(MasteryLevel.LEARNING, MasteryLevel.level(3, 10))
        assertEquals(MasteryLevel.SOLID, MasteryLevel.level(4, 10))
        assertEquals(MasteryLevel.SHARP, MasteryLevel.level(9, 10))

        val store = PracticeRecordStore(defaults, clock)
        val tileRoom = DrillLibrary.room(room)!!
        val id = PracticeRecordStore.trackableItemIDs(tileRoom, isMember = false).first()
        store.record(id, room, correct = true)
        store.record(id, room, correct = true)
        assertEquals(1, store.mastery(tileRoom, isMember = false).known)
        advanceDays(10)
        assertEquals("A full interval past due goes rusty", 0, store.mastery(tileRoom, isMember = false).known)
    }

    @Test
    fun legacyMigrationSeedsEngagementOnlyOnce() {
        val store = PracticeRecordStore(defaults, clock)
        val ids = PracticeRecordStore.trackableItemIDs(DrillLibrary.room(room)!!, true).take(2)
        store.migrateLegacyProgress(seen = ids.toSet() + "gone", missed = setOf(ids[0]))
        assertEquals(2, store.records.size)
        assertEquals(0, store.records[ids[0]]!!.streak)
        assertEquals(1, store.records[ids[1]]!!.streak)
        store.resetAll()
        store.migrateLegacyProgress(seen = ids.toSet(), missed = emptySet())
        assertTrue(store.records.isEmpty())
    }

    @Test
    fun handPlayGivesOneFreeHandADayAndResumesAStartedOne() {
        val store = HandPlayStore(defaults, clock)
        assertTrue(store.canPlay(isMember = false))
        store.recordStart(isMember = false)
        assertFalse(store.canPlay(isMember = false))
        assertTrue(store.canPlay(isMember = true))
        store.saveInProgress(
            HandPlayStore.InProgressHand(
                listOf(Tile.c(2)), listOf(Tile.Joker), 1, HandCategory.EVENS_2468, 3, 2, Tile.Joker,
                HandPlayStore.ThrowGrade(Tile.c(5), false, "note"),
            ),
        )
        val reloaded = HandPlayStore(defaults, clock)
        assertTrue("A started hand is always playable", reloaded.canPlay(isMember = false))
        assertEquals("note", reloaded.inProgress!!.grade!!.note)
        reloaded.clearInProgress()
        advanceDays(1)
        assertTrue(HandPlayStore(defaults, clock).canPlay(isMember = false))
    }

    @Test
    fun mahjMinuteKeepsOnlyTheFirstAttempt() {
        val store = MahjMinuteStore(defaults, clock)
        val challenge = MahjMinuteContent.challenge(LocalDate.of(2026, 9, 30))
        val first = store.record(challenge, listOf(true, true, false, false, true))
        store.record(challenge, List(5) { true })
        assertEquals(3, MahjMinuteStore(defaults, clock).result(LocalDate.of(2026, 9, 30))!!.score)
        assertEquals(first.shortDate, "09/30")
        assertTrue(first.shareText.startsWith("Mahj Minute 09/30: 3/5"))
        assertEquals(1, store.completedThisWeek())
    }

    @Test
    fun reviewCardWaitsForEnoughUseAndHonoursCooldowns() {
        val tracker = ReviewPromptTracker(defaults, clock)
        tracker.recordAppLaunch()
        tracker.recordAppLaunch()
        repeat(2) { tracker.recordPositiveMoment() }
        assertFalse(tracker.shouldShowAfterPositiveMoment())
        tracker.recordPositiveMoment()
        assertTrue(tracker.shouldShowAfterPositiveMoment())
        tracker.markStoreCardRequested()
        assertFalse(tracker.shouldShowAfterPositiveMoment())
        advanceDays(31)
        assertTrue(tracker.shouldShowAfterPositiveMoment())
        tracker.markOpenedWriteReview()
        advanceDays(400)
        assertFalse("A terminal outcome retires it", tracker.shouldShowAfterPositiveMoment())
    }

    @Test
    fun conversionAttributesStayEmptyUntilAPitchAndFreezeAtConversion() {
        val diagnostics = ConversionDiagnostics(defaults, clock)
        diagnostics.recordAppOpen()
        assertTrue(diagnostics.subscriberAttributes.isEmpty())
        diagnostics.recordPitchView("mahj_onboarding_trial")
        diagnostics.recordPitchView("mahj_home_sheet")
        diagnostics.recordConversion("monthly", startedTrial = true, offeringId = "default")
        diagnostics.recordConversion("yearly", startedTrial = false, offeringId = null)
        val attributes = diagnostics.subscriberAttributes
        assertEquals("2", attributes["pitch_views_total"])
        assertEquals("1", attributes["pitch_views_onboarding_trial"])
        assertEquals("home_sheet", attributes["converted_surface"])
        assertEquals("monthly", attributes["converted_plan"])
        assertEquals("true", attributes["converted_with_trial"])
        assertEquals("1", attributes["opens_before_first_pitch"])
    }

    @Test
    fun whatsNewNeverShowsOnAFreshInstall() {
        val tracker = WhatsNewTracker(defaults, "1.3.1")
        assertFalse(tracker.shouldPresent(hasOnboarded = false))
        assertTrue("An onboarded player without a marker updated from an old build", tracker.shouldPresent(hasOnboarded = true))
        tracker.markCurrentAsBaseline()
        assertFalse(tracker.shouldPresent(hasOnboarded = true))
        assertFalse(WhatsNewTracker(InMemoryStore(), "9.9").shouldPresent(hasOnboarded = true))
    }
}
