package com.jackwallner.mahj.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.jackwallner.mahj.content.GlossaryGroup
import com.jackwallner.mahj.content.GlossaryTerm
import com.jackwallner.mahj.content.ReferenceContent
import com.jackwallner.mahj.content.SectionReference
import com.jackwallner.mahj.model.racked
import com.jackwallner.mahj.ui.components.TileRack
import com.jackwallner.mahj.ui.components.symbol
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.theme.Eyebrow
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjScreen
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.Readable
import com.jackwallner.mahj.ui.theme.Segmented
import com.jackwallner.mahj.ui.theme.navBarPadding
import com.jackwallner.mahj.ui.theme.pressable
import com.jackwallner.mahj.ui.theme.rounded
import com.jackwallner.mahj.ui.theme.themedCard

private enum class ReferenceTab(val title: String) { GLOSSARY("Glossary"), SECTIONS("Sections") }

/** The at-the-table reference: search a term, or read a section. Free for everyone. */
@Composable
fun ReferenceScreen() {
    val navigator = LocalNavigator.current
    val colors = Mahj.colors
    var query by rememberSaveable { mutableStateOf("") }
    var tab by rememberSaveable { mutableStateOf(ReferenceTab.GLOSSARY) }
    var expanded by rememberSaveable { mutableStateOf<String?>(null) }
    MahjScreen("Reference", onBack = { navigator.pop() }) {
        Readable {
            Column(Modifier.padding(horizontal = 16.dp).padding(bottom = 10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                SearchField(query, if (tab == ReferenceTab.GLOSSARY) "Search terms" else "Search sections") { query = it }
                Segmented(ReferenceTab.entries, tab, { it.title }) { tab = it }
            }
        }
        Readable(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
            Column(Modifier.padding(horizontal = 16.dp).padding(navBarPadding(28.dp)), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                when (tab) {
                    ReferenceTab.GLOSSARY -> {
                        val groups = GlossaryGroup.entries.mapNotNull { group ->
                            ReferenceContent.terms(group, query).takeIf { it.isNotEmpty() }?.let { group to it }
                        }
                        if (groups.isEmpty()) {
                            EmptyState("magnifyingglass", "Nothing matches \"$query\"", "Try a shorter word. Nicknames work too: soap, news, wild.")
                        }
                        groups.forEach { (group, terms) -> GlossaryGroupCard(group, terms) }
                    }
                    ReferenceTab.SECTIONS -> {
                        val matches = ReferenceContent.sections(query)
                        if (matches.isEmpty()) {
                            EmptyState("menucard", "No section matches \"$query\"", "Sections are families like evens, odds, 369 and consecutive runs.")
                        } else {
                            Text(
                                "Every rack below is an original teaching example for the shape of the section. For the actual hands and their values, use the current NMJL card.",
                                style = MahjType.caption,
                                color = colors.inkTertiary,
                                modifier = Modifier.fillMaxWidth().padding(top = 6.dp).background(colors.well, rounded(14.dp)).padding(12.dp),
                            )
                            matches.forEach { reference ->
                                SectionCard(reference, expanded == reference.category.raw) {
                                    expanded = if (expanded == reference.category.raw) null else reference.category.raw
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SearchField(query: String, placeholder: String, onChange: (String) -> Unit) {
    val colors = Mahj.colors
    Row(
        Modifier.fillMaxWidth().heightIn(min = 40.dp).background(colors.well, RoundedCornerShape(10.dp)).padding(horizontal = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(symbol("magnifyingglass"), null, tint = colors.inkTertiary, modifier = Modifier.size(18.dp))
        Box(Modifier.weight(1f)) {
            if (query.isEmpty()) Text(placeholder, style = MahjType.body, color = colors.inkTertiary)
            BasicTextField(
                query,
                onChange,
                singleLine = true,
                textStyle = MahjType.body.copy(color = colors.ink),
                cursorBrush = SolidColor(colors.jade),
                modifier = Modifier.fillMaxWidth().testTag("reference-search"),
            )
        }
    }
}

@Composable
private fun GlossaryGroupCard(group: GlossaryGroup, terms: List<GlossaryTerm>) {
    val colors = Mahj.colors
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.padding(horizontal = 4.dp).padding(top = 6.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(symbol(group.icon), null, tint = colors.jade, modifier = Modifier.size(14.dp))
            Eyebrow(group.title.uppercase())
        }
        Column(Modifier.fillMaxWidth().themedCard(16.dp)) {
            terms.forEachIndexed { index, term ->
                Column(Modifier.fillMaxWidth().padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(term.term, style = MahjType.headline, color = colors.ink)
                    Text(term.definition, style = MahjType.subheadline, color = colors.inkSecondary)
                }
                if (index < terms.lastIndex) Box(Modifier.fillMaxWidth().padding(start = 14.dp).height(1.dp).background(colors.rule))
            }
        }
    }
}

@Composable
private fun SectionCard(reference: SectionReference, expanded: Boolean, onToggle: () -> Unit) {
    val colors = Mahj.colors
    val chevron by animateFloatAsState(if (expanded) 180f else 0f, label = "chevron")
    Column(Modifier.fillMaxWidth().themedCard(16.dp).padding(14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(Modifier.fillMaxWidth().pressable(onClick = onToggle), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(reference.category.displayName, style = MahjType.headline, color = colors.ink)
                Text(reference.category.howToSpot, style = MahjType.subheadline, color = colors.inkSecondary)
            }
            Icon(symbol("chevron.down"), null, tint = colors.inkTertiary, modifier = Modifier.size(20.dp).rotate(chevron))
        }
        AnimatedVisibility(expanded, enter = fadeIn() + expandVertically(), exit = fadeOut() + shrinkVertically()) {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Eyebrow("AN EXAMPLE OF THE SHAPE", colors.inkTertiary)
                TileRack(reference.exampleRack.racked, Modifier.fillMaxWidth(), tileWidth = 36.dp)
                Row(
                    Modifier.fillMaxWidth().background(colors.gold.copy(alpha = 0.12f), rounded(10.dp)).padding(10.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(symbol("exclamationmark.triangle.fill"), null, tint = colors.gold, modifier = Modifier.size(14.dp))
                    Text(reference.watchOut, style = MahjType.footnote, color = colors.ink)
                }
            }
        }
    }
}

@Composable
private fun EmptyState(icon: String, title: String, body: String) {
    val colors = Mahj.colors
    Column(
        Modifier.fillMaxWidth().padding(top = 16.dp).themedCard().padding(28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(symbol(icon), null, tint = colors.jade.copy(alpha = 0.5f), modifier = Modifier.size(34.dp))
        Text(title, style = MahjType.headline, color = colors.ink, textAlign = TextAlign.Center)
        Text(body, style = MahjType.subheadline, color = colors.inkSecondary, textAlign = TextAlign.Center)
    }
}
