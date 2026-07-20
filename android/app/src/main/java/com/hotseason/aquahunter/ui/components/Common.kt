package com.hotseason.aquahunter.ui.components

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hotseason.aquahunter.ui.AppScreen
import com.hotseason.aquahunter.ui.theme.AquaMint
import com.hotseason.aquahunter.ui.theme.DeepOcean
import com.hotseason.aquahunter.ui.theme.Divider
import com.hotseason.aquahunter.ui.theme.OceanSurface
import com.hotseason.aquahunter.ui.theme.OceanSurfaceHigh
import com.hotseason.aquahunter.ui.theme.RadarCyan
import com.hotseason.aquahunter.ui.theme.SignalBlue
import com.hotseason.aquahunter.ui.theme.SunGold
import com.hotseason.aquahunter.ui.theme.TextPrimary
import com.hotseason.aquahunter.ui.theme.TextSecondary
import com.hotseason.aquahunter.ui.theme.WarmCoral
import kotlin.math.max

@Composable
fun BrandMark(modifier: Modifier = Modifier) {
    Canvas(
        modifier = modifier
            .size(38.dp)
            .semantics { contentDescription = "AquaHunter logo" },
    ) {
        val ringStroke = 1.7.dp.toPx()
        drawCircle(color = SignalBlue.copy(alpha = 0.12f))
        drawCircle(
            color = SignalBlue,
            radius = size.minDimension * 0.43f,
            style = Stroke(width = ringStroke),
        )
        drawCircle(
            color = RadarCyan.copy(alpha = 0.78f),
            radius = size.minDimension * 0.25f,
            style = Stroke(width = 1.1.dp.toPx()),
        )
        drawLine(
            color = RadarCyan.copy(alpha = 0.72f),
            start = Offset(size.width * 0.50f, size.height * 0.50f),
            end = Offset(size.width * 0.23f, size.height * 0.24f),
            strokeWidth = 1.5.dp.toPx(),
            cap = StrokeCap.Round,
        )
        listOf(
            Offset(size.width * 0.50f, size.height * 0.05f) to Offset(size.width * 0.50f, size.height * 0.20f),
            Offset(size.width * 0.50f, size.height * 0.80f) to Offset(size.width * 0.50f, size.height * 0.95f),
            Offset(size.width * 0.05f, size.height * 0.50f) to Offset(size.width * 0.20f, size.height * 0.50f),
            Offset(size.width * 0.80f, size.height * 0.50f) to Offset(size.width * 0.95f, size.height * 0.50f),
        ).forEach { (start, end) ->
            drawLine(SignalBlue, start, end, ringStroke, StrokeCap.Round)
        }

        val trend = Path().apply {
            moveTo(size.width * 0.14f, size.height * 0.71f)
            lineTo(size.width * 0.34f, size.height * 0.55f)
            lineTo(size.width * 0.49f, size.height * 0.64f)
            lineTo(size.width * 0.74f, size.height * 0.35f)
            lineTo(size.width * 0.84f, size.height * 0.40f)
        }
        drawPath(
            path = trend,
            color = AquaMint,
            style = Stroke(width = 2.dp.toPx(), cap = StrokeCap.Round),
        )
        drawLine(
            color = AquaMint,
            start = Offset(size.width * 0.74f, size.height * 0.35f),
            end = Offset(size.width * 0.82f, size.height * 0.30f),
            strokeWidth = 2.dp.toPx(),
            cap = StrokeCap.Round,
        )
        drawLine(
            color = AquaMint,
            start = Offset(size.width * 0.74f, size.height * 0.35f),
            end = Offset(size.width * 0.79f, size.height * 0.43f),
            strokeWidth = 2.dp.toPx(),
            cap = StrokeCap.Round,
        )

        listOf(
            Offset(size.width * 0.60f, size.height * 0.66f),
            Offset(size.width * 0.70f, size.height * 0.75f),
            Offset(size.width * 0.55f, size.height * 0.79f),
        ).forEach { center ->
            drawOval(
                color = TextPrimary,
                topLeft = Offset(center.x - size.width * 0.055f, center.y - size.height * 0.025f),
                size = Size(size.width * 0.11f, size.height * 0.05f),
            )
            val tail = Path().apply {
                moveTo(center.x - size.width * 0.045f, center.y)
                lineTo(center.x - size.width * 0.085f, center.y - size.height * 0.035f)
                lineTo(center.x - size.width * 0.085f, center.y + size.height * 0.035f)
                close()
            }
            drawPath(tail, TextPrimary)
        }
        drawCircle(
            color = SignalBlue,
            radius = size.minDimension * 0.055f,
            center = center,
        )
    }
}

