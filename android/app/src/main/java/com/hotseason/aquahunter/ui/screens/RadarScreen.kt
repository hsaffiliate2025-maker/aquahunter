package com.hotseason.aquahunter.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hotseason.aquahunter.ui.components.DataCard
import com.hotseason.aquahunter.ui.components.FilterPill
import com.hotseason.aquahunter.ui.components.LicensedWorldMap
import com.hotseason.aquahunter.ui.components.SectionHeader
import com.hotseason.aquahunter.ui.components.Tag
import com.hotseason.aquahunter.ui.theme.AquaMint
import com.hotseason.aquahunter.ui.theme.Divider
import com.hotseason.aquahunter.ui.theme.OceanSurfaceHigh
import com.hotseason.aquahunter.ui.theme.SignalBlue
import com.hotseason.aquahunter.ui.theme.SunGold
import com.hotseason.aquahunter.ui.theme.TextPrimary
import com.hotseason.aquahunter.ui.theme.TextSecondary

@Composable
fun RadarScreen() {
    val species = remember {
        listOf("Bluefin Tuna", "Pacific Cod", "Salmon", "Mackerel", "Shrimp")
    }
    var selectedSpecies by remember { mutableStateOf(species.first()) }

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
                eyebrow = "AI Fish Radar",
                title = "Probability, not detection.",
            )
            Spacer(Modifier.height(8.dp))
            Text(
                "A probability may be published only after every model input and historical-catch source passes commercial-use and provenance review.",
                color = TextSecondary,
                fontSize = 12.sp,
                lineHeight = 18.sp,
            )
        }

        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                species.forEach { item ->
                    FilterPill(
                        text = item,
                        selected = selectedSpecies == item,
                        onClick = { selectedSpecies = item },
                    )
                }
            }
        }

        item {
            LicensedWorldMap(
                markers = emptyList(),
                centerLatitude = 30.0,
                centerLongitude = 155.0,
                zoomLevel = 1.1,
            )
        }

        item {
            Text(
                "Offline base map available. No probability heat layer is drawn until the selected species has a complete approved input bundle.",
                color = TextSecondary,
                fontSize = 10.sp,
                lineHeight = 15.sp,
            )
        }

        item {
            DataCard(Modifier.fillMaxWidth(), emphasized = true) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(46.dp)
                            .background(SunGold.copy(alpha = 0.12f), CircleShape),
                        contentAlignment = Alignment.Center,
                    ) {
                        Text("—", color = SunGold, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.size(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(
                            "$selectedSpecies probability unavailable",
                            color = TextPrimary,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Spacer(Modifier.height(4.dp))
                        Text(
                            "No synthetic percentage or heatmap is generated.",
                            color = TextSecondary,
                            fontSize = 10.sp,
                        )
                    }
                    Tag("NO ESTIMATE", accent = SunGold)
                }
            }
        }

        item {
            SectionHeader(
                eyebrow = "Required evidence",
                title = "Inputs before activation",
            )
        }

        item {
            DataCard(Modifier.fillMaxWidth()) {
                listOf(
                    "Sea-surface temperature",
                    "Chlorophyll concentration",
                    "Ocean currents",
                    "Bathymetry and depth",
                    "Moon and seasonal variables",
                    "Species-specific historical catch",
                ).forEachIndexed { index, label ->
                    if (index > 0) {
                        Spacer(Modifier.height(10.dp))
                        Box(Modifier.fillMaxWidth().height(1.dp).background(Divider))
                        Spacer(Modifier.height(10.dp))
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(7.dp).background(SignalBlue, CircleShape))
                        Spacer(Modifier.size(9.dp))
                        Text(label, color = TextPrimary, fontSize = 12.sp, modifier = Modifier.weight(1f))
                        Text("PENDING", color = TextSecondary, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(OceanSurfaceHigh.copy(alpha = 0.60f), RoundedCornerShape(13.dp))
                    .padding(13.dp),
                verticalAlignment = Alignment.Top,
            ) {
                Text("!", color = SunGold, fontWeight = FontWeight.Bold)
                Spacer(Modifier.size(9.dp))
                Text(
                    "A future score will describe environmental suitability only. It will never guarantee fish presence, catchability, legal access or voyage safety.",
                    color = TextSecondary,
                    fontSize = 10.sp,
                    lineHeight = 15.sp,
                )
            }
        }
    }
}
