//
//  MarkerInstancePool.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/25.
//  Copyright © 2018年 sasau. All rights reserved.
//

import Foundation
import GoogleMaps
import SwiftyJSON


class MarkerInstancePool {
    var markerPool: [GMSMarker] = []
    var plottingMarkers: [String: GMSMarker] = [:]
    
    // Resources
    let redMakerIcon = GMSMarker.markerImage(with: .red)
    let blueMakerIcon = GMSMarker.markerImage(with: .blue)
    
    private func updateMarker(marker: GMSMarker, battle: JSON) {
        var point = battle["points"][0]
        if point.isEmpty {
            let placeURI = battle["places"][0].stringValue
            let places = battle["places"]
            let place = places[placeURI]
            point = place["points"][0]
        }
        let lat: CLLocationDegrees = point[0].doubleValue
        let lng: CLLocationDegrees = point[1].doubleValue
        marker.position = CLLocationCoordinate2D(
            latitude: lat,
            longitude: lng
        )
        marker.userData = battle
        marker.icon = redMakerIcon
        marker.zIndex = 1
    }
    
    func plotMarker(battles: JSON, mapView: GMSMapView) {
        var newMarkers: [String: GMSMarker] = [:]
        for battle in battles {
            let uri = battle.1["uri"].stringValue
            if plottingMarkers[uri] != nil {
                newMarkers[uri] = plottingMarkers[uri]
                plottingMarkers[uri] = nil
                continue
            }
            let marker: GMSMarker
            if !markerPool.isEmpty {
                marker = markerPool.popLast()!
            } else {
                marker = GMSMarker.init()
            }
            updateMarker(marker: marker, battle: battle.1)
            newMarkers[battle.1["uri"].stringValue] = marker
            marker.userData = battle.1
            marker.icon = redMakerIcon
            marker.zIndex = 1
            marker.map = mapView
        }
        for marker in plottingMarkers.values {
            marker.map = nil
            markerPool.append(marker)
        }
        self.plottingMarkers = newMarkers
    }
    
    func get(uri: String) -> GMSMarker? {
        return plottingMarkers[uri]
    }
}
