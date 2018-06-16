//
//  ViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/12.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON


class ViewController: UIViewController, GMSMapViewDelegate {
    
    // IBOutlet
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var detailViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailTitleLabel: UILabel!
    @IBOutlet weak var battleNavigationView: UIView!
    @IBOutlet weak var leftleftButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var rightrightButton: UIButton!
    // UI Parameters
    var detailHeaderBeganTop: CGFloat = 0
    var showDetailHeader: Bool = true
    var showingDetail: Bool = false

    // entities
    var data: JSON? = nil
    var battle: JSON? = nil
    
    var markers: [String: GMSMarker] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera = GMSCameraPosition.camera(withLatitude: 41.89083333333333, longitude: 12.477222222222222, zoom: 3.2)
        self.mapView.camera = camera
        self.mapView.delegate = self
        
        let url: String = "https://tevere.cc/api/tevere?from=-220&to=-211"
        Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseJSON{ response in
            
            switch response.result {
            case .success:
                let json:JSON = JSON(response.result.value ?? kill)
                self.updateData(data: json)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func updateData(data: JSON) {
        self.data = data
        let battles = data["battles"]
        var newMarkers: [String: GMSMarker] = [:]
        for battle in battles {
            let uri = battle.1["uri"].stringValue
            if markers[uri] != nil {
                newMarkers[uri] = markers[uri]
                markers[uri] = nil
                continue
            }
            let marker = GMSMarker()
            var point = battle.1["points"][0]
            if point.isEmpty {
                let placeURI = battle.1["places"][0].stringValue
                let places = data["places"]
                let place = places[placeURI]
                point = place["points"][0]
            }
            let lat: CLLocationDegrees = point[0].doubleValue
            let lng: CLLocationDegrees = point[1].doubleValue
            marker.position = CLLocationCoordinate2D(
                latitude: lat,
                longitude: lng
            )
            newMarkers[battle.1["uri"].stringValue] = marker
            marker.userData = battle.1
            marker.map = mapView
        }
        for marker in markers.values {
            marker.map = nil
        }
        markers = newMarkers
    }
    
    func updateBattle(newBattle: JSON?) {
        battle = newBattle
        if let battle_ = battle {
            if detailViewTopConstraint.constant >= 0 {
                detailViewTopConstraint.constant = -60
            }
            self.detailTitleLabel.text = battle_["label"].stringValue
            if let data_ = data {
                var index = 0
                for battle in data_["battles"] {
                    if battle_["uri"] == battle.1["uri"] {
                        index = Int(battle.0)!
                        break
                    }
                }
                if index == 0 {
                    self.leftButton.isEnabled = false
                    self.leftleftButton.isEnabled = false
                } else {
                    self.leftButton.isEnabled = true
                    self.leftleftButton.isEnabled = true
                }
                if index == data_["battles"].count - 1 {
                    self.rightButton.isEnabled = false
                    self.rightrightButton.isEnabled = false
                } else {
                    self.rightButton.isEnabled = true
                    self.rightrightButton.isEnabled = true
                }
            }
        } else {
            detailViewTopConstraint.constant = 0
        }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
            self.battleNavigationView.alpha = self.battle != nil ? 1.0 : 0.0
        }
    }

    @IBAction func detailRemoveButtonPushed(_ sender: UIButton) {
        updateBattle(newBattle: nil)
    }
    
    @IBAction func detailHeaderPanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            detailHeaderBeganTop = detailViewTopConstraint.constant
        case .changed:
            let point: CGPoint = sender.translation(in: sender.view)
            if detailViewTopConstraint.constant == detailHeaderBeganTop + point.y {
                showDetailHeader = !showingDetail
            } else {
                showDetailHeader = detailViewTopConstraint.constant >= detailHeaderBeganTop + point.y
            }
            detailViewTopConstraint.constant = detailHeaderBeganTop + point.y
            self.view.layoutIfNeeded()
        case .ended:
            if showDetailHeader {
                detailViewTopConstraint.constant = -self.view.frame.height / 2
                showingDetail = true
            } else {
                detailViewTopConstraint.constant = -60
                showingDetail = false
            }
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            break
        default:
            break
        }
    }
    
    @IBAction func navigationButtonPushed(_ sender: UIButton) {
        guard let data_ = data else {
            return
        }
        guard let battle_ = battle else {
            return
        }
        var index: Int = 0
        if sender == leftleftButton {
            index = 0
        } else if sender == rightrightButton {
            index = data_["battles"].count - 1
        } else {
            for battle in data_["battles"] {
                if battle_["uri"] == battle.1["uri"] {
                    index = Int(battle.0)!
                    break
                }
            }
            if sender == leftButton {
                index -= 1
            } else if sender == rightButton {
                index += 1
            }
        }
        let newBattle = data_["battles"][index]
        guard let marker = markers[newBattle["uri"].stringValue] else {
            return
        }
        mapView.animate(to: GMSCameraPosition.camera(withTarget: marker.position, zoom: 4))
        updateBattle(newBattle: newBattle)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let newBattle = marker.userData as! JSON
        updateBattle(newBattle: newBattle)
        return true
    }

    @IBAction func detailViewTapped(_ sender: Any) {
        if !showingDetail {
            detailViewTopConstraint.constant = -self.view.frame.height / 2
            showingDetail = true
        } else {
            detailViewTopConstraint.constant = -60
            showingDetail = false
        }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

