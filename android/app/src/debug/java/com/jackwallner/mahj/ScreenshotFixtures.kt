package com.jackwallner.mahj

import com.jackwallner.mahj.content.DrillLibrary
import com.jackwallner.mahj.data.PracticeRecordStore

/** A believable week of practice for screenshots: real items, real grading paths. */
object ScreenshotFixtures {
    fun seed(graph: AppGraph) {
        val rooms = DrillLibrary.rooms.take(3)
        rooms.forEachIndexed { roomIndex, room ->
            val ids = PracticeRecordStore.trackableItemIDs(room, isMember = true)
            val known = ids.take(ids.size * (3 - roomIndex) / 5)
            known.forEach { id ->
                graph.recordAnswer(id, room.id, correct = true)
                graph.recordAnswer(id, room.id, correct = true)
            }
            ids.drop(known.size).take(2).forEach { id -> graph.recordAnswer(id, room.id, correct = false) }
            room.drills.first().let { graph.progress.recordSession(it.id) }
        }
    }

    private fun AppGraph.recordAnswer(id: String, roomID: String, correct: Boolean) {
        progress.recordItem(id, correct)
        records.record(id, roomID, correct)
    }
}
