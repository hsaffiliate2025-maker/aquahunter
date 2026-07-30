package com.hotseason.aquahunter.ui.screens

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.AddCircle
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.FileDownload
import androidx.compose.material.icons.outlined.ShoppingCart
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.hotseason.aquahunter.commerce.AndroidCommerceStore
import com.hotseason.aquahunter.commerce.CommerceAnalytics
import com.hotseason.aquahunter.commerce.CommerceAnalyticsException
import com.hotseason.aquahunter.commerce.CommerceDestination
import com.hotseason.aquahunter.commerce.CommerceLocaleText
import com.hotseason.aquahunter.commerce.CommerceProductDefinition
import com.hotseason.aquahunter.commerce.LandedCostInput
import com.hotseason.aquahunter.commerce.PriceAlertRule
import com.hotseason.aquahunter.data.AuthorizedMarketLoadState
import com.hotseason.aquahunter.data.AuthorizedMarketSeries
import com.hotseason.aquahunter.data.StatisticsNorwayMarketRepository
import com.hotseason.aquahunter.ui.components.DataCard
import com.hotseason.aquahunter.ui.components.SectionHeader
import com.hotseason.aquahunter.ui.components.Sparkline
import com.hotseason.aquahunter.ui.theme.AquaMint
import com.hotseason.aquahunter.ui.theme.DeepOcean
import com.hotseason.aquahunter.ui.theme.SignalBlue
import com.hotseason.aquahunter.ui.theme.SunGold
import com.hotseason.aquahunter.ui.theme.TextPrimary
import com.hotseason.aquahunter.ui.theme.TextSecondary
import java.util.Locale
import java.util.UUID

