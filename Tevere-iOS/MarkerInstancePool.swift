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
    
    private func generateMarker(battle: JSON, places: JSON) -> GMSMarker {
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
        let marker = GMSMarker(position: position)
        marker.icon = redMakerIcon
        marker.zIndex = 1
        marker.userData = battle
        return marker
    }
    
    func plotMarker(battles: JSON, places: JSON, mapView: GMSMapView) {
        var newMarkers: [String: GMSMarker] = [:]
        for battle in battles {
            let uri = battle.1["uri"].stringValue
            if plottingMarkers[uri] != nil {
                newMarkers[uri] = plottingMarkers[uri]
                plottingMarkers[uri] = nil
            }
            let marker = generateMarker(battle: battle.1, places: places)
            marker.map = mapView
            marker.isTappable = true
            newMarkers[battle.1["uri"].stringValue] = marker
        }
        for marker in plottingMarkers.values {
            marker.map = nil
        }
        self.plottingMarkers = newMarkers
    }
    
    func get(uri: String) -> GMSMarker? {
        return plottingMarkers[uri]
    }
}
