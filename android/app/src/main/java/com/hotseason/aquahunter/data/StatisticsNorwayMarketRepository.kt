package com.hotseason.aquahunter.data

import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject

object StatisticsNorwayMarketRepository {
    private const val ENDPOINT_BASE =
        "https://data.ssb.no/api/pxwebapi/v2/tables/03024/data"

    suspend fun fetchSalmonSeries(historyWeeks: Int = 52): List<AuthorizedMarketSeries> =
        withContext(Dispatchers.IO) {
        require(historyWeeks in 1..1_386) {
            "Requested history is outside the official dataset."
        }
        val endpoint = ENDPOINT_BASE +
            "?lang=en" +
            "&valueCodes%5BVareGrupper2%5D=*" +
            "&valueCodes%5BContentsCode%5D=*" +
            "&valueCodes%5BTid%5D=top%28$historyWeeks%29" +
            "&outputFormat=json-stat2"
        val connection = (URL(endpoint).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 20_000
            readTimeout = 20_000
            setRequestProperty("Accept", "application/json")
            setRequestProperty("User-Agent", "AquaHunter/1.0 (contact@hotseason.app)")
        }

        try {
            val status = connection.responseCode
            if (status !in 200..299) {
                throw MarketDataException("Official data service returned HTTP $status.")
            }
            val body = connection.inputStream.bufferedReader().use { it.readText() }
            parseSeries(JSONObject(body))
        } finally {
            connection.disconnect()
        }
    }

    internal fun parseSeries(payload: JSONObject): List<AuthorizedMarketSeries> {
        val ids = payload.getJSONArray("id").toStringList()
        val sizes = payload.getJSONArray("size").toIntList()
        if (ids != listOf("VareGrupper2", "ContentsCode", "Tid") ||
            sizes.size != 3 ||
            sizes[0] != 2 ||
            sizes[1] != 2
        ) {
            throw MarketDataException("Official dataset structure changed and requires review.")
        }

        val dimensions = payload.getJSONObject("dimension")
        val commodityCodes = orderedCodes(dimensions.getJSONObject("VareGrupper2"))
        val timeCodes = orderedCodes(dimensions.getJSONObject("Tid"))
        val contentIndex = categoryIndex(dimensions.getJSONObject("ContentsCode"))
        val priceIndex = contentIndex["Kilopris"]
            ?: throw MarketDataException("Price field is missing from the official dataset.")
        val weightIndex = contentIndex["Vekt"]
            ?: throw MarketDataException("Weight field is missing from the official dataset.")
        val timeCount = sizes[2]
        if (timeCodes.size != timeCount) {
            throw MarketDataException("Official time dimension is inconsistent.")
        }
        if (commodityCodes != listOf("01", "02")) {
            throw MarketDataException("Official commodity dimension is inconsistent.")
        }

        val values = payload.getJSONArray("value")
        val contentCount = sizes[1]
        return commodityCodes.mapIndexed { commodityIndex, commodityCode ->
            val points = buildList {
                timeCodes.forEachIndexed { timeIndex, periodCode ->
                    val commodityOffset = commodityIndex * contentCount * timeCount
                    val priceOffset = commodityOffset + priceIndex * timeCount + timeIndex
                    val weightOffset = commodityOffset + weightIndex * timeCount + timeIndex
                    val price = values.nullableDouble(priceOffset)
                    if (price != null && price.isFinite() && price > 0) {
                        add(
                            MarketDataPoint(
                                periodCode = periodCode,
                                pricePerKg = price,
                                volumeTonnes = values.nullableDouble(weightOffset),
                            ),
                        )
                    }
                }
            }
            if (points.isEmpty()) {
                throw MarketDataException("The official dataset contains no publishable values.")
            }

            val isFresh = commodityCode == "01"
            AuthorizedMarketSeries(
                id = if (isFresh) {
                    "ssb-03024-fresh-salmon"
                } else {
                    "ssb-03024-frozen-salmon"
                },
                species = "Atlantic Salmon",
                scientificName = "Salmo salar",
                geography = "Norway",
                countryCode = "NO",
                benchmark = if (isFresh) {
                    "Norway fresh/chilled farmed salmon export benchmark"
                } else {
                    "Norway frozen farmed salmon export benchmark"
                },
                commodityCode = commodityCode,
                commodityForm = if (isFresh) {
                    "Fresh or chilled, farmed"
                } else {
                    "Frozen, farmed"
                },
                currencyCode = "NOK",
                unit = "kg",
                sourceId = "ssb-statbank-03024",
                sourceUrl = "https://www.ssb.no/en/statbank1/table/03024",
                licenseName = "CC BY 4.0",
                licenseUrl = "https://creativecommons.org/licenses/by/4.0/",
                attribution = "Source: Statistics Norway, table 03024, commodity $commodityCode",
                providerUpdatedAt = payload.optString("updated").takeIf { it.isNotBlank() },
                retrievedAt = Instant.now().toString(),
                latency = "Weekly official statistic",
                points = points,
            )
        }
    }

    private fun orderedCodes(dimension: JSONObject): List<String> {
        val index = categoryIndex(dimension)
        val result = MutableList(index.size) { "" }
        index.forEach { (code, position) ->
            if (position !in result.indices || result[position].isNotEmpty()) {
                throw MarketDataException("Official category index is inconsistent.")
            }
            result[position] = code
        }
        if (result.any { it.isEmpty() }) {
            throw MarketDataException("Official category index has gaps.")
        }
        return result
    }

    private fun categoryIndex(dimension: JSONObject): Map<String, Int> {
        val index = dimension.getJSONObject("category").getJSONObject("index")
        return buildMap {
            val keys = index.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                put(key, index.getInt(key))
            }
        }
    }
}

private class MarketDataException(message: String) : Exception(message)

private fun org.json.JSONArray.toStringList(): List<String> =
    List(length()) { index -> getString(index) }

private fun org.json.JSONArray.toIntList(): List<Int> =
    List(length()) { index -> getInt(index) }

private fun org.json.JSONArray.nullableDouble(index: Int): Double? {
    if (index !in 0 until length() || isNull(index)) return null
    return getDouble(index)
}