@Composable
fun SectionHeader(
    eyebrow: String,
    title: String,
    modifier: Modifier = Modifier,
    action: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (eyebrow.isNotBlank()) {
            Text(
                text = eyebrow.uppercase(),
                color = SignalBlue,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.4.sp,
            )
            Spacer(Modifier.height(5.dp))
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(
                text = title,
                color = TextPrimary,
                fontSize = 24.sp,
                lineHeight = 28.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f),
            )
            if (action != null && onAction != null) {
                Text(
                    text = action,
                    color = SignalBlue,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .clickable(role = Role.Button, onClick = onAction)
                        .padding(horizontal = 8.dp, vertical = 6.dp),
                )
            }
        }
    }
}

@Composable
fun DataCard(
    modifier: Modifier = Modifier,
    emphasized: Boolean = false,
    content: @Composable ColumnScope.() -> Unit,
) {
    Surface(
        modifier = modifier,
        color = if (emphasized) OceanSurfaceHigh else OceanSurface,
        shape = RoundedCornerShape(18.dp),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            if (emphasized) SignalBlue.copy(alpha = 0.34f) else Divider.copy(alpha = 0.72f),
        ),
    ) {
        Column(modifier = Modifier.padding(16.dp), content = content)
    }
}

@Composable
fun MetricCard(
    label: String,
    value: String,
    detail: String,
    accent: Color,
    modifier: Modifier = Modifier,
) {
    DataCard(modifier = modifier) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(7.dp).background(accent, CircleShape))
            Spacer(Modifier.size(7.dp))
            Text(
                text = label.uppercase(),
                color = TextSecondary,
                fontSize = 9.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 0.8.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Spacer(Modifier.height(11.dp))
        Text(
            text = value,
            color = TextPrimary,
            fontSize = 22.sp,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.height(3.dp))
        Text(
            text = detail,
            color = accent,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
fun SearchField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(OceanSurface)
            .border(1.dp, Divider.copy(alpha = 0.75f), RoundedCornerShape(14.dp))
            .padding(horizontal = 14.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Canvas(Modifier.size(17.dp)) {
            drawCircle(
                color = TextSecondary,
                radius = size.minDimension * 0.32f,
                center = Offset(size.width * 0.42f, size.height * 0.42f),
                style = Stroke(width = 1.8.dp.toPx()),
            )
            drawLine(
                color = TextSecondary,
                start = Offset(size.width * 0.66f, size.height * 0.66f),
                end = Offset(size.width * 0.92f, size.height * 0.92f),
                strokeWidth = 1.8.dp.toPx(),
                cap = StrokeCap.Round,
            )
        }
        Spacer(Modifier.size(10.dp))
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.weight(1f),
            singleLine = true,
            textStyle = TextStyle(color = TextPrimary, fontSize = 14.sp),
            decorationBox = { innerTextField ->
                Box {
                    if (value.isBlank()) {
                        Text(text = placeholder, color = TextSecondary, fontSize = 14.sp)
                    }
                    innerTextField()
                }
            },
        )
        if (value.isNotBlank()) {
            Text(
                text = "×",
                color = TextSecondary,
                fontSize = 20.sp,
                modifier = Modifier
                    .clip(CircleShape)
                    .clickable { onValueChange("") }
                    .padding(horizontal = 6.dp),
            )
        }
    }
}

