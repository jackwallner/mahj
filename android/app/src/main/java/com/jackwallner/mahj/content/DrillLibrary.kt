package com.jackwallner.mahj.content

import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.Room

object DrillLibrary {
    val rooms: List<Room> get() = MahjContent.library.rooms

    fun room(id: String): Room? = rooms.firstOrNull { it.id == id }

    /** The room a drill belongs to, so drill screens can report per-room accuracy. */
    fun roomID(forDrillID: String): String =
        rooms.firstOrNull { room -> room.drills.any { it.id == forDrillID } }?.id ?: ""
}

object HowToPlayContent {
    val pages: List<HowToPlayPage> get() = MahjContent.library.primer

    /** The room recommended at the end of the primer for an onboarding skill level. */
    fun recommendedRoom(skillLevel: String): Room {
        val roomID = when (skillLevel) {
            "basics" -> "card-room"
            "played" -> "table-room"
            else -> "tile-room"
        }
        return DrillLibrary.room(roomID) ?: DrillLibrary.rooms.first()
    }
}

object ReferenceContent {
    val sections: List<SectionReference> get() = MahjContent.library.referenceSections
    val glossary: List<GlossaryTerm> get() = MahjContent.library.glossary

    fun sections(query: String): List<SectionReference> {
        val needle = query.lowercase()
        if (needle.isEmpty()) return sections
        return sections.filter {
            it.category.displayName.lowercase().contains(needle) ||
                it.category.shortName.lowercase().contains(needle) ||
                it.category.howToSpot.lowercase().contains(needle) ||
                it.watchOut.lowercase().contains(needle)
        }
    }

    fun section(category: HandCategory): SectionReference? = sections.firstOrNull { it.category == category }

    fun terms(group: GlossaryGroup, query: String = ""): List<GlossaryTerm> =
        glossary.filter { it.matches(query) && it.group == group }

    fun terms(query: String): List<GlossaryTerm> = glossary.filter { it.matches(query) }
}
