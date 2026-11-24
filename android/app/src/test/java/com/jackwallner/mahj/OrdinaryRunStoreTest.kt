package com.jackwallner.mahj

import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.content.SessionBuilder
import com.jackwallner.mahj.data.InMemoryStore
import com.jackwallner.mahj.data.OrdinaryRun
import com.jackwallner.mahj.data.OrdinaryRunStore
import com.jackwallner.mahj.model.DrillKind
import org.junit.Assert.*
import org.junit.Test

class OrdinaryRunStoreTest {
    @Test
    fun quickRunSurvivesRelaunchWithExactOrderAndHeldAnswer() {
        val defaults = InMemoryStore()
        val store = OrdinaryRunStore(defaults)
        val items = SessionBuilder.quickSession(seen = emptySet(), missed = emptySet(), includePro = false)
        val run = OrdinaryRun(SessionBuilder.sessionDrill, items, index = 3, score = 2, selection = 1,
            answers = listOf(true, false, true, false))
        store.save(run)
        assertEquals(run, OrdinaryRunStore(defaults).inProgress)
        store.clear("other-drill")
        assertNotNull(store.inProgress)
        store.clear(run.id)
        assertNull(OrdinaryRunStore(defaults).inProgress)
        store.save(OrdinaryRun(SessionBuilder.sessionDrill))
        assertNull(store.inProgress)
    }

    @Test
    fun roomRunsPreserveAllContentAndCharlestonAndDeckState() {
        val defaults = InMemoryStore()
        val store = OrdinaryRunStore(defaults)
        DrillLibrary.rooms.flatMap { it.drills }.forEach { drill ->
            val queue = (drill.kind as? DrillKind.Flashcards)?.cards?.reversed()?.map { it.id }.orEmpty()
            val run = OrdinaryRun(drill, index = 1, score = 2, selection = 0, answers = listOf(false, true),
                selected = listOf(1, 4, 7), submitted = true, queue = queue, flipped = true)
            store.save(run)
            assertEquals(run, OrdinaryRunStore(defaults).run(drill.id))
        }
    }

    @Test
    fun charlestonOnlyMissesDoNotPromiseAnEmptyReview() {
        val store = com.jackwallner.mahj.data.PracticeRecordStore(InMemoryStore(), com.jackwallner.mahj.data.AppClock())
        val scenarios = DrillLibrary.rooms.flatMap { it.drills }.mapNotNull { it.kind as? DrillKind.Charleston }.flatMap { it.scenarios }
        assertTrue(scenarios.isNotEmpty())
        scenarios.forEach { store.record(it.id, "charleston-room", false) }
        val presentable = SessionBuilder.reviewableIDs(true)
        assertEquals(0, store.dueCount(presentable))
        assertTrue(store.reviewQueue(presentable = presentable).isEmpty())
    }
    @Test
    fun deckUndoKeepsTheScheduleBeforeTheHeldAnswer() {
        val defaults = InMemoryStore()
        val records = com.jackwallner.mahj.data.PracticeRecordStore(defaults, com.jackwallner.mahj.data.AppClock())
        val progress = com.jackwallner.mahj.data.ProgressStore(defaults, com.jackwallner.mahj.data.AppClock())
        val drill = DrillLibrary.rooms.flatMap { it.drills }.first { it.kind is DrillKind.Flashcards }
        val card = (drill.kind as DrillKind.Flashcards).cards.first()
        val before = OrdinaryRun.AnswerSnapshot(progress.snapshotItem(card.id), records.snapshotAnswer(card.id))
        records.record(card.id, "tile-room", false)
        val store = OrdinaryRunStore(defaults)
        store.save(OrdinaryRun(drill, answers = listOf(false), pendingAnswer = before, undoCardID = card.id, undoAnswer = before))
        val saved = OrdinaryRunStore(defaults).inProgress!!
        assertEquals(before, saved.pendingAnswer)
        assertEquals(card.id, saved.undoCardID)
        records.restoreAnswer(saved.undoAnswer!!.practice)
        assertNull(records.records[card.id])
    }

    private fun drill(id: String) = DrillLibrary.rooms.flatMap { it.drills }.first { it.id == id }

