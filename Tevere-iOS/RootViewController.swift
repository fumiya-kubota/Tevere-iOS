//
//  RootViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/18.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON
import SwiftDate
import RxSwift
import RxCocoa


enum TabBarItemTag: Int {
    case Age = 1
    case Battle = 2
    case Search = 3
}

func tevereURL(year: Int, singleYear: Bool) -> String {
    if singleYear {
        return "https://tevere.cc/api/tevere?from=\(year)&to=\(year)"
    }
    return "https://tevere.cc/api/tevere?from=\(year)&to=\(year + 9)"
}

class RootViewController: UIViewController, GMSMapViewDelegate, UITabBarDelegate {
    // const
    let SHOW_DETAIL_LESS: CGFloat = -90.0
    let SHOW_DETAIL_MORE: CGFloat = -UIScreen.main.bounds.height * 5 / 10
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var leftleftButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var rightrightButton: UIButton!
    @IBOutlet weak var ageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var battleViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var ageItem: UITabBarItem!
    @IBOutlet weak var battleItem: UITabBarItem!
    @IBOutlet weak var searchItem: UITabBarItem!
    @IBOutlet weak var battleTitleLabel: UILabel!
    // Age
    @IBOutlet weak var ageSlider: UISlider!
    @IBOutlet weak var ageSwitch: UISwitch!
    @IBOutlet weak var ageLeftButton: UIButton!
    @IBOutlet weak var ageRightButton: UIButton!
    // Resources
    let redMakerIcon = GMSMarker.markerImage(with: .red)
    let blueMakerIcon = GMSMarker.markerImage(with: .blue)
    
    // entities
    var data: JSON? = nil
    var battle: JSON? = nil
    var markers: [String: GMSMarker] = [:]
    
    // states
    var selectingTab: TabBarItemTag? = TabBarItemTag.Age

    // fetch
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        battleViewTopConstraint.constant = 0
        
        let camera = GMSCameraPosition.camera(withLatitude: 41.89083333333333, longitude: 12.477222222222222, zoom: 3.2)
        mapView.camera = camera
        mapView.delegate = self

        let jsonStream = PublishSubject<JSON>()
        jsonStream.subscribe(onNext: {[weak self] (data) in
            self?.updateData(data: data)
        }).disposed(by: disposeBag)
        let ageStream = Observable.combineLatest(
            ageSlider.rx.value.distinctUntilChanged().asObservable(),
            ageSwitch.rx.value.distinctUntilChanged().asObservable())
            .map { (age, single) -> (Int, Bool) in
                if single {
                    return (Int(age), single)
                } else {
                    return (Int(age) / 10 * 10, single)
                }
            }.distinctUntilChanged { (a, b) -> Bool in
                return a.0 == b.0 && a.1 == b.1
        }
        ageStream.map { (age, single) -> String in
            let s: String
            if (single) {
                s = "年"
            } else {
                s = "年代"
            }
            let string: String
            if (age < 0) {
                string = "\("紀元前")\(-age)\(s)"
            } else {
                string = "\("西暦")\(age)\(s)"
            }
            return string
        }.bind(to: self.rx.title).disposed(by: disposeBag)
        
