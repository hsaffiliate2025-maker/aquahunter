package com.hotseason.aquahunter.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hotseason.aquahunter.data.AuthorizedMarketLoadState
import com.hotseason.aquahunter.data.AuthorizedMarketSeries
import com.hotseason.aquahunter.data.MarketDataPoint
import com.hotseason.aquahunter.data.StatisticsNorwayMarketRepository
import com.hotseason.aquahunter.ui.components.ChangePill
import com.hotseason.aquahunter.ui.components.DataCard
import com.hotseason.aquahunter.ui.components.EmptyState
import com.hotseason.aquahunter.ui.components.FilterPill
import com.hotseason.aquahunter.ui.components.SearchField
import com.hotseason.aquahunter.ui.components.SectionHeader
import com.hotseason.aquahunter.ui.components.Sparkline
import com.hotseason.aquahunter.ui.components.Tag
import com.hotseason.aquahunter.ui.theme.AquaMint
import com.hotseason.aquahunter.ui.theme.DeepOcean
import com.hotseason.aquahunter.ui.theme.OceanSurfaceHigh
import com.hotseason.aquahunter.ui.theme.SignalBlue
import com.hotseason.aquahunter.ui.theme.SunGold
import com.hotseason.aquahunter.ui.theme.TextPrimary
import com.hotseason.aquahunter.ui.theme.TextSecondary
import com.hotseason.aquahunter.ui.theme.WarmCoral

@Composable
fun MarketsScreen() {
    var query by remember { mutableStateOf("") }
    var selectedSeries by remember { mutableStateOf<AuthorizedMarketSeries?>(null) }
    var state by remember {
        mutableStateOf<AuthorizedMarketLoadState>(AuthorizedMarketLoadState.Loading)
    }
    var reloadKey by remember { mutableIntStateOf(0) }

    LaunchedEffect(reloadKey) {
        state = AuthorizedMarketLoadState.Loading
        state = try {
            AuthorizedMarketLoadState.Loaded(
                listOf(StatisticsNorwayMarketRepository.fetchFreshSalmonSeries()),
            )
        } catch (_: Exception) {
            AuthorizedMarketLoadState.Unavailable(
                "No authorized market data is available right now. " +
                    "AquaHunter does not insert fictional fallback values.",
            )
        }
    }

    selectedSeries?.let { series ->
        AuthorizedMarketDetailScreen(
            series = series,
            onBack = { selectedSeries = null },
        )
        return
    }

    val loaded = state as? AuthorizedMarketLoadState.Loaded
    val results = loaded?.series.orEmpty().filter { series ->
        query.isBlank() ||
            series.species.contains(query, ignoreCase = true) ||
            series.geography.contains(query, ignoreCase = true) ||
            series.benchmark.contains(query, ignoreCase = true)
    }

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(
            start = 16.dp,
            top = 18.dp,
            end = 16.dp,
            bottom = 28.dp,
        ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            SectionHeader(
                eyebrow = "Licensed official data",
                title = "Global markets",
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "Only authorized observations are shown. Cadence, source units and data semantics are preserved.",
                color = TextSecondary,
                fontSize = 12.sp,
                lineHeight = 18.sp,
            )
        }

        item {
            SearchField(
                value = query,
                onValueChange = { query = it },
                placeholder = "Search species, country or benchmark",
            )
        }

        when (val current = state) {
            AuthorizedMarketLoadState.Loading -> item {
                DataCard(Modifier.fillMaxWidth()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(22.dp),
                            color = SignalBlue,
                            strokeWidth = 2.dp,
                        )
                        Spacer(Modifier.size(10.dp))
                        Text(
                            "Loading authorized market data…",
                            color = TextSecondary,
                            fontSize = 12.sp,
                        )
                    }
                }
            }

            is AuthorizedMarketLoadState.Unavailable -> item {
                DataCard(Modifier.fillMaxWidth()) {
                    Text(
                        "Market data unavailable",
                        color = TextPrimary,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Spacer(Modifier.height(6.dp))
                    Text(
                        current.message,
                        color = TextSecondary,
                        fontSize = 11.sp,
                        lineHeight = 16.sp,
                    )
                    TextButton(onClick = { reloadKey += 1 }) {
                        Text("Retry", color = SignalBlue, fontWeight = FontWeight.Bold)
                    }
                }
            }

            is AuthorizedMarketLoadState.Loaded -> {
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                OceanSurfaceHigh.copy(alpha = 0.48f),
                                RoundedCornerShape(12.dp),
                            )
                            .padding(horizontal = 12.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(Modifier.size(7.dp).background(AquaMint, CircleShape))
                        Spacer(Modifier.size(8.dp))
                        Text(
                            "${results.size} authorized benchmark",
                            color = TextPrimary,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Medium,
                            modifier = Modifier.weight(1f),
                        )
                        Text(
                            "SOURCE UNITS",
                            color = AquaMint,
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }

                if (results.isEmpty()) {
                    item {
                        EmptyState(
                            title = "No authorized matching data",
                            body = "No fictional value is substituted for unavailable species or cities.",
                        )
                    }
                } else {
                    items(
                        count = results.size,
                        key = { index -> results[index].id },
                    ) { index ->
                        AuthorizedMarketCard(
                            series = results[index],
                            onClick = { selectedSeries = results[index] },
                        )
                    }
                }
            }
        }

        item { DataInterpretationNote() }
    }
}

