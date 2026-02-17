//
//  ContentView.swift
//  MapNavigatorTransport
//
//  Created by mac on 2026-02-17.
//

import SwiftUI
import MapKit

enum TransportMode: String, CaseIterable, Identifiable {
    case automobile = "🚗"
    case transit = "🚇"
    case walking = "🚶"
    case cycling = "🚴"
    
    var id: String { rawValue }
    
    var mkType: MKDirectionsTransportType {
        switch self {
        case .automobile: return .automobile
        case .transit: return .transit
        case .walking: return .walking
        case .cycling: return .automobile
        }
    }
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4919, longitude: -73.5794),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var searchText = ""
    @State private var destination: CLLocationCoordinate2D?
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var transportMode: TransportMode = .automobile
    @State private var routeDistance: String = ""
    @State private var routeTime: String = ""
    @State private var routePolyline: MKPolyline?
    
    let lasalle = CLLocationCoordinate2D(latitude: 45.4919, longitude: -73.5794)
    
    var annotations: [MapLocation] {
        var items = [MapLocation(coordinate: lasalle, title: "Collège LaSalle", color: .red)]
        
        if let userLoc = locationManager.userLocation {
            items.append(MapLocation(coordinate: userLoc, title: "You", color: .blue))
        }
        
        if let dest = destination {
            items.append(MapLocation(coordinate: dest, title: "Destination", color: .green))
        }
        
        return items
    }
    
    var body: some View {
        ZStack {
            MapViewWithRoute(region: $region, annotations: annotations, polyline: routePolyline)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Button(action: zoomIn) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Button(action: zoomOut) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                
                if !routeDistance.isEmpty {
                    VStack(spacing: 8) {
                        Text("Route Info")
                            .font(.headline)
                        HStack(spacing: 20) {
                            Text("Distance: \(routeDistance)")
                            Text("Time: \(routeTime)")
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                }
                
                Picker("Transport", selection: $transportMode) {
                    ForEach(TransportMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
                .onChange(of: transportMode) { _ in
                    if destination != nil {
                        calculateRoute()
                    }
                }
                
                HStack {
                    TextField("Search destination", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: runSearch) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
            }
        }
        .alert("Search Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func zoomIn() {
        withAnimation {
            region.span.latitudeDelta *= 0.5
            region.span.longitudeDelta *= 0.5
        }
    }
    
    func zoomOut() {
        withAnimation {
            region.span.latitudeDelta *= 2
            region.span.longitudeDelta *= 2
        }
    }
    
    func runSearch() {
        guard !searchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if error != nil {
                    self.errorMessage = "No results found"
                    self.showError = true
                    return
                }
                
                guard let item = response?.mapItems.first else {
                    self.errorMessage = "No results found"
                    self.showError = true
                    return
                }
                
                //  reject if result is too far (more than 100km from Montreal)
                let resultLocation = CLLocation(
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude
                )
                let montrealCenter = CLLocation(latitude: 45.5017, longitude: -73.5673)
                let distance = resultLocation.distance(from: montrealCenter) / 1000 //  to km
                
                if distance > 100 {
                    self.errorMessage = "No results found"
                    self.showError = true
                    return
                }
                
              
                self.destination = item.placemark.coordinate
                
                withAnimation {
                    self.region.center = item.placemark.coordinate
                    self.region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                }
                
                self.calculateRoute()
            }
        }
    }
    
    func calculateRoute() {
        guard let dest = destination else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: lasalle))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        request.transportType = transportMode.mkType
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                if error != nil {
                    if self.transportMode == .transit {
                        self.errorMessage = "No public transit route available. Try 🚗 automobile or 🚶 walking."
                    } else {
                        self.errorMessage = "Route not available. Try a different transport mode."
                    }
                    self.showError = true
                    self.routeDistance = ""
                    self.routeTime = ""
                    self.routePolyline = nil
                    return
                }
                
                guard let route = response?.routes.first else {
                    self.routeDistance = ""
                    self.routeTime = ""
                    self.routePolyline = nil
                    return
                }
                
                self.routePolyline = route.polyline
                self.routeDistance = String(format: "%.2f km", route.distance / 1000)
                self.routeTime = String(format: "%.0f min", route.expectedTravelTime / 60)
                
                self.fitRouteInView(route: route)
            }
        }
    }
    
    func fitRouteInView(route: MKRoute) {
        let rect = route.polyline.boundingMapRect
        
        withAnimation {
            self.region = MKCoordinateRegion(rect)
            
            let latPadding = self.region.span.latitudeDelta * 0.3
            let lonPadding = self.region.span.longitudeDelta * 0.3
            self.region.span.latitudeDelta += latPadding
            self.region.span.longitudeDelta += lonPadding
        }
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let color: Color
}

struct MapViewWithRoute: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let annotations: [MapLocation]
    let polyline: MKPolyline?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        mapView.removeAnnotations(mapView.annotations)
        
        for location in annotations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.title
            mapView.addAnnotation(annotation)
        }
        
        mapView.removeOverlays(mapView.overlays)
        if let polyline = polyline {
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, annotations: annotations)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithRoute
        let annotations: [MapLocation]
        
        init(_ parent: MapViewWithRoute, annotations: [MapLocation]) {
            self.parent = parent
            self.annotations = annotations
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "Marker"
            
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }
            
            if let title = annotation.title ?? "" {
                if title == "Collège LaSalle" {
                    view?.markerTintColor = .red
                } else if title == "You" {
                    view?.markerTintColor = .blue
                } else if title == "Destination" {
                    view?.markerTintColor = .green
                }
            }
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
