package com.jackwallner.mahj.content

import com.jackwallner.mahj.model.CardChoice
import com.jackwallner.mahj.model.CategoryText
import com.jackwallner.mahj.model.CharlestonScenario
import com.jackwallner.mahj.model.Drill
import com.jackwallner.mahj.model.DrillKind
import com.jackwallner.mahj.model.Flashcard
import com.jackwallner.mahj.model.HandCategory
import com.jackwallner.mahj.model.HandMatchQuestion
import com.jackwallner.mahj.model.QuizQuestion
import com.jackwallner.mahj.model.Room
import com.jackwallner.mahj.model.Tile
import org.json.JSONArray
import org.json.JSONObject

data class HowToPlayPage(
    val id: String,
    val icon: String,
    val title: String,
    val body: String,
    val tiles: List<Tile>,
    val tip: String?,
)

enum class GlossaryGroup(val raw: String, val title: String, val icon: String) {
    TILES("tiles", "Tiles", "square.grid.3x3.fill"),
    GROUPS("groups", "Groups & Hands", "rectangle.stack.fill"),
    CHARLESTON("charleston", "The Charleston", "arrow.triangle.2.circlepath"),
    PLAY("play", "At the Table", "hand.point.up.left.fill"),
}

data class GlossaryTerm(
    val id: String,
    val term: String,
    /** Extra spellings a player might search for. Never shown, only matched. */
    val aliases: List<String>,
    val group: GlossaryGroup,
    val definition: String,
) {
    fun matches(query: String): Boolean {
        val needle = query.lowercase()
        if (needle.isEmpty()) return true
        return term.lowercase().contains(needle) ||
            aliases.any { it.lowercase().contains(needle) } ||
            definition.lowercase().contains(needle)
    }
}

data class SectionReference(val category: HandCategory, val exampleRack: List<Tile>, val watchOut: String)

data class WhatsNewItem(val id: String, val icon: String, val title: String, val body: String, val isPlus: Boolean)

data class WhatsNewRelease(val version: String, val headline: String, val items: List<WhatsNewItem>)

class ContentLibrary(
    val rooms: List<Room>,
    val categoryText: Map<HandCategory, CategoryText>,
    val primer: List<HowToPlayPage>,
    val referenceSections: List<SectionReference>,
    val glossary: List<GlossaryTerm>,
    val whatsNew: List<WhatsNewRelease>,
)

/**
 * Every authored drill, the primer, the reference and the release notes,
 * exported from the iOS sources by `scripts/sync-android-content.sh`. Loaded
 * from a classpath resource so JVM unit tests read exactly what the app reads.
 */
object MahjContent {
    val library: ContentLibrary by lazy { load() }

    private fun load(): ContentLibrary {
        val stream = MahjContent::class.java.classLoader!!.getResourceAsStream("mahj-content.json")
            ?: error("mahj-content.json is missing; run scripts/sync-android-content.sh")
        return parse(JSONObject(stream.bufferedReader().use { it.readText() }))
    }

