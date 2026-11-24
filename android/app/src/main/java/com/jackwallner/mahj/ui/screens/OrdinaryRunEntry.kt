package com.jackwallner.mahj.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jackwallner.mahj.data.OrdinaryRun
import com.jackwallner.mahj.model.DrillKind
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.theme.BarTextButton
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjScreen
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA

/**
 * A room drill with a saved run asks Resume or Start over. Decide before constructing the runner
 * so Start over creates fresh state. `askFirst` is false for Home's Resume card, which goes
 * straight back in.
 */
@Composable
fun OrdinaryRunEntry(id: String, title: String, askFirst: Boolean = true, content: @Composable () -> Unit) {
    val store = LocalGraph.current.ordinaryRuns
    val navigator = LocalNavigator.current
    val saved = remember { store.run(id) }
    var decided by remember { mutableStateOf(saved == null || !askFirst) }
    if (decided || saved == null) {
        content()
    } else {
        MahjScreen(title, onBack = { navigator.pop() }) {
            Column(
                Modifier.fillMaxSize().padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(18.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.weight(1f))
                // The bar already names the drill; the middle says what Resume brings back.
                Text(position(saved), style = MahjType.display(28.sp), color = Mahj.colors.ink, textAlign = TextAlign.Center)
                Spacer(Modifier.weight(1f))
                PrimaryCTA("Resume") { decided = true }
                BarTextButton("Start over", Mahj.colors.inkSecondary) {
                    store.clear(id)
                    decided = true
                }
            }
        }
    }
}

/** Where a saved run stands: cards down for a deck, otherwise the question (or deal) it resumes on. */
fun position(run: OrdinaryRun): String {
    val total = run.drill.kind.itemCount
    if (run.drill.kind is DrillKind.Flashcards) return "${total - run.queue.size} of $total down"
    return "Question ${minOf(run.index + 1, total)} of $total"
}