@Composable
fun CommerceToolkitScreen(
    store: AndroidCommerceStore,
    language: AquaAppLanguage,
    destination: CommerceDestination,
    onDestinationChange: (CommerceDestination) -> Unit,
) {
    val context = LocalContext.current
    val ledgerRevision by store.ledgerRevision.collectAsState()
    var showsStore by remember { mutableStateOf(false) }
    var state by remember {
        mutableStateOf<AuthorizedMarketLoadState>(
            AuthorizedMarketLoadState.Loading,
        )
    }
    var resultTitle by remember { mutableStateOf<String?>(null) }
    var resultBody by remember { mutableStateOf<String?>(null) }
    var pendingCsv by remember { mutableStateOf<ByteArray?>(null) }
    var exchangeRate by remember { mutableStateOf("0.095") }
    var freightPerKg by remember { mutableStateOf("1.20") }
    var tariffPercent by remember { mutableStateOf("0") }
    var lossPercent by remember { mutableStateOf("2") }
    var alertThreshold by remember { mutableStateOf("70") }
    var alertDirection by remember { mutableStateOf(PriceAlertRule.Direction.Above) }
    val locale = store.catalog.locale(language.code)
    val balance = remember(destination, ledgerRevision) {
        store.available(destination)
    }

    val exportLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("text/csv"),
    ) { uri ->
        val bytes = pendingCsv
        pendingCsv = null
        if (uri == null || bytes == null) {
            resultTitle = locale.toolText(
                "result.exportFailed",
                "Export not delivered",
            )
            resultBody = locale.noCharge
            return@rememberLauncherForActivityResult
        }
        runCatching {
            context.contentResolver.openOutputStream(uri)?.use {
                it.write(bytes)
            } ?: error("The selected document could not be opened.")
        }.onSuccess {
            if (store.consumeSuccessfulResult(CommerceDestination.Export)) {
                resultTitle = locale.toolText(
                    "result.exportDelivered",
                    "CSV delivered",
                )
                resultBody = locale.toolText(
                    "body.export",
                    "{file}\nStatistics Norway · 03024 · CC BY 4.0",
                    mapOf("file" to uri.lastPathSegment.orEmpty()),
                )
            }
        }.onFailure {
            resultTitle = locale.toolText(
                "result.exportFailed",
                "Export not delivered",
            )
            resultBody = locale.noCharge
        }
    }

    LaunchedEffect(Unit) {
        state = try {
            AuthorizedMarketLoadState.Loaded(
                StatisticsNorwayMarketRepository.fetchSalmonSeries(520),
            )
        } catch (_: Exception) {
            AuthorizedMarketLoadState.Unavailable(
                locale.toolText(
                    "noData",
                    "No authorized market data is available right now.",
                ),
            )
        }
    }

    if (showsStore) {
        CommerceStorefrontScreen(
            store = store,
            language = language,
            onBack = { showsStore = false },
        )
        return
    }

    androidx.compose.foundation.lazy.LazyColumn(
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
                eyebrow = locale.toolText(
                    "eyebrow",
                    "Licensed market intelligence",
                ),
                title = locale.toolText("title", "Research toolkit"),
                action = locale.store.storeButton,
                onAction = { showsStore = true },
            )
            Spacer(Modifier.height(7.dp))
            Text(
                locale.toolText(
                    "subtitle",
                    "Every delivered result cites its official source. Failed or empty results never use a credit.",
                ),
                color = TextSecondary,
                fontSize = 11.sp,
                lineHeight = 17.sp,
            )
        }

        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(7.dp),
            ) {
                CommerceDestination.entries.forEach { item ->
                    FilterChip(
                        selected = destination == item,
                        onClick = {
                            onDestinationChange(item)
                            resultTitle = null
                            resultBody = null
                        },
                        label = {
                            Text(
                                locale.destinations[item] ?: item.wireValue,
                                fontSize = 10.sp,
                            )
                        },
                    )
                }
            }
        }

        if (destination == CommerceDestination.History) {
            item {
                HistoryToolCard(
                    store = store,
                    state = state,
                    locale = locale,
                    onOpenStore = { showsStore = true },
                )
            }
        } else {
            item {
                DataCard(Modifier.fillMaxWidth(), emphasized = true) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(Modifier.weight(1f)) {
                            Text(
                                locale.destinations[destination]
                                    ?: destination.wireValue,
                                color = TextPrimary,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.SemiBold,
                            )
                            Text(
                                locale.replace(
                                    locale.balance,
                                    mapOf("count" to balance.toString()),
                                ),
                                color = SignalBlue,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                            )
                        }
                        IconButton(onClick = { showsStore = true }) {
                            Icon(
                                Icons.Outlined.AddCircle,
                                contentDescription = locale.toolText(
                                    "addCredits",
                                    "Add credits",
                                ),
                                tint = SignalBlue,
                            )
                        }
                    }

                    if (destination == CommerceDestination.LandedCost) {
                        CommerceNumberField(
                            locale.toolText(
                                "exchangeRate",
                                "Target currency per NOK",
                            ),
                            exchangeRate,
                        ) { exchangeRate = it }
                        CommerceNumberField(
                            locale.toolText("freight", "Freight per kg"),
                            freightPerKg,
                        ) {
                            freightPerKg = it
                        }
                        CommerceNumberField(
                            locale.toolText("tariff", "Tariff %"),
                            tariffPercent,
                        ) {
                            tariffPercent = it
                        }
                        CommerceNumberField(
                            locale.toolText("loss", "Loss %"),
                            lossPercent,
                        ) {
                            lossPercent = it
                        }
                        Text(
                            locale.toolText(
                                "assumptionNotice",
                                "Exchange rate and costs are your assumptions; AquaHunter does not guarantee them.",
                            ),
                            color = SunGold,
                            fontSize = 9.sp,
                            lineHeight = 13.sp,
                        )
                    }

                    if (destination == CommerceDestination.Alerts) {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            FilterChip(
                                selected =
                                    alertDirection == PriceAlertRule.Direction.Above,
                                onClick = {
                                    alertDirection =
                                        PriceAlertRule.Direction.Above
                                },
                                label = {
                                    Text(
                                        locale.toolText(
                                            "above",
                                            "At or above",
                                        ),
                                    )
                                },
                            )
                            FilterChip(
                                selected =
                                    alertDirection == PriceAlertRule.Direction.Below,
                                onClick = {
                                    alertDirection =
                                        PriceAlertRule.Direction.Below
                                },
                                label = {
                                    Text(
                                        locale.toolText(
                                            "below",
                                            "At or below",
                                        ),
                                    )
                                },
                            )
                        }
                        CommerceNumberField(
                            locale.toolText(
                                "threshold",
                                "Threshold in NOK/kg",
                            ),
                            alertThreshold,
                        ) { alertThreshold = it }
                        Text(
                            locale.toolText(
                                "alertNotice",
                                "One credit is used only after a matching official period is delivered in this app.",
                            ),
                            color = TextSecondary,
                            fontSize = 9.sp,
                            lineHeight = 13.sp,
                        )
                    }

                    Button(
                        enabled = balance > 0,
                        onClick = {
                            val series = (
                                state as? AuthorizedMarketLoadState.Loaded
                                )?.series
                            if (series.isNullOrEmpty()) {
                                resultTitle = locale.toolText(
                                    "noResult",
                                    "No result",
                                )
                                resultBody = locale.noCharge
                                return@Button
                            }
                            runCatching {
                                when (destination) {
                                    CommerceDestination.Export -> {
                                        pendingCsv = CommerceAnalytics.csv(
                                            series.first(),
                                        )
                                        exportLauncher.launch(
                                            "AquaHunter-${series.first().id}.csv",
                                        )
                                        return@Button
                                    }
                                    CommerceDestination.Compare -> {
                                        val output = CommerceAnalytics.compare(
                                            series[0],
                                            series[1],
                                        )
                                        resultTitle = locale.toolText(
                                            "result.compare",
                                            "Official market comparison",
                                        )
                                        resultBody = locale.toolText(
                                            "body.compare",
                                            "Period {period}\n{first}: {firstPrice}\n{second}: {secondPrice}\nSpread: {spread} {currency}/{unit} ({spreadPercent})\nStatistics Norway · 03024 · CC BY 4.0",
                                            mapOf(
                                                "period" to output.periodCode,
                                                "first" to locale.commodityName(
                                                    output.firstCommodityCode,
                                                ),
                                                "firstPrice" to "%.2f".format(
                                                    Locale.US,
                                                    output.firstPricePerKg,
                                                ),
                                                "second" to locale.commodityName(
                                                    output.secondCommodityCode,
                                                ),
                                                "secondPrice" to "%.2f".format(
                                                    Locale.US,
                                                    output.secondPricePerKg,
                                                ),
                                                "spread" to "%+.2f".format(
                                                    Locale.US,
                                                    output.absoluteSpreadPerKg,
                                                ),
                                                "currency" to
                                                    output.currencyCode,
                                                "unit" to output.unit,
                                                "spreadPercent" to
                                                    "%+.1f%%".format(
                                                        Locale.US,
                                                        output.spreadPercentOfSecond,
                                                    ),
                                            ),
                                        )
                                    }
                                    CommerceDestination.Snapshot -> {
                                        val output = CommerceAnalytics.snapshot(
                                            series.first(),
                                        )
                                        resultTitle = locale.toolText(
                                            "result.snapshot",
                                            "Sourced market snapshot",
                                        )
                                        resultBody = locale.toolText(
                                            "body.snapshot",
                                            "{period}: {price} NOK/kg\nChange: {change}\n12-week average: {average}\nRange: {low}–{high}\nStatistics Norway · 03024 · {commodity} · CC BY 4.0",
                                            mapOf(
                                                "period" to output.periodCode,
                                                "price" to "%.2f".format(
                                                    Locale.US,
                                                    output.pricePerKg,
                                                ),
                                                "change" to (
                                                    output.changePercent?.let {
                                                        "%+.1f%%".format(
                                                            Locale.US,
                                                            it,
                                                        )
                                                    } ?: locale.toolText(
                                                        "unavailable",
                                                        "Unavailable",
                                                    )
                                                    ),
                                                "average" to "%.2f".format(
                                                    Locale.US,
                                                    output.average12Week,
                                                ),
                                                "low" to "%.2f".format(
                                                    Locale.US,
                                                    output.low12Week,
                                                ),
                                                "high" to "%.2f".format(
                                                    Locale.US,
                                                    output.high12Week,
                                                ),
                                                "commodity" to
                                                    locale.commodityName(
                                                        output.commodityCode,
                                                    ),
                                            ),
                                        )
                                    }
                                    CommerceDestination.Seasonality -> {
                                        val output =
                                            CommerceAnalytics.seasonality(
                                                series.first(),
                                            )
                                        resultTitle = locale.toolText(
                                            "result.seasonality",
                                            "Seasonality report",
                                        )
                                        resultBody = locale.toolText(
                                            "body.seasonality",
                                            "Week {week} · {years} historical years\nHistorical average: {average} NOK/kg\nLatest: {latest} NOK/kg\nDifference: {difference}\nStatistics Norway · 03024 · CC BY 4.0",
                                            mapOf(
                                                "week" to
                                                    output.weekOfYear.toString(),
                                                "years" to
                                                    output.sampleYears.toString(),
                                                "average" to "%.2f".format(
                                                    Locale.US,
                                                    output.historicalAverage,
                                                ),
                                                "latest" to "%.2f".format(
                                                    Locale.US,
                                                    output.latestPrice,
                                                ),
                                                "difference" to
                                                    "%+.1f%%".format(
                                                        Locale.US,
                                                        output.differencePercent,
                                                    ),
                                            ),
                                        )
                                    }
                                    CommerceDestination.LandedCost -> {
                                        val first = series.first()
                                        val latest = requireNotNull(first.latest)
                                        val output = CommerceAnalytics.landedCost(
                                            LandedCostInput(
                                                sourcePricePerKg =
                                                    latest.pricePerKg,
                                                sourceCurrencyCode =
                                                    first.currencyCode,
                                                targetCurrencyCode = "USD",
                                                targetCurrencyPerSourceCurrency =
                                                    numeric(exchangeRate),
                                                freightPerKgTargetCurrency =
                                                    numeric(freightPerKg),
                                                tariffPercent =
                                                    numeric(tariffPercent),
                                                lossPercent =
                                                    numeric(lossPercent),
                                            ),
                                        )
                                        resultTitle = locale.toolText(
                                            "result.landedCost",
                                            "Landed-cost calculation",
                                        )
                                        resultBody = locale.toolText(
                                            "body.landedCost",
                                            "Source {period}: {sourcePrice} NOK/kg\nConverted source: {converted} USD/kg\nBefore loss: {subtotal} USD/kg\nLanded cost: {landed} USD/saleable kg\nUser assumptions: FX {fx} · freight {freight} · tariff {tariff}% · loss {loss}%",
                                            mapOf(
                                                "period" to latest.periodCode,
                                                "sourcePrice" to "%.2f".format(
                                                    Locale.US,
                                                    latest.pricePerKg,
                                                ),
                                                "converted" to "%.2f".format(
                                                    Locale.US,
                                                    output.convertedSourcePricePerKg,
                                                ),
                                                "subtotal" to "%.2f".format(
                                                    Locale.US,
                                                    output.subtotalBeforeLoss,
                                                ),
                                                "landed" to "%.2f".format(
                                                    Locale.US,
                                                    output.landedCostPerSaleableKg,
                                                ),
                                                "fx" to exchangeRate,
                                                "freight" to freightPerKg,
                                                "tariff" to tariffPercent,
                                                "loss" to lossPercent,
                                            ),
                                        )
                                    }
                                    CommerceDestination.Alerts -> {
                                        val first = series.first()
                                        val rule = PriceAlertRule(
                                            id = UUID.randomUUID().toString(),
                                            seriesId = first.id,
                                            threshold = numeric(alertThreshold),
                                            direction = alertDirection,
                                            currencyCode = first.currencyCode,
                                            unit = first.unit,
                                            lastDeliveredPeriodCode = null,
                                        )
                                        if (!rule.matches(first)) {
                                            resultTitle =
                                                locale.toolText(
                                                    "result.alertNoMatch",
                                                    "Alert saved; no matching event",
                                                )
                                            resultBody = locale.noCharge
                                            return@Button
                                        }
                                        val latest = requireNotNull(first.latest)
                                        resultTitle = locale.toolText(
                                            "result.alertDelivered",
                                            "Price alert delivered",
                                        )
                                        resultBody = locale.toolText(
                                            "body.alert",
                                            "{commodity}: {price} {currency}/{unit} · official period {period}\nStatistics Norway · 03024 · CC BY 4.0",
                                            mapOf(
                                                "commodity" to
                                                    locale.commodityName(
                                                        first.commodityCode,
                                                    ),
                                                "price" to "%.2f".format(
                                                    Locale.US,
                                                    latest.pricePerKg,
                                                ),
                                                "currency" to
                                                    first.currencyCode,
                                                "unit" to first.unit,
                                                "period" to latest.periodCode,
                                            ),
                                        )
                                    }
                                    CommerceDestination.History -> Unit
                                }
                                if (!store.consumeSuccessfulResult(destination)) {
                                    error(
                                        locale.toolText(
                                            "noCredit",
                                            "No credit is available.",
                                        ),
                                    )
                                }
                            }.onFailure {
                                resultTitle = locale.toolText(
                                    "noResult",
                                    "No result",
                                )
                                resultBody = locale.noCharge
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 10.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SignalBlue,
                            contentColor = DeepOcean,
                        ),
                    ) {
                        Icon(Icons.Outlined.CheckCircle, null)
                        Spacer(Modifier.size(7.dp))
                        Text(
                            actionTitle(destination, locale),
                            fontWeight = FontWeight.Bold,
                        )
                    }

                    if (balance == 0) {
                        Text(
                            locale.toolText(
                                "creditPrompt",
                                "Choose a finite credit pack or subscription allowance.",
                            ),
                            color = SunGold,
                            fontSize = 9.sp,
                            modifier = Modifier.padding(top = 8.dp),
                        )
                        OutlinedButton(
                            onClick = { showsStore = true },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(top = 7.dp),
                        ) {
                            Icon(Icons.Outlined.ShoppingCart, null)
                            Spacer(Modifier.size(7.dp))
                            Text(
                                locale.toolText(
                                    "viewPlans",
                                    "View plans and credit packs",
                                ),
                            )
                        }
                    }
                }
            }
        }

        if (resultTitle != null && resultBody != null) {
            item {
                DataCard(Modifier.fillMaxWidth()) {
                    Text(
                        resultTitle.orEmpty(),
                        color = AquaMint,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                    Spacer(Modifier.height(7.dp))
                    Text(
                        resultBody.orEmpty(),
                        color = TextPrimary,
                        fontSize = 11.sp,
                        lineHeight = 17.sp,
                    )
                }
            }
        }

        item {
            DataCard(Modifier.fillMaxWidth()) {
                Text(
                    locale.toolText(
                        "reuseTitle",
                        "COMMERCIAL REUSE VERIFIED",
                    ),
                    color = AquaMint,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(Modifier.height(6.dp))
                Text(
                    locale.toolText(
                        "reuseBody",
                        "Paid results in this release use Statistics Norway table 03024 under CC BY 4.0. Commercial use, derivative analysis and attributed redistribution are approved by the release registry.",
                    ),
                    color = TextSecondary,
                    fontSize = 10.sp,
                    lineHeight = 15.sp,
                )
                Text(
                    locale.toolText(
                        "benchmarkLimit",
                        "National weekly export unit values; not city prices, auction quotes or executable offers.",
                    ),
                    color = SunGold,
                    fontSize = 9.sp,
                    lineHeight = 13.sp,
                    modifier = Modifier.padding(top = 6.dp),
                )
            }
        }
    }
}

