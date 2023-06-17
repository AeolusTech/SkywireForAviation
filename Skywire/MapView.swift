//
//  MapView.swift
//  Skywire
//
//  Created by Kamil Kuczaj on 17/06/2023.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isUserInteractionEnabled = false
        mapView.accessibilityIdentifier = "mapView"
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setCenter(coordinate, animated: true)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        uiView.setRegion(region, animated: true)

        uiView.removeAnnotations(uiView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        uiView.addAnnotation(annotation)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }
    }
}
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(coordinate: .constant(CLLocationCoordinate2D()))
    }
}