    fun parse(json: JSONObject): ContentLibrary {
        val categories = json.getJSONArray("categories").objects().associate { item ->
            HandCategory.fromRaw(item.getString("id")) to CategoryText(
                displayName = item.getString("displayName"),
                shortName = item.getString("shortName"),
                howToSpot = item.getString("howToSpot"),
                requires = item.getString("requires"),
            )
        }
        return ContentLibrary(
            rooms = json.getJSONArray("rooms").objects().map(::room),
            categoryText = categories,
            primer = json.getJSONArray("primer").objects().map { item ->
                HowToPlayPage(
                    id = item.getString("id"),
                    icon = item.getString("icon"),
                    title = item.getString("title"),
                    body = item.getString("body"),
                    tiles = item.getJSONArray("tiles").tiles(),
                    tip = item.optStringOrNull("tip"),
                )
            },
            referenceSections = json.getJSONArray("referenceSections").objects().map { item ->
                SectionReference(
                    category = HandCategory.fromRaw(item.getString("category")),
                    exampleRack = item.getJSONArray("exampleRack").tiles(),
                    watchOut = item.getString("watchOut"),
                )
            },
            glossary = json.getJSONArray("glossary").objects().map { item ->
                GlossaryTerm(
                    id = item.getString("id"),
                    term = item.getString("term"),
                    aliases = item.getJSONArray("aliases").strings(),
                    group = GlossaryGroup.entries.first { it.raw == item.getString("group") },
                    definition = item.getString("definition"),
                )
            },
            whatsNew = json.getJSONArray("whatsNew").objects().map { release ->
                WhatsNewRelease(
                    version = release.getString("version"),
                    headline = release.getString("headline"),
                    items = release.getJSONArray("items").objects().map { item ->
                        WhatsNewItem(
                            id = item.getString("id"),
                            icon = item.getString("icon"),
                            title = item.getString("title"),
                            body = item.getString("body"),
                            isPlus = item.getBoolean("isPlus"),
                        )
                    },
                )
            },
        )
    }

    private fun room(json: JSONObject) = Room(
        id = json.getString("id"),
        name = json.getString("name"),
        tagline = json.getString("tagline"),
        icon = json.getString("icon"),
        isFree = json.getBoolean("isFree"),
        drills = json.getJSONArray("drills").objects().map(::drill),
    )

    private fun drill(json: JSONObject): Drill {
        val items = json.getJSONArray("items").objects()
        val kind = when (val raw = json.getString("kind")) {
            "flashcards" -> DrillKind.Flashcards(items.map(::flashcard))
            "quiz" -> DrillKind.Quiz(items.map(::quiz))
            "handMatch" -> DrillKind.HandMatch(items.map(::handMatch))
            "charleston" -> DrillKind.Charleston(items.map(::charleston))
            else -> error("Unknown drill kind $raw")
        }
        return Drill(
            id = json.getString("id"),
            title = json.getString("title"),
            subtitle = json.getString("subtitle"),
            kind = kind,
            isPlus = json.getBoolean("isPlus"),
        )
    }

    private fun flashcard(json: JSONObject) = Flashcard(
        id = json.getString("id"),
        frontTitle = json.getString("frontTitle"),
        frontTiles = json.getJSONArray("frontTiles").tiles(),
        frontSubtitle = json.optStringOrNull("frontSubtitle"),
        backTitle = json.getString("backTitle"),
        backBody = json.getString("backBody"),
        choice = json.optJSONObject("choice")?.let {
            CardChoice(it.getJSONArray("options").strings(), it.getInt("answerIndex"))
        },
    )

    private fun quiz(json: JSONObject) = QuizQuestion(
        id = json.getString("id"),
        prompt = json.getString("prompt"),
        tiles = json.getJSONArray("tiles").tiles(),
        choices = json.getJSONArray("choices").strings(),
        answerIndex = json.getInt("answerIndex"),
        explanation = json.getString("explanation"),
    )

    private fun handMatch(json: JSONObject) = HandMatchQuestion(
        id = json.getString("id"),
        tiles = json.getJSONArray("tiles").tiles(),
        choices = json.getJSONArray("choices").strings().map(HandCategory::fromRaw),
        answer = HandCategory.fromRaw(json.getString("answer")),
        explanation = json.getString("explanation"),
    )

    private fun charleston(json: JSONObject) = CharlestonScenario(
        id = json.getString("id"),
        situation = json.getString("situation"),
        deal = json.getJSONArray("deal").tiles(),
        recommendedPass = json.getJSONArray("recommendedPass").tiles(),
        reasoning = json.getString("reasoning"),
        tip = json.getString("tip"),
    )
}

internal fun JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }
internal fun JSONArray.strings(): List<String> = (0 until length()).map { getString(it) }
internal fun JSONArray.tiles(): List<Tile> = strings().map(Tile::fromCode)
internal fun JSONObject.optStringOrNull(key: String): String? = if (has(key) && !isNull(key)) getString(key) else null