@Composable
private fun HistoryToolCard(
    store: AndroidCommerceStore,
    state: AuthorizedMarketLoadState,
    locale: CommerceLocaleText,
    onOpenStore: () -> Unit,
) {
    val weeks = store.historyWeeks()
    if (weeks <= 52) {
        DataCard(Modifier.fillMaxWidth(), emphasized = true) {
            Text(
                locale.toolText(
                    "historyLockedTitle",
                    "Extended history requires Markets Plus, Pro or Max",
                ),
                color = TextPrimary,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
            )
            Text(
                locale.toolText(
                    "historyLockedBody",
                    "The free market screen keeps 52 official weekly observations. A subscription unlocks a finite 3-, 5- or 10-year licensed history window.",
                ),
                color = TextSecondary,
                fontSize = 10.sp,
                lineHeight = 15.sp,
                modifier = Modifier.padding(top = 6.dp),
            )
            OutlinedButton(
                onClick = onOpenStore,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp),
            ) {
                Text(
                    locale.toolText(
                        "viewSubscriptions",
                        "View subscriptions",
                    ),
                )
            }
        }
        return
    }
    when (state) {
        AuthorizedMarketLoadState.Loading -> DataCard(Modifier.fillMaxWidth()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                )
                Spacer(Modifier.size(8.dp))
                Text(
                    locale.toolText(
                        "loading",
                        "Loading licensed observations…",
                    ),
                )
            }
        }
        is AuthorizedMarketLoadState.Unavailable ->
            DataCard(Modifier.fillMaxWidth()) {
                Text(state.message, color = TextSecondary)
            }
        is AuthorizedMarketLoadState.Loaded ->
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                state.series.forEach { series ->
                    DataCard(Modifier.fillMaxWidth()) {
                        Text(
                            locale.commodityName(series.commodityCode),
                            color = TextPrimary,
                            fontWeight = FontWeight.SemiBold,
                        )
                        Sparkline(
                            values = series.points
                                .takeLast(weeks)
                                .map { it.pricePerKg.toFloat() },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(190.dp)
                                .padding(top = 10.dp),
                            color = AquaMint,
                        )
                        Text(
                            locale.toolText(
                                "observationSummary",
                                "{count} official weekly observations · {currency}/{unit}",
                                mapOf(
                                    "count" to minOf(
                                        series.points.size,
                                        weeks,
                                    ).toString(),
                                    "currency" to series.currencyCode,
                                    "unit" to series.unit,
                                ),
                            ),
                            color = TextSecondary,
                            fontSize = 9.sp,
                        )
                        Text(
                            "Statistics Norway · 03024 · "
                                + "${series.commodityCode} · CC BY 4.0",
                            color = AquaMint,
                            fontSize = 9.sp,
                        )
                    }
                }
            }
    }
}

