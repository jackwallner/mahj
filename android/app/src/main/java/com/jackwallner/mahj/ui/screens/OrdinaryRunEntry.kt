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
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.jackwallner.mahj.ui.LocalGraph
import com.jackwallner.mahj.ui.nav.LocalNavigator
import com.jackwallner.mahj.ui.theme.BarTextButton
import com.jackwallner.mahj.ui.theme.Mahj
import com.jackwallner.mahj.ui.theme.MahjScreen
import com.jackwallner.mahj.ui.theme.MahjType
import com.jackwallner.mahj.ui.theme.PrimaryCTA

/** Decide before constructing the runner so Start over creates fresh state. */
@Composable
fun OrdinaryRunEntry(id: String, title: String, content: @Composable () -> Unit) {
    val store = LocalGraph.current.ordinaryRuns
    val navigator = LocalNavigator.current
    val saved = remember { store.run(id) }
    var decided by remember { mutableStateOf(saved == null) }
    if (decided) {
        content()
    } else {
        MahjScreen(title, onBack = { navigator.pop() }) {
            Column(Modifier.fillMaxSize().padding(20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                Spacer(Modifier.weight(1f))
                Text(title, style = MahjType.headline, color = Mahj.colors.ink)
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
