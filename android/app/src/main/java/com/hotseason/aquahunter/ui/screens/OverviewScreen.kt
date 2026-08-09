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
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hotseason.aquahunter.data.AuthorizedMarketLoadState
import com.hotseason.aquahunter.data.AuthorizedMarketSeries
import com.hotseason.aquahunter.data.StatisticsNorwayMarketRepository
import com.hotseason.aquahunter.ui.components.ChangePill
import com.hotseason.aquahunter.ui.components.DataCard
import com.hotseason.aquahunter.ui.components.LicensedMapMarker
import com.hotseason.aquahunter.ui.components.LicensedWorldMap
import com.hotseason.aquahunter.ui.components.SectionHeader
import com.hotseason.aquahunter.ui.components.Sparkline
import com.hotseason.aquahunter.ui.components.Tag
import com.hotseason.aquahunter.ui.theme.AquaMint
import com.hotseason.aquahunter.ui.theme.SignalBlue
import com.hotseason.aquahunter.ui.theme.SunGold
import com.hotseason.aquahunter.ui.theme.TextPrimary
import com.hotseason.aquahunter.ui.theme.TextSecondary

@Composable
fun OverviewScreen(
    onOpenMarkets: () -> Unit,
    onOpenRadar: () -> Unit,
    onOpenNetwork: () -> Unit,
) {
    var marketState by remember {
        mutableStateOf<AuthorizedMarketLoadState>(AuthorizedMarketLoadState.Loading)
    }

    LaunchedEffect(Unit) {
        marketState = try {
            AuthorizedMarketLoadState.Loaded(
                StatisticsNorwayMarketRepository.fetchSalmonSeries(),
            )
        } catch (_: Exception) {
            AuthorizedMarketLoadState.Unavailable(
                "The authorized official feed could not be reached. No substitute value is shown.",
            )
        }
    }

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(
            start = 16.dp,
            top = 18.dp,
            end = 16.dp,
            bottom = 28.dp,
        ),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            SectionHeader(
                eyebrow = "Licensed ocean intelligence",
                title = "Global seafood pulse",
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "Only observations from approved, commercially reusable sources are displayed.",
                color = TextSecondary,
                fontSize = 12.sp,
                lineHeight = 18.sp,
            )
        }

        item {
            when (val current = marketState) {
                AuthorizedMarketLoadState.Loading -> LoadingMarketCard()
                is AuthorizedMarketLoadState.Loaded -> {
                    val series = current.series.firstOrNull()
                    if (series == null) {
                        UnavailableCard(
                            title = "Market data unavailable",
                            body = "No authorized market series is available.",
                            action = "Open markets",
                            onClick = onOpenMarkets,
                        )
                    } else {
                        LiveMarketCard(series = series, onClick = onOpenMarkets)
                    }
                }
                is AuthorizedMarketLoadState.Unavailable -> UnavailableCard(
                    title = "Market data unavailable",
                    body = current.message,
                    action = "Open markets",
                    onClick = onOpenMarkets,
                )
            }
        }

        item {
            SectionHeader(
                eyebrow = "Coverage",
                title = "Data availability",
            )
        }

        item {
            LicensedWorldMap(
                markers = listOf(
                    LicensedMapMarker(
                        id = "norway-market-benchmark",
                        title = "Norway",
                        subtitle = "Licensed national salmon export benchmark",
                        latitude = 61.0,
                        longitude = 8.0,
                    ),
                ),
                centerLatitude = 54.0,
                centerLongitude = 8.0,
                zoomLevel = 2.0,
            )
        }

        item {
            Text(
                "The base map works offline. The marker shows coverage of the licensed Norway national benchmark; it is not an Oslo spot price.",
                color = TextSecondary,
                fontSize = 10.sp,
                lineHeight = 15.sp,
            )
        }

        item {
            UnavailableCard(
                title = "Fish probability radar",
                body = "Unavailable until the environmental, historical-catch and model-input bundle is approved for commercial use.",
                action = "Open radar",
                onClick = onOpenRadar,
            )
        }

        item {
            UnavailableCard(
                title = "Buyer, trade, port and vessel network",
                body = "Unavailable until licensed records, attribution, timestamps and correction workflows are connected.",
                action = "Open network",
                onClick = onOpenNetwork,
            )
        }

        item {
            DataCard(Modifier.fillMaxWidth()) {
                Text(
                    "MAP POLICY",
                    color = SignalBlue,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 1.sp,
                )
                Spacer(Modifier.height(7.dp))
                Text(
                    "The production base map uses MapLibre Native with bundled Natural Earth public-domain geometry. It does not call Google Maps, Apple Maps or the public OpenStreetMap community tile service.",
                    color = TextSecondary,
                    fontSize = 10.sp,
                    lineHeight = 15.sp,
                )
            }
        }
    }
}

@Composable
private fun LoadingMarketCard() {
    DataCard(Modifier.fillMaxWidth(), emphasized = true) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            CircularProgressIndicator(
                modifier = Modifier.size(22.dp),
                color = SignalBlue,
                strokeWidth = 2.dp,
            )
            Spacer(Modifier.size(10.dp))
            Text(
                "Loading authorized official market data…",
                color = TextSecondary,
                fontSize = 12.sp,
            )
        }
    }
}

@Composable
private fun LiveMarketCard(
    series: AuthorizedMarketSeries,
    onClick: () -> Unit,
) {
    val latest = series.latest
    DataCard(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        emphasized = true,
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top,
        ) {
            Box(Modifier.size(8.dp).background(AquaMint, CircleShape))
            Spacer(Modifier.size(8.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    series.benchmark,
                    color = TextPrimary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    "${series.species} · ${series.commodityForm}",
                    color = TextSecondary,
                    fontSize = 10.sp,
                )
            }
            series.changePercent?.let { ChangePill(it) }
        }

        Spacer(Modifier.height(16.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Bottom,
        ) {
            Column {
                Text(
                    latest?.let { "%.2f".format(it.pricePerKg) } ?: "Unavailable",
                    color = TextPrimary,
                    fontSize = 27.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    "${series.currencyCode}/${series.unit} · ${latest?.periodCode.orEmpty()}",
                    color = TextSecondary,
                    fontSize = 10.sp,
                )
            }
            Sparkline(
                values = series.points.takeLast(12).map { it.pricePerKg.toFloat() },
                modifier = Modifier.size(width = 118.dp, height = 48.dp),
                color = AquaMint,
            )
        }

        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(7.dp)) {
            Tag(series.licenseName, accent = AquaMint)
            Tag(series.latency, accent = SunGold)
        }
        Spacer(Modifier.height(8.dp))
        Text(
            series.attribution,
            color = TextSecondary,
            fontSize = 9.sp,
        )
        Text(
            "National weekly export unit value; not a city spot price or executable quote.",
            color = SunGold,
            fontSize = 9.sp,
            lineHeight = 14.sp,
        )
    }
}

@Composable
private fun UnavailableCard(
    title: String,
    body: String,
    action: String,
    onClick: () -> Unit,
) {
    DataCard(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    title,
                    color = TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.height(5.dp))
                Text(
                    body,
                    color = TextSecondary,
                    fontSize = 10.sp,
                    lineHeight = 15.sp,
                )
            }
            Spacer(Modifier.size(12.dp))
            Text(
                action,
                color = SignalBlue,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}
