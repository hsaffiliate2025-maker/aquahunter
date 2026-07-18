package com.hsaffiliate.aquahunter.ui.components

import android.graphics.Color as AndroidColor
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import org.maplibre.android.MapLibre
import org.maplibre.android.annotations.MarkerOptions
import org.maplibre.android.camera.CameraPosition
import org.maplibre.android.geometry.LatLng
import org.maplibre.android.maps.MapView
import org.maplibre.android.maps.Style
import org.maplibre.android.style.layers.FillLayer
import org.maplibre.android.style.layers.LineLayer
import org.maplibre.android.style.layers.PropertyFactory.fillColor
import org.maplibre.android.style.layers.PropertyFactory.fillOutlineColor
import org.maplibre.android.style.layers.PropertyFactory.lineColor
import org.maplibre.android.style.layers.PropertyFactory.lineWidth
import org.maplibre.android.style.sources.GeoJsonSource
import java.net.URI

data class LicensedMapMarker(
    val id: String,
    val title: String,
    val subtitle: String,
    val latitude: Double,
    val longitude: Double,
)

@Composable
fun LicensedWorldMap(
    markers: List<LicensedMapMarker>,
    modifier: Modifier = Modifier,
    centerLatitude: Double = 25.0,
    centerLongitude: Double = 10.0,
    zoomLevel: Double = 0.8,
) {
    val context = LocalContext.current
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    val mapView = remember(context) {
        MapLibre.getInstance(context.applicationContext)
        MapView(context).apply { onCreate(null) }
    }

    DisposableEffect(lifecycle, mapView) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> mapView.onStart()
                Lifecycle.Event.ON_RESUME -> mapView.onResume()
                Lifecycle.Event.ON_PAUSE -> mapView.onPause()
                Lifecycle.Event.ON_STOP -> mapView.onStop()
                else -> Unit
            }
        }
        lifecycle.addObserver(observer)
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) mapView.onStart()
        if (lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) mapView.onResume()

        onDispose {
            lifecycle.removeObserver(observer)
            if (lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) mapView.onPause()
            if (lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) mapView.onStop()
            mapView.onDestroy()
        }
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(270.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(Color(0xFF061A38)),
    ) {
        AndroidView(
            factory = { mapView },
            modifier = Modifier.fillMaxSize(),
            update = { view ->
                view.getMapAsync { map ->
                    val applyMarkers = {
                        map.clear()
                        markers.forEach { marker ->
                            map.addMarker(
                                MarkerOptions()
                                    .position(LatLng(marker.latitude, marker.longitude))
                                    .title(marker.title)
                                    .snippet(marker.subtitle),
                            )
                        }
                        map.cameraPosition = CameraPosition.Builder()
                            .target(LatLng(centerLatitude, centerLongitude))
                            .zoom(zoomLevel)
                            .build()
                    }

                    if (map.style == null) {
                        map.setStyle(offlineStyle()) {
                            applyMarkers()
                        }
                    } else {
                        applyMarkers()
                    }
                }
            },
        )

        Text(
            text = "MapLibre · Natural Earth public domain · Not for navigation",
            color = Color.White.copy(alpha = 0.84f),
            fontSize = 8.sp,
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(8.dp)
                .background(Color.Black.copy(alpha = 0.58f), RoundedCornerShape(6.dp))
                .padding(horizontal = 7.dp, vertical = 5.dp),
        )
    }
}

private fun offlineStyle(): Style.Builder = Style.Builder()
    .fromJson(
        """
        {
          "version": 8,
          "name": "AquaHunter Offline Ocean",
          "sources": {},
          "layers": [
            {
              "id": "ocean-background",
              "type": "background",
              "paint": { "background-color": "#061A38" }
            }
          ]
        }
        """.trimIndent(),
    )
    .withSource(
        GeoJsonSource(
            "natural-earth-land",
            URI("asset://natural-earth/ne_110m_land.geojson"),
        ),
    )
    .withLayer(
        FillLayer("natural-earth-land-fill", "natural-earth-land").withProperties(
            fillColor(AndroidColor.rgb(20, 59, 92)),
            fillOutlineColor(AndroidColor.rgb(76, 171, 235)),
        ),
    )
    .withLayer(
        LineLayer("natural-earth-coastline", "natural-earth-land").withProperties(
            lineColor(AndroidColor.argb(190, 76, 171, 235)),
            lineWidth(0.8f),
        ),
    )