@Composable
fun FilterPill(
    text: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier.clickable(role = Role.RadioButton, onClick = onClick),
        color = if (selected) SignalBlue else OceanSurface,
        contentColor = if (selected) DeepOcean else TextSecondary,
        shape = RoundedCornerShape(10.dp),
        border = androidx.compose.foundation.BorderStroke(
            1.dp,
            if (selected) SignalBlue else Divider,
        ),
    ) {
        Text(
            text = text,
            fontSize = 12.sp,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 13.dp, vertical = 9.dp),
        )
    }
}

@Composable
fun ChangePill(change: Double, modifier: Modifier = Modifier) {
    val positive = change >= 0
    val color = if (positive) AquaMint else WarmCoral
    Text(
        text = "${if (positive) "↑" else "↓"} ${"%.1f".format(kotlin.math.abs(change))}%",
        color = color,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold,
        modifier = modifier
            .clip(RoundedCornerShape(7.dp))
            .background(color.copy(alpha = 0.11f))
            .padding(horizontal = 7.dp, vertical = 5.dp),
    )
}

@Composable
fun Tag(text: String, modifier: Modifier = Modifier, accent: Color = SignalBlue) {
    Text(
        text = text,
        color = accent,
        fontSize = 10.sp,
        fontWeight = FontWeight.Medium,
        modifier = modifier
            .clip(RoundedCornerShape(6.dp))
            .background(accent.copy(alpha = 0.10f))
            .padding(horizontal = 7.dp, vertical = 4.dp),
    )
}

@Composable
fun Sparkline(
    values: List<Float>,
    modifier: Modifier = Modifier,
    color: Color = AquaMint,
    fill: Boolean = true,
) {
    if (values.size < 2) return
    Canvas(modifier = modifier) {
        val minValue = values.minOrNull() ?: 0f
        val maxValue = values.maxOrNull() ?: 1f
        val range = max(maxValue - minValue, 0.001f)
        val points = values.mapIndexed { index, value ->
            Offset(
                x = size.width * index / (values.size - 1),
                y = size.height - ((value - minValue) / range * size.height * 0.76f) - size.height * 0.12f,
            )
        }
        if (fill) {
            val fillPath = Path().apply {
                moveTo(points.first().x, size.height)
                points.forEach { lineTo(it.x, it.y) }
                lineTo(points.last().x, size.height)
                close()
            }
            drawPath(fillPath, color = color.copy(alpha = 0.08f))
        }
        val linePath = Path().apply {
            moveTo(points.first().x, points.first().y)
            points.drop(1).forEach { lineTo(it.x, it.y) }
        }
        drawPath(linePath, color = color, style = Stroke(width = 2.dp.toPx(), cap = StrokeCap.Round))
        drawCircle(color = color, radius = 3.dp.toPx(), center = points.last())
    }
}

@Composable
fun SegmentedControl(
    options: List<String>,
    selected: String,
    onSelected: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(OceanSurface)
            .padding(4.dp),
    ) {
        options.forEach { option ->
            val isSelected = option == selected
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(9.dp))
                    .background(if (isSelected) OceanSurfaceHigh else Color.Transparent)
                    .clickable(role = Role.Tab) { onSelected(option) }
                    .padding(vertical = 9.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = option,
                    color = if (isSelected) TextPrimary else TextSecondary,
                    fontSize = 12.sp,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                )
            }
        }
    }
}

@Composable
fun EmptyState(
    title: String,
    body: String,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 42.dp, horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(50.dp)
                .background(OceanSurfaceHigh, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text("∿", color = SignalBlue, fontSize = 28.sp)
        }
        Spacer(Modifier.height(14.dp))
        Text(title, color = TextPrimary, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
        Spacer(Modifier.height(6.dp))
        Text(body, color = TextSecondary, fontSize = 12.sp, lineHeight = 18.sp)
    }
}

