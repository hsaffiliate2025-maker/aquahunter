import SwiftUI

#if os(iOS)
import MapLibre
import UIKit
#endif

struct LicensedMapMarker: Identifiable, Hashable {
    enum Kind: Hashable {
        case market
        case port
        case reference
    }

    let id: String
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let kind: Kind
}

struct LicensedWorldMap: View {
    let markers: [LicensedMapMarker]
    var centerLatitude: Double = 25
    var centerLongitude: Double = 10
    var zoomLevel: Double = 0.8

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            #if os(iOS)
            MapLibreWorldMap(
                markers: markers,
                centerLatitude: centerLatitude,
                centerLongitude: centerLongitude,
                zoomLevel: zoomLevel
            )
            #else
            NaturalEarthWorldCanvas(markers: markers)
            #endif

            Text("MapLibre · Natural Earth public domain · Not for navigation")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(.black.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .padding(8)
        }
        .frame(minHeight: 260)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AquaTheme.divider, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Offline world map. Not for navigation.")
    }
}

#if os(iOS)
private struct MapLibreWorldMap: UIViewRepresentable {
    let markers: [LicensedMapMarker]
    let centerLatitude: Double
    let centerLongitude: Double
    let zoomLevel: Double

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MLNMapView {
        let styleURL = Bundle.main.url(
            forResource: "aquahunter-offline-style",
            withExtension: "json"
        )
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.compassView.isHidden = false
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        mapView.showsUserLocation = false
        mapView.isPitchEnabled = false
        mapView.setCenter(
            CLLocationCoordinate2D(
                latitude: centerLatitude,
                longitude: centerLongitude
            ),
            zoomLevel: zoomLevel,
            animated: false
        )
        context.coordinator.update(markers: markers, on: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        context.coordinator.update(markers: markers, on: mapView)
    }

    final class Coordinator: NSObject, MLNMapViewDelegate {
        private var pendingMarkers: [LicensedMapMarker] = []
        private var displayedAnnotations: [MLNPointAnnotation] = []
        private var isStyleReady = false

        func update(markers: [LicensedMapMarker], on mapView: MLNMapView) {
            pendingMarkers = markers
            guard isStyleReady else { return }
            replaceAnnotations(on: mapView)
        }

        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            if let landURL = Bundle.main.url(
                forResource: "ne_110m_land",
                withExtension: "geojson"
            ) {
                let source = MLNShapeSource(
                    identifier: "natural-earth-land",
                    url: landURL,
                    options: nil
                )
                style.addSource(source)

                let fill = MLNFillStyleLayer(
                    identifier: "natural-earth-land-fill",
                    source: source
                )
                fill.fillColor = NSExpression(
                    forConstantValue: UIColor(red: 0.08, green: 0.23, blue: 0.36, alpha: 1)
                )
                fill.fillOutlineColor = NSExpression(
                    forConstantValue: UIColor(red: 0.25, green: 0.57, blue: 0.79, alpha: 0.72)
                )
                style.addLayer(fill)

                let coast = MLNLineStyleLayer(
                    identifier: "natural-earth-coastline",
                    source: source
                )
                coast.lineColor = NSExpression(
                    forConstantValue: UIColor(red: 0.30, green: 0.67, blue: 0.92, alpha: 0.72)
                )
                coast.lineWidth = NSExpression(forConstantValue: 0.8)
                style.addLayer(coast)
            }

            isStyleReady = true
            replaceAnnotations(on: mapView)
        }

        private func replaceAnnotations(on mapView: MLNMapView) {
            if !displayedAnnotations.isEmpty {
                mapView.removeAnnotations(displayedAnnotations)
            }
            displayedAnnotations = pendingMarkers.map { marker in
                let annotation = MLNPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(
                    latitude: marker.latitude,
                    longitude: marker.longitude
                )
                annotation.title = marker.title
                annotation.subtitle = marker.subtitle
                return annotation
            }
            mapView.addAnnotations(displayedAnnotations)
        }
    }
}
#else
private struct NaturalEarthWorldCanvas: View {
    let markers: [LicensedMapMarker]

    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color(red: 0.024, green: 0.102, blue: 0.22))
            )

            drawGrid(context: &context, size: size)

            var land = Path()
            for ring in NaturalEarthGeometry.rings {
                guard let first = ring.first else { continue }
                land.move(to: project(first, into: size))
                for point in ring.dropFirst() {
                    land.addLine(to: project(point, into: size))
                }
                land.closeSubpath()
            }
            context.fill(
                land,
                with: .color(Color(red: 0.08, green: 0.23, blue: 0.36)),
                style: FillStyle(eoFill: true)
            )
            context.stroke(
                land,
                with: .color(AquaTheme.radarCyan.opacity(0.48)),
                lineWidth: 0.65
            )

            for marker in markers {
                let position = project(
                    CGPoint(x: marker.longitude, y: marker.latitude),
                    into: size
                )
                let color: Color = marker.kind == .market
                    ? AquaTheme.positive
                    : marker.kind == .port
                        ? AquaTheme.signalBlue
                        : AquaTheme.radarCyan
                context.fill(
                    Path(ellipseIn: CGRect(x: position.x - 7, y: position.y - 7, width: 14, height: 14)),
                    with: .color(color.opacity(0.25))
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: position.x - 3.5, y: position.y - 3.5, width: 7, height: 7)),
                    with: .color(color)
                )
                context.draw(
                    Text(marker.title)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.white),
                    at: CGPoint(x: position.x + 6, y: position.y - 8),
                    anchor: .leading
                )
            }
        }
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        var grid = Path()
        for longitude in stride(from: -120.0, through: 120.0, by: 60.0) {
            let x = project(CGPoint(x: longitude, y: 0), into: size).x
            grid.move(to: CGPoint(x: x, y: 0))
            grid.addLine(to: CGPoint(x: x, y: size.height))
        }
        for latitude in stride(from: -60.0, through: 60.0, by: 30.0) {
            let y = project(CGPoint(x: 0, y: latitude), into: size).y
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(grid, with: .color(.white.opacity(0.08)), lineWidth: 0.5)
    }

    private func project(_ coordinate: CGPoint, into size: CGSize) -> CGPoint {
        CGPoint(
            x: (coordinate.x + 180) / 360 * size.width,
            y: (90 - coordinate.y) / 180 * size.height
        )
    }
}