    /** Answering in another drill used to replace the one saved slot and lose a half-done Get Started. */
    @Test
    fun eachDrillKeepsItsOwnRun() {
        val defaults = InMemoryStore()
        val store = OrdinaryRunStore(defaults)
        val items = SessionBuilder.quickSession(seen = emptySet(), missed = emptySet(), includePro = false)
        val quick = OrdinaryRun(SessionBuilder.sessionDrill, items, index = 2, score = 1, answers = listOf(true, false))
        store.save(quick)
        val other = DrillLibrary.rooms.first().drills.first { it.kind is DrillKind.Quiz }
        val room = OrdinaryRun(other, index = 1, answers = listOf(true))
        store.save(room)
        val reloaded = OrdinaryRunStore(defaults)
        assertEquals(quick, reloaded.run(quick.id))
        assertEquals(room, reloaded.run(room.id))
        assertEquals("The latest answered run is last", room, reloaded.inProgress)
        assertEquals(room, reloaded.resumableRoomRun(isMember = false))
        assertTrue(reloaded.hasResumableQuickSession(isMember = false))

        store.save(quick.copy(index = 3, answers = listOf(true, false, true)))
        assertEquals(SessionBuilder.sessionDrill.id, OrdinaryRunStore(defaults).inProgress?.id)

        store.clearAll()
        assertTrue(OrdinaryRunStore(defaults).runs.isEmpty())
    }

    /** Opening a drill saves its empty run; that must never take or replace a slot. */
    @Test
    fun anUnansweredRunNeverReplacesASavedOne() {
        val defaults = InMemoryStore()
        val store = OrdinaryRunStore(defaults)
        val other = DrillLibrary.rooms.first().drills.first { it.kind is DrillKind.Quiz }
        val items = SessionBuilder.quickSession(seen = emptySet(), missed = emptySet(), includePro = false)
        val quick = OrdinaryRun(SessionBuilder.sessionDrill, items, index = 1, answers = listOf(true))
        store.save(quick)
        store.save(OrdinaryRun(other))
        assertEquals(listOf(quick), OrdinaryRunStore(defaults).runs)
        assertNull(store.resumableRoomRun(isMember = false))

        store.save(OrdinaryRun(SessionBuilder.sessionDrill, items))
        assertNull("Undone back to nothing, the run drops out", OrdinaryRunStore(defaults).run(quick.id))
    }

    @Test
    fun aRunSavedBeforeTheUpdateSurvivesIt() {
        val defaults = InMemoryStore()
        val other = DrillLibrary.rooms.first().drills.first { it.kind is DrillKind.Quiz }
        val legacy = OrdinaryRun(other, index = 2, answers = listOf(true, true))
        defaults.putString(OrdinaryRunStore.KEY, legacy.toJson().toString())
        val store = OrdinaryRunStore(defaults)
        assertEquals(listOf(legacy), store.runs)
        store.save(legacy.copy(index = 3, answers = listOf(true, true, false)))
        assertFalse("The old slot goes once the new list is written", defaults.contains(OrdinaryRunStore.KEY))

        val empty = InMemoryStore()
        empty.putString(OrdinaryRunStore.KEY, OrdinaryRun(other).toJson().toString())
        assertTrue("An unanswered legacy run is not offered", OrdinaryRunStore(empty).runs.isEmpty())
    }

    /** A lapsed member keeps the run on disk but is never offered it. */
    @Test
    fun aLockedRunIsKeptButNotOffered() {
        val defaults = InMemoryStore()
        val store = OrdinaryRunStore(defaults)
        val plus = DrillLibrary.rooms.first { it.isFree }.drills.first { it.isPlus }
        store.save(OrdinaryRun(plus, index = 1, answers = listOf(true)))
        val memberItems = SessionBuilder.quickSession(seen = emptySet(), missed = emptySet(), includePro = true, count = 200)
        val quick = OrdinaryRun(SessionBuilder.sessionDrill, memberItems, index = 1, answers = listOf(true))
        store.save(quick)
        assertTrue(quick.isLocked(isMember = false))
        assertTrue(store.resumable(isMember = false).isEmpty())
        assertEquals(2, store.resumable(isMember = true).size)
        assertEquals(2, OrdinaryRunStore(defaults).runs.size)
        val freeQuick = quick.copy(items = SessionBuilder.quickSession(seen = emptySet(), missed = emptySet(), includePro = false))
        assertFalse(freeQuick.isLocked(isMember = false))
    }
}
