package com.hotseason.aquahunter.ui.legal

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
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hotseason.aquahunter.ui.components.BrandMark
import com.hotseason.aquahunter.ui.theme.AquaMint
import com.hotseason.aquahunter.ui.theme.DeepOcean
import com.hotseason.aquahunter.ui.theme.Divider
import com.hotseason.aquahunter.ui.theme.OceanSurface
import com.hotseason.aquahunter.ui.theme.OceanSurfaceHigh
import com.hotseason.aquahunter.ui.theme.SignalBlue
import com.hotseason.aquahunter.ui.theme.SunGold
import com.hotseason.aquahunter.ui.theme.TextPrimary
import com.hotseason.aquahunter.ui.theme.TextSecondary

const val MARITIME_RISK_NOTICE_VERSION = "2026-07-21"

data class MaritimeRiskSection(
    val title: String,
    val body: String,
)

val maritimeRiskSections = listOf(
    MaritimeRiskSection(
        "1. Public and licensed data sources",
        "Every statistic, price, environmental layer and base map displayed in AquaHunter comes from publicly released official sources or licensed suppliers whose published terms permit commercial use — for example Statistics Norway Statbank table 03024 (CC BY 4.0) and the public-domain Natural Earth base map. Each value is shown with its source and original publication cadence, and attributions required by data providers are displayed in the app. AquaHunter does not display data from sources whose commercial-reuse license has not been verified; the corresponding features remain hidden or marked unavailable instead of being filled with fictional values. Public statistics are aggregates released by their originators; they are not insider information, private feeds or real-time quotations.",
    ),
    MaritimeRiskSection(
        "2. Intelligence service—not navigation, detection or professional advice",
        "AquaHunter provides market, environmental, probability, port, trade, buyer and vessel intelligence. It is not a nautical chart, collision-avoidance system, fish finder, weather-routing service, distress service, coast-guard instruction, legal opinion, insurance advice or substitute for the professional judgment of a licensed master, skipper, operator, fleet manager or competent authority. Fish Probability and Ocean Intelligence scores are statistical estimates only. They do not mean fish are present, catchable, lawful to harvest or commercially viable. Never use AquaHunter as the sole basis for navigation, departure, route, fishing, safety or emergency decisions.",
    ),
    MaritimeRiskSection(
        "3. Weather, ocean and fish movement risk",
        "Marine conditions can change rapidly and without notice. Wind, waves, swell, fog, ice, storms, typhoons, hurricanes, lightning, visibility, tides, temperature fronts, chlorophyll, salinity, oxygen, depth, seabed conditions and ocean currents may differ from observations or forecasts. Satellite coverage, cloud cover, sensor failure, model error and transmission delay can create gaps or inaccuracies. Fish schools may move, disperse, dive, migrate or disappear before a vessel arrives because of currents, weather, predators, food availability, vessel activity, seasonality or other biological factors. AquaHunter does not guarantee a sighting, catch, catch volume, species, quality, price, revenue, fuel efficiency or return on a voyage.",
    ),
    MaritimeRiskSection(
        "4. Vessel charter, fleet service and hiring",
        "Unless a record is expressly marked “Charter available” or “Fleet service available” and separately verified, a vessel card is tracking-only information and is not an offer to sell, rent, charter, crew or hire a vessel. AquaHunter is not the owner, operator, employer, crewing agency, broker, carrier or insurer of third-party vessels and is not a party to agreements made between users and vessel or fleet providers. Users must independently verify identity, authority, beneficial ownership, flag, registration, class, seaworthiness, maintenance, equipment, crew competence, labor conditions, safety management, insurance, pollution cover, liens, sanctions exposure, permits and contract terms. Any deposit, charter party, employment, service agreement or voyage instruction is entered into at the parties’ own risk unless separate written AquaHunter marketplace terms state otherwise.",
    ),
    MaritimeRiskSection(
        "5. Master, operator and user responsibility",
        "The master and operator retain sole authority and responsibility for the vessel, crew, passengers, cargo, route and operational decisions. They must obtain current official charts, Notices to Mariners, meteorological and ocean warnings, port instructions, security advisories, navigational warnings and emergency communications; maintain a proper lookout; carry required safety and communications equipment; assess crew fatigue and competence; and comply with flag-state, coastal-state, port-state and international requirements. No AquaHunter prediction, alert, map, route, message or commercial request overrides the master’s professional judgment or duty to protect life, the vessel and the marine environment.",
    ),
    MaritimeRiskSection(
        "6. Piracy, armed robbery, conflict and security",
        "Sea voyages may expose vessels and people to piracy, armed robbery, kidnapping, theft, smuggling, sabotage, terrorism, civil unrest, war, mines, detention, embargoes, sanctions, communications disruption and port closure. Threat reports may be incomplete, delayed or unavailable. AquaHunter does not provide armed security, convoy protection, evacuation, rescue or real-time threat assurance. Owners, operators and masters must conduct their own voyage-specific security assessment, use current official and industry guidance, report through applicable maritime security channels, maintain required security plans and decide whether a voyage should proceed. The absence of an alert in AquaHunter does not mean an area is safe.",
    ),
    MaritimeRiskSection(
        "7. AIS and vessel-position limitations",
        "AIS and other vessel data may be delayed, incomplete, inaccurate, intentionally disabled, incorrectly entered, duplicated, spoofed, obstructed by coverage limits or restricted by a provider or law. A displayed point may be historical rather than current and may not represent ownership, activity, destination, fishing behavior or commercial availability. Do not use AquaHunter AIS displays for collision avoidance, search and rescue, law-enforcement action, border decisions or proof that a vessel committed or did not commit an act. Verify material facts with licensed providers, vessel operators and competent authorities.",
    ),
    MaritimeRiskSection(
        "8. Fishing law, borders, closed areas and IUU fishing",
        "Users are solely responsible for determining whether any voyage and fishing activity is lawful. Before operating, users must verify the current location and boundaries of territorial seas, exclusive economic zones, disputed waters, marine protected areas, no-take zones, seasonal closures, spawning closures, port restrictions and other controlled areas. Users must obtain and comply with all licenses, vessel authorizations, quotas, catch limits, species rules, size limits, gear restrictions, bycatch rules, protected-species requirements, observer or monitoring duties, transshipment rules, landing requirements, catch documentation, customs, labor, environmental and reporting obligations. AquaHunter does not authorize fishing in another country’s waters or any prohibited area. Do not fish, harvest or operate in waters that have not been opened or developed for fishing, or for which you do not hold every required permit, license or official approval. Illegal, unreported or unregulated fishing is forbidden. A map, probability cell, vessel track or missing boundary does not create a right to enter, fish, land or trade.",
    ),
    MaritimeRiskSection(
        "9. Market, buyer and transaction risk",
        "Market prices fluctuate continuously and can move sharply without warning; AquaHunter is not responsible for market price movements or for the outcome of any decision made in reliance on displayed prices. Prices, volumes, buyer profiles, import history, certificates, licenses and contact details may be normalized, estimated, delayed, incomplete or supplied by third parties. They are not binding quotations, credit decisions or guarantees of identity, solvency, capacity, legality, product quality, payment or delivery. Users must perform sanctions, anti-money-laundering, counterparty, food-safety, traceability, certificate, export-control, tax, customs and contract due diligence. AquaHunter is not responsible for losses caused by price movement, failed negotiations, non-payment, fraud, spoiled cargo, cold-chain failure, detention, rejection, recall, demurrage or other transaction events, except where liability cannot lawfully be excluded.",
    ),
    MaritimeRiskSection(
        "10. Emergencies and loss reporting",
        "AquaHunter is not monitored as an emergency channel. Do not send distress calls, medical emergencies, piracy alerts, pollution reports or rescue requests only through the app. Use the vessel’s approved distress and safety systems and immediately contact the relevant coast guard, maritime rescue coordination center, port, flag-state or local emergency service. Connectivity and app availability are not guaranteed offshore. Users should maintain independent communications, offline charts, contingency plans, emergency contacts and backups.",
    ),
    MaritimeRiskSection(
        "11. Assumption of risk and limitation of liability",
        "To the maximum extent permitted by applicable law, users assume the risks of relying on marine, fisheries, vessel and commercial information and remain responsible for their decisions, acts, omissions, compliance, contracts and operations. AquaHunter and its providers do not warrant uninterrupted access, completeness, accuracy, timeliness, fitness for a particular purpose, safety, legality, catch success or commercial outcome, and are not liable for indirect, incidental, special, exemplary, punitive or consequential loss, including loss of life or injury where exclusion is lawful, vessel or equipment damage, lost catch, lost profit, fuel cost, delay or reputational loss arising from use of or reliance on the service. Nothing in this notice excludes or limits liability that applicable law does not permit to be excluded or limited, including liability arising from fraud, willful misconduct, gross negligence or mandatory consumer and safety rights where applicable. Separate signed marketplace, charter or enterprise terms may impose additional obligations and will control if they expressly conflict with this general notice.",
    ),
)