private enum NaturalEarthGeometry {
    static let rings: [[CGPoint]] = loadRings()

    private static func loadRings() -> [[CGPoint]] {
        guard
            let url = Bundle.main.url(forResource: "ne_110m_land", withExtension: "geojson"),
            let data = try? Data(contentsOf: url),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let features = root["features"] as? [[String: Any]]
        else {
            return []
        }

        var output: [[CGPoint]] = []
        for feature in features {
            guard
                let geometry = feature["geometry"] as? [String: Any],
                let type = geometry["type"] as? String,
                let coordinates = geometry["coordinates"] as? [Any]
            else {
                continue
            }

            if type == "Polygon" {
                appendPolygon(coordinates, to: &output)
            } else if type == "MultiPolygon" {
                for polygon in coordinates {
                    guard let polygon = polygon as? [Any] else { continue }
                    appendPolygon(polygon, to: &output)
                }
            }
        }
        return output
    }

    private static func appendPolygon(_ polygon: [Any], to output: inout [[CGPoint]]) {
        for rawRing in polygon {
            guard let ring = rawRing as? [[Double]] else { continue }
            let points = ring.compactMap { pair -> CGPoint? in
                guard pair.count >= 2 else { return nil }
                return CGPoint(x: pair[0], y: pair[1])
            }
            if points.count >= 3 {
                output.append(points)
            }
        }
    }
}
#endif
