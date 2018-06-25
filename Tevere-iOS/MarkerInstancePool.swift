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
    
    private func updateMarker(marker: GMSMarker, battle: JSON, places: JSON) {
        var point = battle["points"][0]
        if point.isEmpty {
            let placeURI = battle["places"][0].stringValue
            let place = places[placeURI]
            point = place["points"][0]
        }
        let lat: CLLocationDegrees = point[0].doubleValue
        let lng: CLLocationDegrees = point[1].doubleValue
        let position = CLLocationCoordinate2D(
            latitude: lat,
            longitude: lng
        )
        marker.position = position
        marker.icon = redMakerIcon
        marker.zIndex = 1
        marker.userData = battle
    }
    
    func plotMarker(battles: JSON, places: JSON, mapView: GMSMapView) {
        var newMarkers: [String: GMSMarker] = [:]
        for battle in battles {
            let uri = battle.1["uri"].stringValue
            if plottingMarkers[uri] != nil {
                newMarkers[uri] = plottingMarkers[uri]
                plottingMarkers[uri] = nil
            }
        }
        for marker in plottingMarkers.values {
            marker.isTappable = false
            marker.userData = nil
            marker.map = nil
            markerPool.append(marker)
        }
        for battle in battles {
            let uri = battle.1["uri"].stringValue
            if newMarkers[uri] != nil {
                continue
            }
            let marker: GMSMarker
            if markerPool.isEmpty {
                marker = GMSMarker()
            } else {
                marker = markerPool.popLast()!
            }
            marker.map = mapView
            marker.isTappable = true
            updateMarker(marker: marker, battle: battle.1, places: places)
            newMarkers[battle.1["uri"].stringValue] = marker
        }
        self.plottingMarkers = newMarkers
    }
    
    func get(uri: String) -> GMSMarker? {
        return plottingMarkers[uri]
    }
}