@Composable
private fun CommerceNumberField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label, fontSize = 10.sp) },
        singleLine = true,
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Decimal,
        ),
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 6.dp),
    )
}

private fun CommerceLocaleText.toolText(
    key: String,
    fallback: String,
    values: Map<String, String> = emptyMap(),
): String = replace(tool(key, fallback), values)

private fun CommerceLocaleText.commodityName(code: String): String =
    toolText(
        "commodity.$code",
        if (code == "01") {
            "Fresh or chilled, farmed"
        } else {
            "Frozen, farmed"
        },
    )

private fun actionTitle(
    destination: CommerceDestination,
    locale: CommerceLocaleText,
): String {
    val fallback = when (destination) {
        CommerceDestination.History -> "Open history"
        CommerceDestination.Export -> "Prepare CSV"
        CommerceDestination.Compare -> "Create comparison"
        CommerceDestination.Snapshot -> "Create snapshot"
        CommerceDestination.Seasonality -> "Create seasonality report"
        CommerceDestination.LandedCost -> "Calculate landed cost"
        CommerceDestination.Alerts -> "Save and evaluate alert"
    }
    return locale.toolText("action.${destination.wireValue}", fallback)
}

private fun numeric(value: String): Double {
    val number = value.replace(",", ".").toDoubleOrNull()
        ?: throw CommerceAnalyticsException.InvalidAssumption
    if (!number.isFinite()) throw CommerceAnalyticsException.InvalidAssumption
    return number
}

