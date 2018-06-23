//
//  AppDelegate.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/12.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import GoogleMaps
import SVProgressHUD


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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyBjN9sSI8blsqQ6T5e7ujh9Xml_U5Tehvo")
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.setDefaultStyle(.dark)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        ArchivedData.shared.archive()
    }
}

