package com.hsaffiliate.aquahunter.ui.screens

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.hsaffiliate.aquahunter.ui.components.DataCard
import com.hsaffiliate.aquahunter.ui.components.LicensedMapMarker
import com.hsaffiliate.aquahunter.ui.components.LicensedWorldMap
import com.hsaffiliate.aquahunter.ui.components.SectionHeader
import com.hsaffiliate.aquahunter.ui.components.SegmentedControl
import com.hsaffiliate.aquahunter.ui.components.Tag
import com.hsaffiliate.aquahunter.ui.legal.MaritimeRiskNoticeContent
import com.hsaffiliate.aquahunter.ui.theme.AquaMint
import com.hsaffiliate.aquahunter.ui.theme.DeepOcean
import com.hsaffiliate.aquahunter.ui.theme.Divider
import com.hsaffiliate.aquahunter.ui.theme.OceanSurface
import com.hsaffiliate.aquahunter.ui.theme.OceanSurfaceHigh
import com.hsaffiliate.aquahunter.ui.theme.SignalBlue
import com.hsaffiliate.aquahunter.ui.theme.SunGold
import com.hsaffiliate.aquahunter.ui.theme.TextPrimary
import com.hsaffiliate.aquahunter.ui.theme.TextSecondary

@Composable
fun NetworkScreen() {
    var section by remember { mutableStateOf("Buyers") }
    var showsHelp by remember { mutableStateOf(false) }

    if (showsHelp) {
        NetworkHelpDialog(onDismiss = { showsHelp = false })
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(start = 16.dp, top = 18.dp, end = 16.dp, bottom = 28.dp),
        verticalArrangement = Arrangement.spacedBy(13.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top,
        ) {
            SectionHeader(
                eyebrow = "Commercial network",
                title = "Verified routes to market.",
                modifier = Modifier.weight(1f),
            )
            IconButton(onClick = { showsHelp = true }) {
                Icon(
                    Icons.AutoMirrored.Outlined.HelpOutline,
                    contentDescription = "Network feature help",
                    tint = SignalBlue,
                )
            }
        }

        Text(
            "Records appear only after the exact product, license, provenance and refresh policy has been approved.",
            color = TextSecondary,
            fontSize = 12.sp,
            lineHeight = 18.sp,
        )

        SegmentedControl(
            options = listOf("Buyers", "Trade", "Ports", "Vessels"),
            selected = section,
            onSelected = { section = it },
        )

        LicensedWorldMap(
            markers = if (section == "Ports") portReferenceMarkers else emptyList(),
            centerLatitude = 28.0,
            centerLongitude = 20.0,
            zoomLevel = 0.7,
        )

        Text(
            if (section == "Ports") {
                "Port markers are reference locations only. No landing, price or ship activity is implied."
            } else {
                "The offline base map remains available. No business, trade or vessel overlay is fabricated when licensed records are missing."
            },
            color = TextSecondary,
            fontSize = 10.sp,
            lineHeight = 15.sp,
        )

        NetworkUnavailableCard(section)

        DataCard(Modifier.fillMaxWidth()) {
            Text(
                "SOURCE REQUIREMENTS",
                color = SignalBlue,
                fontSize = 9.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp,
            )
            Spacer(Modifier.height(8.dp))
            SourceRequirement("Commercial reuse", "License text must explicitly permit the planned use.")
            SourceRequirement("Provenance", "Provider, dataset ID, source URL and transformations are retained.")
            SourceRequirement("Freshness", "Provider update time, retrieval time and expected latency are displayed.")
            SourceRequirement("No substitution", "An unavailable provider produces an unavailable state, never a fictional record.")
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(SunGold.copy(alpha = 0.08f), RoundedCornerShape(12.dp))
                .padding(13.dp),
            verticalAlignment = Alignment.Top,
        ) {
            Text("!", color = SunGold, fontWeight = FontWeight.Bold)
            Spacer(Modifier.size(9.dp))
            Text(
                "Vessel tracking does not mean a vessel can be rented or hired. Only a separately verified “Charter available” or “Fleet service available” label may indicate commercial availability.",
                color = TextSecondary,
                fontSize = 10.sp,
                lineHeight = 15.sp,
            )
        }
    }
}