@Composable
private fun CommerceStorefrontScreen(
    store: AndroidCommerceStore,
    language: AquaAppLanguage,
    onBack: () -> Unit,
) {
    val details by store.productDetails.collectAsState()
    val status by store.statusMessage.collectAsState()
    val locale = store.catalog.locale(language.code)

    androidx.compose.foundation.lazy.LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = androidx.compose.foundation.layout.PaddingValues(
            start = 16.dp,
            top = 8.dp,
            end = 16.dp,
            bottom = 30.dp,
        ),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onBack) {
                    Icon(
                        Icons.AutoMirrored.Outlined.ArrowBack,
                        contentDescription = locale.toolText("back", "Back"),
                        tint = SignalBlue,
                    )
                }
                SectionHeader(
                    eyebrow = locale.store.optionsEyebrow,
                    title = locale.store.plansTitle,
                    modifier = Modifier.weight(1f),
                )
            }
            Text(
                locale.store.allowanceDisclosure,
                color = TextSecondary,
                fontSize = 10.sp,
                lineHeight = 15.sp,
                modifier = Modifier.padding(top = 6.dp),
            )
        }

        status?.let { message ->
            item {
                DataCard(Modifier.fillMaxWidth()) {
                    Text(message, color = SunGold, fontSize = 10.sp)
                }
            }
        }

        item {
            Text(
                locale.store.subscriptionsTitle.uppercase(
                    Locale.forLanguageTag(language.code),
                ),
                color = SignalBlue,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
            )
        }
        items(
            count = store.catalog.products.count { it.isSubscription },
            key = { index ->
                store.catalog.products.filter { it.isSubscription }[index].id
            },
        ) { index ->
            val product =
                store.catalog.products.filter { it.isSubscription }[index]
            CommerceProductCard(
                store = store,
                product = product,
                language = language,
                available = details.containsKey(product.id),
            )
        }

        item {
            Text(
                locale.store.oneTimeTitle.uppercase(
                    Locale.forLanguageTag(language.code),
                ),
                color = SignalBlue,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(top = 6.dp),
            )
        }
        val consumables = store.catalog.products.filter {
            !it.isSubscription
        }
        items(
            count = consumables.size,
            key = { index -> consumables[index].id },
        ) { index ->
            CommerceProductCard(
                store = store,
                product = consumables[index],
                language = language,
                available = details.containsKey(consumables[index].id),
            )
        }

        item {
            OutlinedButton(
                onClick = { store.restore(language.code) },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(locale.restore)
            }
            Text(
                locale.store.legalDisclosure,
                color = TextSecondary,
                fontSize = 9.sp,
                lineHeight = 13.sp,
                modifier = Modifier.padding(top = 8.dp),
            )
        }
    }
}

