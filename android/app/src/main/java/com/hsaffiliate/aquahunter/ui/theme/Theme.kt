package com.hsaffiliate.aquahunter.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val DeepOcean = Color(0xFF041A38)
val OceanSurface = Color(0xFF08254A)
val OceanSurfaceHigh = Color(0xFF0D3260)
val AquaMint = Color(0xFF31D17C)
val SignalBlue = Color(0xFF168DFF)
val RadarCyan = Color(0xFF20C8FF)
val WarmCoral = Color(0xFFFF746C)
val SunGold = Color(0xFFFFC857)
val TextPrimary = Color(0xFFF3F9FF)
val TextSecondary = Color(0xFFA7BED8)
val Divider = Color(0xFF1B4F7A)

private val AquaHunterColors = darkColorScheme(
    primary = SignalBlue,
    onPrimary = TextPrimary,
    primaryContainer = Color(0xFF0B3F78),
    onPrimaryContainer = Color(0xFFD9ECFF),
    secondary = AquaMint,
    onSecondary = DeepOcean,
    secondaryContainer = Color(0xFF124B38),
    onSecondaryContainer = Color(0xFFC9FFE2),
    tertiary = WarmCoral,
    onTertiary = DeepOcean,
    background = DeepOcean,
    onBackground = TextPrimary,
    surface = OceanSurface,
    onSurface = TextPrimary,
    surfaceVariant = OceanSurfaceHigh,
    onSurfaceVariant = TextSecondary,
    outline = Divider,
    error = Color(0xFFFF6B6B),
)

@Composable
fun AquaHunterTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = AquaHunterColors,
        typography = Typography(),
        content = content,
    )
}
