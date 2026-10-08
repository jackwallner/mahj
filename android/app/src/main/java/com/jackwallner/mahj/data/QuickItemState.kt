package com.jackwallner.mahj.data

import com.jackwallner.mahj.content.QuickItem
import com.jackwallner.mahj.model.Tile
import org.json.JSONArray
import org.json.JSONObject

/** Saves the dealt questions themselves, so recreation never deals a different rack. */
object QuickItemState {
    fun encode(items: List<QuickItem>): String = JSONArray(items.map { item ->
        JSONObject().apply {
            put("id", item.id)
            put("prompt", item.prompt)
            put("tiles", JSONArray(item.tiles.map { it.shortLabel }))
            put("choices", JSONArray(item.choices))
            put("answerIndex", item.answerIndex)
            put("explanation", item.explanation)
            put("sourceLabel", item.sourceLabel)
            put("roomID", item.roomID)
            put("trackingID", item.trackingID)
            put("isReviewable", item.isReviewable)
            put("choiceNotes", JSONArray(item.choiceNotes.map { it ?: JSONObject.NULL }))
        }
    }).toString()

    fun decode(value: String): List<QuickItem> {
        val array = JSONArray(value)
        return List(array.length()) { index ->
            val item = array.getJSONObject(index)
            val tiles = item.getJSONArray("tiles")
            val choices = item.getJSONArray("choices")
            val notes = item.getJSONArray("choiceNotes")
            QuickItem(
                id = item.getString("id"),
                prompt = item.getString("prompt"),
                tiles = List(tiles.length()) { Tile.fromCode(tiles.getString(it)) },
                choices = List(choices.length()) { choices.getString(it) },
                answerIndex = item.getInt("answerIndex"),
                explanation = item.getString("explanation"),
                sourceLabel = item.getString("sourceLabel"),
                roomID = item.getString("roomID"),
                trackingID = item.getString("trackingID"),
                isReviewable = item.getBoolean("isReviewable"),
                choiceNotes = List(notes.length()) { if (notes.isNull(it)) null else notes.getString(it) },
            )
        }
    }
}