@Composable
private fun AuthorizedMarketCard(
    series: AuthorizedMarketSeries,
    onClick: () -> Unit,
) {
    val latest = series.latest
    val change = series.changePercent
    val positive = (change ?: 0.0) >= 0

    DataCard(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top,
        ) {
            CountryBadge(series.countryCode)
            Spacer(Modifier.size(11.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    "${series.geography} · ${series.countryCode}",
                    color = TextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.height(3.dp))
                Text(
                    "${series.benchmark} · ${series.species}",
                    color = TextSecondary,
                    fontSize = 10.sp,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            change?.let { ChangePill(it) }
        }
        Spacer(Modifier.height(14.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Bottom,
        ) {
            Column {
                Text(
                    latest?.let { "%.2f".format(it.pricePerKg) } ?: "—",
                    color = TextPrimary,
                    fontSize = 25.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    "${series.currencyCode} / ${series.unit} · ${latest?.periodCode ?: "Unavailable"}",
                    color = TextSecondary,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
            Sparkline(
                values = series.points.takeLast(12).map { it.pricePerKg.toFloat() },
                modifier = Modifier
                    .weight(1f)
                    .height(45.dp)
                    .padding(start = 18.dp),
                color = if (positive) AquaMint else WarmCoral,
            )
        }
        Spacer(Modifier.height(12.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(7.dp),
        ) {
            latest?.volumeTonnes?.let { Tag("${"%.0f".format(it)} T", accent = SunGold) }
            Tag("WEEKLY", accent = SignalBlue)
            Tag(series.licenseName, accent = AquaMint)
        }
        Spacer(Modifier.height(11.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                series.attribution,
                color = AquaMint,
                fontSize = 9.sp,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f),
            )
            Text(
                "View official history ›",
                color = SignalBlue,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

@Composable
private fun AuthorizedMarketDetailScreen(
    series: AuthorizedMarketSeries,
    onBack: () -> Unit,
) {
    var period by remember(series.id) { mutableStateOf("30W") }
    val pointCount = when (period) {
        "6W" -> 6
        "1Y" -> 52
        else -> 30
    }
    val points = series.points.takeLast(pointCount)
    val latest = series.latest
    val uriHandler = LocalUriHandler.current

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(
            start = 16.dp,
            top = 12.dp,
            end = 16.dp,
            bottom = 28.dp,
        ),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Text(
                "‹  Back to markets",
                color = SignalBlue,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .clickable(onClick = onBack)
                    .padding(vertical = 8.dp),
            )
            SectionHeader(
                eyebrow = series.species.uppercase(),
                title = series.geography,
            )
            Spacer(Modifier.height(5.dp))
            Text(
                "${series.benchmark} · ${series.latency}",
                color = TextSecondary,
                fontSize = 11.sp,
            )
        }

        item {
            DataCard(Modifier.fillMaxWidth(), emphasized = true) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Bottom) {
                    Column {
                        Text(
                            latest?.let { "%.2f".format(it.pricePerKg) } ?: "—",
                            color = TextPrimary,
                            fontSize = 31.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Text(
                            "${series.currencyCode} / ${series.unit} · ${latest?.periodCode ?: "Unavailable"}",
                            color = TextSecondary,
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                    Spacer(Modifier.weight(1f))
                    series.changePercent?.let { ChangePill(it) }
                }
            }
        }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf("6W", "30W", "1Y").forEach { item ->
                    FilterPill(
                        text = item,
                        selected = period == item,
                        onClick = { period = item },
                    )
                }
            }
        }

        item {
            DataCard(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        "OFFICIAL WEEKLY SERIES",
                        color = SignalBlue,
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp,
                    )
                    Spacer(Modifier.weight(1f))
                    Text(
                        "NO SYNTHETIC OHLC",
                        color = SunGold,
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
                Spacer(Modifier.height(12.dp))
                Sparkline(
                    values = points.map { it.pricePerKg.toFloat() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(230.dp)
                        .background(DeepOcean, RoundedCornerShape(12.dp))
                        .padding(14.dp),
                    color = if ((series.changePercent ?: 0.0) >= 0) AquaMint else WarmCoral,
                )
                Spacer(Modifier.height(8.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("${points.size} published weekly points", color = TextSecondary, fontSize = 9.sp)
                    Text("${series.currencyCode} / ${series.unit}", color = TextSecondary, fontSize = 9.sp)
                }
            }
        }

        latest?.let { observation ->
            item {
                LatestObservationCard(observation)
            }
        }

        item {
            DataCard(Modifier.fillMaxWidth()) {
                Text(
                    "SOURCE & LICENSE",
                    color = SignalBlue,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp,
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    series.attribution,
                    color = TextPrimary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    "Provider updated: ${series.providerUpdatedAt ?: "Not supplied"}",
                    color = TextSecondary,
                    fontSize = 10.sp,
                )
                Text(
                    "Retrieved: ${series.retrievedAt}",
                    color = TextSecondary,
                    fontSize = 10.sp,
                )
                Text(
                    "${series.commodityForm} · ${series.scientificName}",
                    color = TextSecondary,
                    fontSize = 10.sp,
                    fontStyle = FontStyle.Italic,
                )
                Spacer(Modifier.height(7.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = { uriHandler.openUri(series.sourceUrl) }) {
                        Text("Open source table", color = SignalBlue)
                    }
                    TextButton(onClick = { uriHandler.openUri(series.licenseUrl) }) {
                        Text(series.licenseName, color = SignalBlue)
                    }
                }
                Text(
                    "National export unit value; not a city spot price, auction quote or executable offer.",
                    color = SunGold,
                    fontSize = 10.sp,
                    lineHeight = 15.sp,
                )
            }
        }

        item { DataInterpretationNote() }
    }
}

@Composable
private fun LatestObservationCard(point: MarketDataPoint) {
    DataCard(Modifier.fillMaxWidth()) {
        Text(
            "LATEST PUBLISHED OBSERVATION",
            color = SignalBlue,
            fontSize = 9.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.sp,
        )
        Spacer(Modifier.height(10.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Column {
                Text("PERIOD", color = TextSecondary, fontSize = 8.sp, fontWeight = FontWeight.Bold)
                Text(point.periodCode, color = TextPrimary, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    "EXPORT WEIGHT",
                    color = TextSecondary,
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    point.volumeTonnes?.let { "${"%.0f".format(it)} t" } ?: "Not supplied",
                    color = TextPrimary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}

@Composable
private fun CountryBadge(code: String) {
    Box(
        modifier = Modifier
            .size(38.dp)
            .background(SignalBlue.copy(alpha = 0.12f), RoundedCornerShape(10.dp)),
        contentAlignment = Alignment.Center,
    ) {
        Text(code, color = SignalBlue, fontSize = 11.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun DataInterpretationNote() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(DeepOcean, RoundedCornerShape(12.dp))
            .padding(12.dp),
    ) {
        Text(
            "DATA INTERPRETATION",
            color = SunGold,
            fontSize = 9.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.sp,
        )
        Spacer(Modifier.height(5.dp))
        Text(
            "Statistics Norway table 03024 is a weekly national export statistic. " +
                "It is not an Oslo spot price, auction result or executable quote. " +
                "OHLC candles are not shown because this source does not publish open, high, low and close values.",
            color = TextSecondary,
            fontSize = 10.sp,
            lineHeight = 15.sp,
        )
    }
}