        ageStream.debounce(0.3, scheduler: MainScheduler.instance).subscribe(onNext: { (age, single) in
            print(age, single)
            let url: String = tevereURL(year: age, singleYear: single)
            Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseJSON{ response in
            switch response.result {
                case .success:
                    let json:JSON = JSON(response.result.value ?? kill)
                    jsonStream.onNext(json)
                case .failure(let error):
                    print(error)
                }
            }
        }).disposed(by: disposeBag)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBar.selectedItem = self.ageItem
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
            marker.icon = redMakerIcon
            marker.zIndex = 1
            marker.map = mapView
        }
        for marker in markers.values {
            marker.map = nil
        }
        if let battle_ = self.battle {
            if newMarkers[battle_["uri"].stringValue] == nil {
                self.battle = nil
            }
        }
        if battles.count == 0 {
            leftleftButton.isEnabled = false
            leftButton.isEnabled = false
            rightButton.isEnabled = false
            rightrightButton.isEnabled = false
        } else {
            leftleftButton.isEnabled = true
            leftButton.isEnabled = true
            rightButton.isEnabled = true
            rightrightButton.isEnabled = true
        }
        markers = newMarkers
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let itemTag = TabBarItemTag(rawValue: item.tag) {
            ageViewTopConstraint.constant = 0
            battleViewTopConstraint.constant = 0
            if selectingTab != itemTag {
                switch itemTag {
                case .Age:
                    ageViewTopConstraint.constant = -60
                case .Battle:
                    battleViewTopConstraint.constant = SHOW_DETAIL_LESS
                    break
                case .Search:
                    break
                }
                selectingTab = itemTag
                tabBar.selectedItem = item
            } else {
                selectingTab = nil
                tabBar.selectedItem = nil
            }
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }

    func updateBattle(newBattle: JSON?) {
        if let battle_ = self.battle {
            if let marker = self.markers[battle_["uri"].stringValue] {
                marker.icon = redMakerIcon
                marker.zIndex = 1
            }
        }
        battle = newBattle
        if let battle_ = battle {
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
            ageViewTopConstraint.constant = 0
            battleViewTopConstraint.constant = SHOW_DETAIL_LESS
            showingDetail = false
            tabBar.selectedItem = battleItem
            selectingTab = TabBarItemTag.Battle
            battleTitleLabel.text = battle_["label"].stringValue
        } else {
            battleViewTopConstraint.constant = 0
            tabBar.selectedItem = nil
            selectingTab = nil
        }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
            if let battle_ = self.battle {
                if let marker = self.markers[battle_["uri"].stringValue] {
                    marker.icon = self.blueMakerIcon
                    marker.zIndex = 100
                }
            }
        }
    }

    @IBAction func navigationButtonPushed(_ sender: UIButton) {
        guard let data_ = data else {
            return
        }
        var index: Int = 0
        if sender == leftleftButton {
            index = 0
        } else if sender == rightrightButton {
            index = data_["battles"].count - 1
        } else {
            if let battle_ = battle {
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
            } else {
                index = 0
            }
        }
        let newBattle = data_["battles"][index]
        guard let marker = markers[newBattle["uri"].stringValue] else {
            return
        }
        mapView.animate(toLocation: marker.position)
        updateBattle(newBattle: newBattle)
    }
    
    var battleHeaderBeganTop: CGFloat = 0
    var showDetailHeader = false
    var showingDetail = false
    
    var displayLink: CADisplayLink? = nil
    
    @IBAction func battleViewHeaderPanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            battleHeaderBeganTop = battleViewTopConstraint.constant
            displayLink = CADisplayLink.init(target: self, selector: #selector(moveBattleView))
        case .changed:
            let point: CGPoint = sender.translation(in: sender.view)
            if battleViewTopConstraint.constant == battleHeaderBeganTop + point.y {
                showDetailHeader = !showingDetail
            } else {
                showDetailHeader = battleViewTopConstraint.constant >= battleHeaderBeganTop + point.y
            }
            battleViewTopConstraint.constant = battleHeaderBeganTop + point.y
        case .ended:
            displayLink?.invalidate()
            displayLink = nil
            if showDetailHeader {
                battleViewTopConstraint.constant = SHOW_DETAIL_MORE
                showingDetail = true
            } else {
                battleViewTopConstraint.constant = SHOW_DETAIL_LESS
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
   
    @IBAction func detailViewTapped(_ sender: Any) {
        if !showingDetail {
            battleViewTopConstraint.constant = SHOW_DETAIL_MORE
            showingDetail = true
        } else {
            battleViewTopConstraint.constant = SHOW_DETAIL_LESS
            showingDetail = false
        }
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func moveBattleView() {
        self.view.layoutIfNeeded()
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let newBattle = marker.userData as! JSON
        updateBattle(newBattle: newBattle)
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tabBar.invalidateIntrinsicContentSize()
        self.tabBar.layoutIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