@Composable
fun MaritimeRiskGate(onAccept: () -> Unit) {
    var confirmsReading by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DeepOcean),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(DeepOcean)
                .padding(horizontal = 18.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            BrandMark()
            Spacer(Modifier.size(10.dp))
            Column {
                Text("AquaHunter", color = TextPrimary, fontSize = 19.sp, fontWeight = FontWeight.Bold)
                Text("Required before first use", color = SunGold, fontSize = 10.sp, fontWeight = FontWeight.Bold)
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(Divider))

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
        ) {
            Text(
                "MARITIME OPERATIONS & LEGAL RISK NOTICE",
                color = SignalBlue,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp,
            )
            Spacer(Modifier.height(5.dp))
            Text("Required acknowledgement", color = TextPrimary, fontSize = 25.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(7.dp))
            Text(
                "Review this notice before entering any AquaHunter feature.",
                color = TextSecondary,
                fontSize = 12.sp,
                lineHeight = 18.sp,
            )
            Spacer(Modifier.height(14.dp))
            MaritimeRiskNoticeContent()
        }

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(OceanSurface)
                .padding(16.dp),
        ) {
            Row(verticalAlignment = Alignment.Top) {
                Checkbox(
                    checked = confirmsReading,
                    onCheckedChange = { confirmsReading = it },
                    colors = CheckboxDefaults.colors(checkedColor = SignalBlue),
                    modifier = Modifier.testTag("maritime-risk-confirmation"),
                )
                Spacer(Modifier.size(4.dp))
                Text(
                    "I have read and understand the notice, including public data sourcing, safety, fish-probability, vessel, piracy, lawful-fishing and market-price limitations.",
                    color = TextPrimary,
                    fontSize = 10.sp,
                    lineHeight = 15.sp,
                    modifier = Modifier.padding(top = 11.dp),
                )
            }
            Spacer(Modifier.height(10.dp))
            Button(
                onClick = onAccept,
                enabled = confirmsReading,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("maritime-risk-accept"),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = SignalBlue,
                    contentColor = DeepOcean,
                    disabledContainerColor = OceanSurfaceHigh,
                    disabledContentColor = TextSecondary,
                ),
            ) {
                Text("Accept and enter AquaHunter", fontWeight = FontWeight.Bold)
            }
            Text(
                "Acceptance is stored on this device for notice version $MARITIME_RISK_NOTICE_VERSION.",
                color = TextSecondary,
                fontSize = 8.sp,
                lineHeight = 12.sp,
                modifier = Modifier.padding(top = 7.dp),
            )
        }
    }
}

