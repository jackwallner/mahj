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
        store.save(OrdinaryRun(drill, pendingAnswer = before, undoCardID = card.id, undoAnswer = before))
        val saved = OrdinaryRunStore(defaults).inProgress!!
        assertEquals(before, saved.pendingAnswer)
        assertEquals(card.id, saved.undoCardID)
        records.restoreAnswer(saved.undoAnswer!!.practice)
        assertNull(records.records[card.id])
    }

}