@Composable
fun ExpandableSource(
    source: String,
    modifier: Modifier = Modifier,
) {
    var expanded by remember { mutableStateOf(false) }
    Row(
        modifier = modifier
            .fillMaxWidth()
            .animateContentSize()
            .clip(RoundedCornerShape(8.dp))
            .clickable { expanded = !expanded }
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(5.dp).background(SignalBlue, CircleShape))
        Spacer(Modifier.size(7.dp))
        Text(
            text = if (expanded) "$source · Tap to collapse source details" else source,
            color = TextSecondary,
            fontSize = 10.sp,
            lineHeight = 15.sp,
            maxLines = if (expanded) 3 else 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        Text(if (expanded) "⌃" else "⌄", color = TextSecondary, fontSize = 12.sp)
    }
}

@Composable
fun NavGlyph(screen: AppScreen, selected: Boolean, glyphSize: Dp = 22.dp) {
    val color = if (selected) SignalBlue else TextSecondary
    Canvas(
        modifier = Modifier
            .size(glyphSize)
            .semantics { contentDescription = screen.label },
    ) {
        val stroke = Stroke(width = 1.8.dp.toPx(), cap = StrokeCap.Round)
        when (screen) {
            AppScreen.Pulse -> {
                drawLine(color, Offset(0f, size.height * 0.72f), Offset(size.width * 0.24f, size.height * 0.48f), stroke.width, StrokeCap.Round)
                drawLine(color, Offset(size.width * 0.24f, size.height * 0.48f), Offset(size.width * 0.48f, size.height * 0.62f), stroke.width, StrokeCap.Round)
                drawLine(color, Offset(size.width * 0.48f, size.height * 0.62f), Offset(size.width * 0.72f, size.height * 0.24f), stroke.width, StrokeCap.Round)
                drawLine(color, Offset(size.width * 0.72f, size.height * 0.24f), Offset(size.width, size.height * 0.36f), stroke.width, StrokeCap.Round)
            }
            AppScreen.Markets -> {
                drawRect(color, topLeft = Offset(size.width * 0.12f, size.height * 0.18f), size = Size(size.width * 0.76f, size.height * 0.66f), style = stroke)
                drawLine(color, Offset(size.width * 0.28f, size.height * 0.68f), Offset(size.width * 0.28f, size.height * 0.45f), stroke.width)
                drawLine(color, Offset(size.width * 0.50f, size.height * 0.68f), Offset(size.width * 0.50f, size.height * 0.34f), stroke.width)
                drawLine(color, Offset(size.width * 0.72f, size.height * 0.68f), Offset(size.width * 0.72f, size.height * 0.52f), stroke.width)
            }
            AppScreen.Radar -> {
                drawCircle(color, radius = size.minDimension * 0.39f, style = stroke)
                drawCircle(color, radius = size.minDimension * 0.21f, style = stroke)
                drawLine(color, center, Offset(size.width * 0.78f, size.height * 0.26f), stroke.width, StrokeCap.Round)
                drawCircle(AquaMint, radius = 2.6.dp.toPx(), center = Offset(size.width * 0.68f, size.height * 0.34f))
            }
            AppScreen.Network -> {
                val nodes = listOf(
                    Offset(size.width * 0.22f, size.height * 0.28f),
                    Offset(size.width * 0.76f, size.height * 0.24f),
                    Offset(size.width * 0.55f, size.height * 0.76f),
                )
                drawLine(color, nodes[0], nodes[1], stroke.width)
                drawLine(color, nodes[1], nodes[2], stroke.width)
                drawLine(color, nodes[2], nodes[0], stroke.width)
                nodes.forEach { drawCircle(DeepOcean, 4.dp.toPx(), it); drawCircle(color, 4.dp.toPx(), it, style = stroke) }
            }
        }
    }
}