@Composable
fun MaritimeRiskNoticeContent(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(OceanSurfaceHigh.copy(alpha = 0.66f), RoundedCornerShape(14.dp))
            .padding(15.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Text("!", color = SunGold, fontSize = 18.sp, fontWeight = FontWeight.Black)
            Spacer(Modifier.size(9.dp))
            Column {
                Text("Version $MARITIME_RISK_NOTICE_VERSION", color = SunGold, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                Text(
                    "Review current official information and obtain qualified legal advice for each operating jurisdiction before live charter, hiring or fishing operations.",
                    color = TextPrimary,
                    fontSize = 10.sp,
                    lineHeight = 15.sp,
                )
            }
        }

        maritimeRiskSections.forEach { section ->
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(section.title, color = TextPrimary, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                Text(section.body, color = TextSecondary, fontSize = 9.sp, lineHeight = 14.sp)
            }
        }

        Text(
            "By continuing to use operational features, the user confirms that AquaHunter is a decision-support tool only and that the user will independently verify safety, legality and commercial suitability. Opening this notice is not a substitute for a signed marketplace, charter or enterprise agreement.",
            color = AquaMint,
            fontSize = 10.sp,
            lineHeight = 15.sp,
            fontWeight = FontWeight.SemiBold,
        )
    }
}
