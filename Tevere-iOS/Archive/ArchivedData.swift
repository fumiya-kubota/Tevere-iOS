//
//  ArchivedData.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/23.
//  Copyright © 2018年 sasau. All rights reserved.
//

import Foundation

class ArchivedData {
    enum UserDefaultsDomain: String {
        case Lat = "cc.tevere.app.lat"
        case Lng = "cc.tevere.app.lng"
        case Zoom = "cc.tevere.app.zoom"
        case Year = "cc.tevere.app.year"
    }
    var lat: Double
    var lng: Double
    var zoom: Float
    var year: Int
    
    private init() {
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: [
            UserDefaultsDomain.Lat.rawValue: 41.89083333333333,
            UserDefaultsDomain.Lng.rawValue: 12.477222222222222,
            UserDefaultsDomain.Zoom.rawValue: 3.2,
            UserDefaultsDomain.Year.rawValue: -220
            ])
        self.lat = userDefaults.double(forKey: UserDefaultsDomain.Lat.rawValue)
        self.lng = userDefaults.double(forKey: UserDefaultsDomain.Lng.rawValue)
        self.zoom = userDefaults.float(forKey: UserDefaultsDomain.Zoom.rawValue)
        self.year = userDefaults.integer(forKey: UserDefaultsDomain.Year.rawValue)
    }
    
    func updatePoint(lat: Double, lng: Double, zoom: Float) {
        self.lat = lat
        self.lng = lng
        self.zoom = zoom
    }
    
    func updateYear(year: Int) {
        self.year = year
    }
    
    func archive() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(lat, forKey: UserDefaultsDomain.Lat.rawValue)
        userDefaults.set(lng, forKey: UserDefaultsDomain.Lng.rawValue)
        userDefaults.set(zoom, forKey: UserDefaultsDomain.Zoom.rawValue)
        userDefaults.set(year, forKey: UserDefaultsDomain.Year.rawValue)
    }
    
    static let shared = ArchivedData()
}