@Composable
private fun CommerceProductCard(
    store: AndroidCommerceStore,
    product: CommerceProductDefinition,
    language: AquaAppLanguage,
    available: Boolean,
) {
    val text = store.catalog.text(product, language.code)
    val locale = store.catalog.locale(language.code)
    DataCard(Modifier.fillMaxWidth(), emphasized = product.isSubscription) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top,
        ) {
            Column(Modifier.weight(1f)) {
                Text(
                    text.name,
                    color = TextPrimary,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    text.description,
                    color = TextSecondary,
                    fontSize = 9.sp,
                    lineHeight = 13.sp,
                    modifier = Modifier.padding(top = 4.dp),
                )
                Text(
                    locale.destinations[product.destination].orEmpty(),
                    color = AquaMint,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 5.dp),
                )
            }
            Spacer(Modifier.size(9.dp))
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    store.formattedPrice(product.id)
                        ?: locale.store.unavailable,
                    color = TextPrimary,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                )
                Button(
                    enabled = available,
                    onClick = {
                        store.purchase(product.id, language.code)
                    },
                    modifier = Modifier.padding(top = 5.dp),
                    contentPadding =
                        androidx.compose.foundation.layout.PaddingValues(
                            horizontal = 12.dp,
                            vertical = 4.dp,
                        ),
                ) {
                    Text(locale.purchase, fontSize = 10.sp)
                }
            }
        }
    }
}
