package com.hsaffiliate.aquahunter.ui

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import com.hsaffiliate.aquahunter.ui.components.BrandMark
import com.hsaffiliate.aquahunter.ui.components.NavGlyph
import com.hsaffiliate.aquahunter.ui.legal.MARITIME_RISK_NOTICE_VERSION
import com.hsaffiliate.aquahunter.ui.legal.MaritimeRiskGate
import com.hsaffiliate.aquahunter.ui.screens.MarketsScreen
import com.hsaffiliate.aquahunter.ui.screens.NetworkScreen
import com.hsaffiliate.aquahunter.ui.screens.OverviewScreen
import com.hsaffiliate.aquahunter.ui.screens.RadarScreen
import com.hsaffiliate.aquahunter.ui.screens.AppBackgroundStyle
import com.hsaffiliate.aquahunter.ui.screens.AquaAppLanguage
import com.hsaffiliate.aquahunter.ui.screens.SettingsScreen
import com.hsaffiliate.aquahunter.ui.theme.AquaMint
import com.hsaffiliate.aquahunter.ui.theme.DeepOcean
import com.hsaffiliate.aquahunter.ui.theme.Divider
import com.hsaffiliate.aquahunter.ui.theme.OceanSurface
import com.hsaffiliate.aquahunter.ui.theme.SignalBlue
import com.hsaffiliate.aquahunter.ui.theme.TextPrimary
import com.hsaffiliate.aquahunter.ui.theme.TextSecondary

enum class AppScreen(val label: String) {
    Pulse("Pulse"),
    Markets("Markets"),
    Radar("Radar"),
    Network("Network"),
}

@Composable
fun AquaHunterApp() {
    val context = LocalContext.current
    val legalPreferences = remember {
        context.getSharedPreferences("aquahunter_legal", android.content.Context.MODE_PRIVATE)
    }
    var acceptedRiskVersion by remember {
        mutableStateOf(legalPreferences.getString("maritime_risk_version", "").orEmpty())
    }
    var selectedScreen by remember { mutableStateOf(AppScreen.Pulse) }
    var showsSettings by remember { mutableStateOf(false) }
    var backgroundStyleRaw by remember {
        mutableStateOf(legalPreferences.getString("background_style", AppBackgroundStyle.Ocean.name).orEmpty())
    }
    var languageRaw by remember {
        mutableStateOf(legalPreferences.getString("app_language", AquaAppLanguage.English.code).orEmpty())
    }
    val backgroundStyle = AppBackgroundStyle.from(backgroundStyleRaw)
    val language = AquaAppLanguage.from(languageRaw)

    if (acceptedRiskVersion != MARITIME_RISK_NOTICE_VERSION) {
        MaritimeRiskGate {
            legalPreferences.edit()
                .putString("maritime_risk_version", MARITIME_RISK_NOTICE_VERSION)
                .apply()
            acceptedRiskVersion = MARITIME_RISK_NOTICE_VERSION
        }
        return
    }

    CompositionLocalProvider(
        LocalLayoutDirection provides if (language == AquaAppLanguage.Arabic) LayoutDirection.Rtl else LayoutDirection.Ltr,
    ) {
        Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = backgroundStyle.color,
        topBar = {
            AquaHeader(
                backgroundColor = backgroundStyle.color,
                showSettings = !showsSettings && selectedScreen == AppScreen.Pulse,
                onOpenSettings = { showsSettings = true },
            )
        },
        bottomBar = {
            if (!showsSettings) {
            NavigationBar(
                containerColor = OceanSurface,
                tonalElevation = 0.dp,
            ) {
                AppScreen.entries.forEach { screen ->
                    val selected = selectedScreen == screen
                    NavigationBarItem(
                        selected = selected,
                        onClick = { selectedScreen = screen },
                        icon = { NavGlyph(screen = screen, selected = selected) },
                        label = {
                            Text(
                                language.navigationLabel(screen),
                                fontSize = 9.sp,
                                fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = SignalBlue,
                            selectedTextColor = SignalBlue,
                            indicatorColor = SignalBlue.copy(alpha = 0.14f),
                            unselectedIconColor = TextSecondary,
                            unselectedTextColor = TextSecondary,
                        ),
                    )
                }
            }
            }
        },
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(backgroundStyle.color),
        ) {
            if (showsSettings) {
                SettingsScreen(
                    backgroundStyle = backgroundStyle,
                    language = language,
                    onBackgroundStyleChange = { style ->
                        backgroundStyleRaw = style.name
                        legalPreferences.edit().putString("background_style", style.name).apply()
                    },
                    onLanguageChange = { selected ->
                        languageRaw = selected.code
                        legalPreferences.edit().putString("app_language", selected.code).apply()
                    },
                    onClose = { showsSettings = false },
                )
            } else Crossfade(targetState = selectedScreen, label = "main-navigation") { screen ->
                when (screen) {
                    AppScreen.Pulse -> OverviewScreen(
                        onOpenMarkets = { selectedScreen = AppScreen.Markets },
                        onOpenRadar = { selectedScreen = AppScreen.Radar },
                        onOpenNetwork = { selectedScreen = AppScreen.Network },
                    )
                    AppScreen.Markets -> MarketsScreen()
                    AppScreen.Radar -> RadarScreen()
                    AppScreen.Network -> NetworkScreen()
                }
            }
        }
    }
    }
}

@Composable
private fun AquaHeader(
    backgroundColor: Color,
    showSettings: Boolean,
    onOpenSettings: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(backgroundColor)
            .statusBarsPadding(),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(66.dp)
                .padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                BrandMark()
                Spacer(Modifier.size(10.dp))
                Column {
                    Text(
                        text = "AQUA",
                        color = TextPrimary,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.2.sp,
                    )
                    Text(
                        text = "HUNTER",
                        color = SignalBlue,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.2.sp,
                    )
                }
            }
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                if (showSettings) {
                    IconButton(onClick = onOpenSettings) {
                        Icon(
                            Icons.Outlined.Settings,
                            contentDescription = "Settings",
                            tint = SignalBlue,
                        )
                    }
                }
                Box(
                    modifier = Modifier
                        .size(34.dp)
                        .background(MaterialTheme.colorScheme.surfaceVariant, androidx.compose.foundation.shape.CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Text("AH", color = SignalBlue, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(Divider.copy(alpha = 0.55f)))
    }
}