private val portReferenceMarkers = listOf(
    LicensedMapMarker("seattle", "Seattle", "Reference port location", 47.61, -122.33),
    LicensedMapMarker("tokyo", "Tokyo", "Reference port location", 35.68, 139.76),
    LicensedMapMarker("busan", "Busan", "Reference port location", 35.18, 129.08),
    LicensedMapMarker("qingdao", "Qingdao", "Reference port location", 36.07, 120.38),
    LicensedMapMarker("rotterdam", "Rotterdam", "Reference port location", 51.92, 4.48),
)

@Composable
private fun NetworkUnavailableCard(section: String) {
    val content = when (section) {
        "Buyers" -> Triple(
            "Buyer database unavailable",
            "No approved commercial-use buyer contact and import-history dataset is connected.",
            "Company identity, business contacts, product scope, correction and removal workflows are required.",
        )
        "Trade" -> Triple(
            "Trade flows unavailable",
            "No approved customs trade-flow series is connected.",
            "A future flow will be an aggregate statistic, not a booking, shipment tracker or binding trade offer.",
        )
        "Ports" -> Triple(
            "Port landings unavailable",
            "No approved port-level landing and price feed is connected.",
            "A landing observation does not prove the harvest location, legality, freshness or current availability.",
        )
        else -> Triple(
            "Vessel signals unavailable",
            "No licensed AIS or vessel-position product is connected.",
            "A future vessel point may be delayed and tracking-only. It is not navigation data or a charter offer.",
        )
    }

    DataCard(Modifier.fillMaxWidth(), emphasized = true) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(
                    content.first,
                    color = TextPrimary,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.height(6.dp))
                Text(
                    content.second,
                    color = TextSecondary,
                    fontSize = 11.sp,
                    lineHeight = 17.sp,
                )
            }
            Tag("NO DATA", accent = SunGold)
        }
        Spacer(Modifier.height(11.dp))
        Box(Modifier.fillMaxWidth().height(1.dp).background(Divider))
        Spacer(Modifier.height(11.dp))
        Text(
            content.third,
            color = AquaMint,
            fontSize = 10.sp,
            lineHeight = 15.sp,
        )
    }
}

@Composable
private fun SourceRequirement(label: String, body: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Box(
            Modifier
                .padding(top = 5.dp)
                .size(6.dp)
                .background(AquaMint, RoundedCornerShape(3.dp)),
        )
        Spacer(Modifier.size(9.dp))
        Column {
            Text(label, color = TextPrimary, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
            Text(body, color = TextSecondary, fontSize = 9.sp, lineHeight = 14.sp)
        }
    }
}

@Composable
private fun NetworkHelpDialog(onDismiss: () -> Unit) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(DeepOcean)
                .padding(16.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text(
                        "NETWORK HELP",
                        color = SignalBlue,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp,
                    )
                    Text(
                        "What each feature means",
                        color = TextPrimary,
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Outlined.Close, contentDescription = "Close help", tint = TextPrimary)
                }
            }

            Spacer(Modifier.height(10.dp))
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                HelpSection(
                    "Buyers",
                    "Searchable business profiles and licensed trade evidence. A listing is not an endorsement, credit decision, confirmed demand or guaranteed contact.",
                )
                HelpSection(
                    "Trade",
                    "Aggregated product flows between countries or regions. A flow is not a live container, booking, customs clearance or contract.",
                )
                HelpSection(
                    "Ports",
                    "Reported landing observations and prices where a licensed source exists. A landing record is not proof of catch location or lawful harvest.",
                )
                HelpSection(
                    "Vessels",
                    "Tracking-only unless the record is expressly and separately verified as “Charter available” or “Fleet service available.” Tracking does not mean the vessel can be rented, crewed or hired.",
                )
                HelpSection(
                    "Charter and fleet services",
                    "AquaHunter is not the vessel owner, operator, employer, broker or insurer. Users must independently verify authority, seaworthiness, crew, class, flag, insurance, sanctions, permits and contract terms.",
                )
                MaritimeRiskNoticeContent()
                Spacer(Modifier.height(6.dp))
            }

            Spacer(Modifier.height(12.dp))
            Button(
                onClick = onDismiss,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = SignalBlue,
                    contentColor = DeepOcean,
                ),
                shape = RoundedCornerShape(12.dp),
            ) {
                Text("Close help", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun HelpSection(title: String, body: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(OceanSurfaceHigh, RoundedCornerShape(13.dp))
            .padding(14.dp),
    ) {
        Text(title, color = TextPrimary, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.height(5.dp))
        Text(body, color = TextSecondary, fontSize = 10.sp, lineHeight = 15.sp)
    }
}
