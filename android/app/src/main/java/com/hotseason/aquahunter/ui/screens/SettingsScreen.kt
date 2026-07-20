package com.hotseason.aquahunter.ui.screens

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.BugReport
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ColorLens
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Gavel
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hotseason.aquahunter.ui.AppScreen
import com.hotseason.aquahunter.ui.components.DataCard
import com.hotseason.aquahunter.ui.components.SectionHeader
import com.hotseason.aquahunter.ui.legal.MaritimeRiskNoticeContent
import com.hotseason.aquahunter.ui.theme.AquaMint
import com.hotseason.aquahunter.ui.theme.DeepOcean
import com.hotseason.aquahunter.ui.theme.SignalBlue
import com.hotseason.aquahunter.ui.theme.SunGold
import com.hotseason.aquahunter.ui.theme.TextPrimary
import com.hotseason.aquahunter.ui.theme.TextSecondary

enum class AppBackgroundStyle(val title: String, val color: Color) {
    Ocean("Ocean Blue", DeepOcean),
    Midnight("Midnight Navy", Color(0xFF0D122B)),
    Teal("Deep Teal", Color(0xFF022830)),
    Black("True Black", Color.Black),
    ;

    companion object {
        fun from(raw: String): AppBackgroundStyle = entries.firstOrNull { it.name == raw } ?: Ocean
    }
}

enum class AquaAppLanguage(val code: String, val nativeName: String) {
    English("en", "English"),
    SimplifiedChinese("zh-Hans", "简体中文"),
    TraditionalChinese("zh-Hant", "繁體中文"),
    Spanish("es", "Español"),
    French("fr", "Français"),
    German("de", "Deutsch"),
    Japanese("ja", "日本語"),
    Korean("ko", "한국어"),
    Portuguese("pt-BR", "Português"),
    Indonesian("id", "Bahasa Indonesia"),
    Hindi("hi", "हिन्दी"),
    Arabic("ar", "العربية"),
    ;

    fun navigationLabel(screen: AppScreen): String {
        val index = screen.ordinal
        return when (this) {
            English -> listOf("Pulse", "Markets", "Radar", "Network")[index]
            SimplifiedChinese -> listOf("脉动", "行情", "雷达", "网络")[index]
            TraditionalChinese -> listOf("脈動", "行情", "雷達", "網路")[index]
            Spanish -> listOf("Pulso", "Mercados", "Radar", "Red")[index]
            French -> listOf("Pouls", "Marchés", "Radar", "Réseau")[index]
            German -> listOf("Puls", "Märkte", "Radar", "Netzwerk")[index]
            Japanese -> listOf("動向", "市場", "レーダー", "ネットワーク")[index]
            Korean -> listOf("동향", "시장", "레이더", "네트워크")[index]
            Portuguese -> listOf("Pulso", "Mercados", "Radar", "Rede")[index]
            Indonesian -> listOf("Denyut", "Pasar", "Radar", "Jaringan")[index]
            Hindi -> listOf("पल्स", "बाज़ार", "रडार", "नेटवर्क")[index]
            Arabic -> listOf("نبض", "الأسواق", "الرادار", "الشبكة")[index]
        }
    }

    companion object {
        fun from(raw: String): AquaAppLanguage = entries.firstOrNull { it.code == raw } ?: English
    }
}

