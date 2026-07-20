package com.hotseason.aquahunter.data

import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject

object StatisticsNorwayMarketRepository {
    private const val ENDPOINT =
        "https://data.ssb.no/api/pxwebapi/v2/tables/03024/data" +
            "?lang=en" +
            "&valueCodes%5BVareGrupper2%5D=01" +
            "&valueCodes%5BContentsCode%5D=*" +
            "&valueCodes%5BTid%5D=top%2852%29" +
            "&outputFormat=json-stat2"

    suspend fun fetchFreshSalmonSeries(): AuthorizedMarketSeries = withContext(Dispatchers.IO) {
        val connection = (URL(ENDPOINT).openConnection() as HttpURLConnection).apply {
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

    internal fun parseSeries(payload: JSONObject): AuthorizedMarketSeries {
        val ids = payload.getJSONArray("id").toStringList()
        val sizes = payload.getJSONArray("size").toIntList()
        if (ids != listOf("VareGrupper2", "ContentsCode", "Tid") ||
            sizes.size != 3 ||
            sizes[0] != 1 ||
            sizes[1] != 2
        ) {
            throw MarketDataException("Official dataset structure changed and requires review.")
        }

        val dimensions = payload.getJSONObject("dimension")
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

        val values = payload.getJSONArray("value")
        val points = buildList {
            timeCodes.forEachIndexed { timeIndex, periodCode ->
                val priceOffset = priceIndex * timeCount + timeIndex
                val weightOffset = weightIndex * timeCount + timeIndex
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

        return AuthorizedMarketSeries(
            id = "ssb-03024-fresh-salmon",
            species = "Atlantic Salmon",
            scientificName = "Salmo salar",
            geography = "Norway",
            countryCode = "NO",
            benchmark = "Norway farmed salmon export benchmark",
            commodityForm = "Fresh or chilled, farmed",
            currencyCode = "NOK",
            unit = "kg",
            sourceId = "ssb-statbank-03024",
            sourceUrl = "https://www.ssb.no/en/statbank1/table/03024",
            licenseName = "CC BY 4.0",
            licenseUrl = "https://creativecommons.org/licenses/by/4.0/",
            attribution = "Source: Statistics Norway, table 03024",
            providerUpdatedAt = payload.optString("updated").takeIf { it.isNotBlank() },
            retrievedAt = Instant.now().toString(),
            latency = "Weekly official statistic",
            points = points,
        )
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