@Composable
fun SettingsScreen(
    backgroundStyle: AppBackgroundStyle,
    language: AquaAppLanguage,
    onBackgroundStyleChange: (AppBackgroundStyle) -> Unit,
    onLanguageChange: (AquaAppLanguage) -> Unit,
    onClose: () -> Unit,
) {
    var languageMenuExpanded by remember { mutableStateOf(false) }
    var showsRiskNotice by remember { mutableStateOf(false) }
    var emailStatus by remember { mutableStateOf<String?>(null) }
    val context = LocalContext.current

    if (showsRiskNotice) {
        RiskNoticeReview(onClose = { showsRiskNotice = false })
        return
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(backgroundStyle.color),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(13.dp),
    ) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onClose) {
                    Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Back", tint = SignalBlue)
                }
                SectionHeader(eyebrow = "AquaHunter", title = "Settings")
            }
            Text(
                "Appearance, language, safety notice and support.",
                color = TextSecondary,
                fontSize = 11.sp,
                modifier = Modifier.padding(start = 48.dp, top = 2.dp),
            )
        }

        item {
            DataCard(Modifier.fillMaxWidth()) {
                SettingsTitle(Icons.Outlined.ColorLens, "Background color")
                Spacer(Modifier.height(10.dp))
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(9.dp),
                ) {
                    AppBackgroundStyle.entries.forEach { style ->
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            modifier = Modifier
                                .background(
                                    if (style == backgroundStyle) SignalBlue.copy(alpha = .16f) else Color.Transparent,
                                    RoundedCornerShape(11.dp),
                                )
                                .clickable { onBackgroundStyleChange(style) }
                                .padding(8.dp),
                        ) {
                            Box(
                                Modifier
                                    .size(42.dp)
                                    .background(style.color, CircleShape)
                                    .then(
                                        if (style == backgroundStyle) {
                                            Modifier.background(SignalBlue.copy(alpha = .20f), CircleShape)
                                        } else {
                                            Modifier
                                        },
                                    ),
                                contentAlignment = Alignment.Center,
                            ) {
                                if (style == backgroundStyle) {
                                    Icon(Icons.Outlined.CheckCircle, null, tint = AquaMint, modifier = Modifier.size(19.dp))
                                }
                            }
                            Spacer(Modifier.height(5.dp))
                            Text(style.title, color = TextSecondary, fontSize = 9.sp)
                        }
                    }
                }
            }
        }

        item {
            DataCard(Modifier.fillMaxWidth()) {
                SettingsTitle(Icons.Outlined.Language, "Interface language")
                Spacer(Modifier.height(9.dp))
                Box {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(DeepOcean.copy(alpha = .55f), RoundedCornerShape(11.dp))
                            .clickable { languageMenuExpanded = true }
                            .padding(horizontal = 12.dp, vertical = 11.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(language.nativeName, color = TextPrimary, fontSize = 12.sp, modifier = Modifier.weight(1f))
                        Text("⌄", color = SignalBlue, fontSize = 14.sp)
                    }
                    DropdownMenu(
                        expanded = languageMenuExpanded,
                        onDismissRequest = { languageMenuExpanded = false },
                    ) {
                        AquaAppLanguage.entries.forEach { item ->
                            DropdownMenuItem(
                                text = { Text(item.nativeName) },
                                onClick = {
                                    onLanguageChange(item)
                                    languageMenuExpanded = false
                                },
                                trailingIcon = {
                                    if (item == language) {
                                        Icon(Icons.Outlined.CheckCircle, null, tint = AquaMint)
                                    }
                                },
                            )
                        }
                    }
                }
                Text(
                    "12 languages, matching Railingo's launch-language set. The navigation shell changes immediately and the selection is stored on this device.",
                    color = TextSecondary,
                    fontSize = 9.sp,
                    lineHeight = 14.sp,
                    modifier = Modifier.padding(top = 8.dp),
                )
            }
        }

        item {
            DataCard(Modifier.fillMaxWidth()) {
                SettingsTitle(Icons.Outlined.Gavel, "Safety & legal")
                Text(
                    "Review the notice accepted on first launch at any time.",
                    color = TextSecondary,
                    fontSize = 10.sp,
                    modifier = Modifier.padding(top = 7.dp),
                )
                Text(
                    "View Maritime Operations & Legal Risk Notice  ›",
                    color = SignalBlue,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { showsRiskNotice = true }
                        .padding(vertical = 12.dp),
                )
            }
        }

        item {
            DataCard(Modifier.fillMaxWidth(), emphasized = true) {
                SettingsTitle(Icons.Outlined.BugReport, "Report a bug")
                Text(
                    "Create a pre-addressed email with app context. Do not include passwords, payment data or confidential catch coordinates.",
                    color = TextSecondary,
                    fontSize = 10.sp,
                    lineHeight = 15.sp,
                    modifier = Modifier.padding(top = 7.dp),
                )
                Button(
                    onClick = {
                        val subject = Uri.encode("AquaHunter bug report")
                        val body = Uri.encode(
                            "Please describe the problem:\n\nSteps to reproduce:\n1. \n2. \n3. \n\nExpected result:\n\nActual result:\n\nApp: AquaHunter 1.0\nPlatform: Android",
                        )
                        val intent = Intent(
                            Intent.ACTION_SENDTO,
                            Uri.parse("mailto:contact@hotseason.app?subject=$subject&body=$body"),
                        )
                        emailStatus = runCatching {
                            context.startActivity(intent)
                            null
                        }.getOrElse { "No email app is configured. Contact contact@hotseason.app directly." }
                    },
                    modifier = Modifier.fillMaxWidth().padding(top = 10.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = SignalBlue, contentColor = DeepOcean),
                ) {
                    Icon(Icons.Outlined.Email, null)
                    Spacer(Modifier.size(8.dp))
                    Text("Email contact@hotseason.app", fontWeight = FontWeight.Bold)
                }
                emailStatus?.let {
                    Text(it, color = SunGold, fontSize = 9.sp, modifier = Modifier.padding(top = 7.dp))
                }
            }
        }

        item {
            Text(
                "AquaHunter 1.0 · © 2026 Hot Season Enterprise, Inc.",
                color = TextSecondary,
                fontSize = 9.sp,
                modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
            )
        }
    }
}

@Composable
private fun SettingsTitle(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = SignalBlue, modifier = Modifier.size(20.dp))
        Spacer(Modifier.size(8.dp))
        Text(title, color = TextPrimary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun RiskNoticeReview(onClose: () -> Unit) {
    Column(Modifier.fillMaxSize().background(DeepOcean)) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onClose) {
                Icon(Icons.AutoMirrored.Outlined.ArrowBack, contentDescription = "Back", tint = SignalBlue)
            }
            Text("Maritime Risk Notice", color = TextPrimary, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp)
                .verticalScroll(rememberScrollState()),
        ) {
            MaritimeRiskNoticeContent()
            Spacer(Modifier.height(24.dp))
        }
    }
}
