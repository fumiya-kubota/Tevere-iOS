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
import RxSwift
import RxCocoa
import SafariServices


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

class RootViewController: UIViewController, GMSMapViewDelegate, UITabBarDelegate, UIPopoverPresentationControllerDelegate, PopoverViewControllerDelegate, SearchNavicationControllerDelegate {
    
    // const
    let SHOW_DETAIL_LESS: CGFloat = -90.0
    let SHOW_DETAIL_MORE: CGFloat = -UIScreen.main.bounds.height / 2
    
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
    
    // battle
    @IBOutlet weak var battleScrollView: UIScrollView!
    @IBOutlet weak var battleTitleLabel: UILabel!
    @IBOutlet weak var datesStackView: UIStackView!
    @IBOutlet weak var datesStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var battleAbstractTextView: UITextView!
    @IBOutlet weak var battleAbstractTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var commanderStackView: UIStackView!
    @IBOutlet weak var commanderStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var categoryStackView: UIStackView!
    @IBOutlet weak var categoryStackViewHeight: NSLayoutConstraint!

    // Fetch Data
    @IBOutlet weak var ageSlider: UISlider!
    let age = BehaviorRelay<Int>(value: ArchivedData.shared.year)
    let single = BehaviorRelay<Bool>(value: false)
    @IBOutlet weak var ageSwitch: UISwitch!
    @IBOutlet weak var ageLeftButton: UIButton!
    @IBOutlet weak var ageRightButton: UIButton!
    let commander = BehaviorRelay<JSON?>(value: nil)
    let subject = BehaviorRelay<JSON?>(value: nil)
    
    let ageResult = BehaviorRelay<JSON?>(value: nil)
    let commanderResult = BehaviorRelay<JSON?>(value: nil)
    let subjectResult = BehaviorRelay<JSON?>(value: nil)
    @IBOutlet var commanderTitleButton: UIButton!
    @IBOutlet var subjectTitleButton: UIButton!
    
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
    
    // layout states
    var battleHeaderBeganTop: CGFloat = 0
    var showDetailHeader = false
    var showingDetail = false
    
    var displayLink: CADisplayLink? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        battleViewTopConstraint.constant = 0
        let camera = GMSCameraPosition.camera(
            withLatitude: ArchivedData.shared.lat,
            longitude: ArchivedData.shared.lng,
            zoom: ArchivedData.shared.zoom)
        mapView.camera = camera
        mapView.delegate = self
        age.subscribe(onNext: { (age) in
            ArchivedData.shared.updateYear(year: age)
        }).disposed(by: disposeBag)

        age.map({ (val) -> Float in
            return Float(val)
        }).bind(to: ageSlider.rx.value).disposed(by: disposeBag)

        ageSlider.rx.value.distinctUntilChanged().map({ (val) -> Int in
            return Int(val)
        }).bind(to: age).disposed(by: disposeBag)
        ageSwitch.rx.value.distinctUntilChanged().bind(to: single).disposed(by: disposeBag)
        
        single.map {[weak self] (val) -> Int in
            guard let self_ = self else {
                return 0
            }
            return val ? self_.age.value / 10 * 10 : self_.age.value
        }.bind(to: age).disposed(by: disposeBag)
        single.bind(to: ageSwitch.rx.value).disposed(by: disposeBag)
        
        let ageStream = Observable.combineLatest(
            age,
            single
        ).map { (age, single) -> (Int, Bool) in
            if single {
                return (Int(age), single)
            } else {
                return (Int(age) / 10 * 10, single)
            }
        }.distinctUntilChanged { (a, b) -> Bool in
            return a.0 == b.0 && a.1 == b.1
        }
        
        // ナビゲーションのタイトル
        var calendar = Calendar(identifier: .gregorian)
        let timeZone = TimeZone.init(identifier: "UTC")!
        calendar.timeZone = timeZone
        let locale = Locale.init(identifier: Locale.preferredLanguages.first!)
        let f = DateFormatter()
        f.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "Gy",
            options: 0,
            locale: locale)
        f.timeZone = timeZone

        ageStream.map { (age, single) -> String in
            let dateComponents = DateComponents.init(calendar: calendar, timeZone: timeZone, year: age <= 0 ? age + 1 : age)
            let date = dateComponents.date
            let dateString = f.string(from: date!)
            return single ? dateString : "\(dateString)s"
        }.subscribe(onNext: {[weak self] (title) in
            guard let self_ = self else {
                return
            }
            self_.navigationItem.titleView = nil
            self_.title = title
        }).disposed(by: disposeBag)
        commander.asObservable().map { (commanderData) -> String? in
            guard let data = commanderData else {
                return nil
            }
            return data["label"].stringValue
        }.subscribe(onNext: {[weak self] (title) in
            guard let self_ = self else {
                return
            }
            guard let title_ = title else {
                self_.navigationItem.titleView = nil
                return
            }
            self_.commanderTitleButton.setTitle(title_, for: .normal)
            self_.navigationItem.titleView = self_.commanderTitleButton
        }).disposed(by: disposeBag)
        subject.asObservable().map { (subjectData) -> String? in
            guard let data = subjectData else {
                return nil
            }
            return data["label"].stringValue
        }.subscribe(onNext: {[weak self] (title) in
            guard let self_ = self else {
                return
            }
            guard let title_ = title else {
                self_.navigationItem.titleView = nil
                return
            }
            self_.subjectTitleButton.setTitle(title_, for: .normal)
            self_.navigationItem.titleView = self_.subjectTitleButton
        }).disposed(by: disposeBag)
        
        // Data Fetch
        Observable<JSON?>.merge([ageResult.asObservable(), commanderResult.asObservable(), subjectResult.asObservable()]).filter { (data) -> Bool in
            return data != nil
        }.map { (data) -> JSON in
            return data!
        }.subscribe(onNext: {[weak self] (data) in
            self?.updateData(data: data)
        }).disposed(by: disposeBag)
        
        ageLeftButton.rx.controlEvent(UIControlEvents.touchUpInside).map {[weak self] _ -> Int in
            guard let self_ = self else {
                return 0
            }
            return self_.single.value ? self_.age.value - 1 : self_.age.value - 10
        }.subscribe(onNext: {[weak self] value in
            self?.age.accept(value)
        }).disposed(by: disposeBag)
        ageRightButton.rx.controlEvent(UIControlEvents.touchUpInside).map {[weak self] _ -> Int in
            guard let self_ = self else {
                return 0
            }
            return self_.single.value ? self_.age.value + 1 : self_.age.value + 10
        }.subscribe(onNext: {[weak self] value in
            self?.age.accept(value)
        }).disposed(by: disposeBag)
        
        ageStream.debounce(0.3, scheduler: MainScheduler.instance).subscribe(onNext: {[weak self] (age, single) in
            guard let self_ = self else {
                return
            }
            let url: String = tevereURL(year: age, singleYear: single)
            Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseJSON{ response in
            switch response.result {
                case .success:
                    let json:JSON = JSON(response.result.value ?? kill)
                    self_.ageResult.accept(json)
                case .failure(let error):
                    print(error)
                }
            }
        }).disposed(by: disposeBag)
        
        commander.subscribe(onNext: {[weak self] (data) in
            guard let self_ = self else {
                return
            }
            guard let data_ = data else {
                self_.ageResult.accept(self_.ageResult.value)
                return
            }
            let commanderURI = data_["uri"].stringValue
            let encoded = commanderURI.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            let url = "https://tevere.cc/api/tevere?commander=\(encoded)"
            Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseJSON{ response in
                switch response.result {
                case .success:
                    let json:JSON = JSON(response.result.value ?? kill)
                    self_.commanderResult.accept(json)
                case .failure(let error):
                    print(error)
                }
            }
        }).disposed(by: disposeBag)
        
        subject.subscribe(onNext: {[weak self]  (data) in
            guard let self_ = self else {
                return
            }
            guard let data_ = data else {
                self_.ageResult.accept(self_.ageResult.value)
                return
            }
            let subjectURI = data_["uri"].stringValue
            let encoded = subjectURI.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            let url = "https://tevere.cc/api/tevere?subject=\(encoded)"
            Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseJSON{ response in
                switch response.result {
                case .success:
                    let json:JSON = JSON(response.result.value ?? kill)
                    self_.subjectResult.accept(json)
                case .failure(let error):
                    print(error)
                }
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let tab = selectingTab {
            switch tab {
            case .Age:
                tabBar.selectedItem = ageItem
            case .Battle:
                tabBar.selectedItem = battleItem
            default:
                tabBar.selectedItem = nil
            }
        }
    }
    
    @IBAction func commanderTitleButtonPushed(_ sender: UIButton) {
        guard let commander_ = commander.value else {
            return
        }
        if let vc: PopoverViewController = self.storyboard?.instantiateViewController(withIdentifier: "commander-popover") as! PopoverViewController? {
            vc.data = commander_
            vc.delegate = self
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = sender
            vc.popoverPresentationController?.sourceRect = sender.frame
            vc.popoverPresentationController?.delegate = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func subjectTitleButtonPushed(_ sender: UIButton) {
        guard let subject_ = subject.value else {
            return
        }
        if let vc: SubjectPopoverViewController = self.storyboard?.instantiateViewController(withIdentifier: "subject-popover") as! SubjectPopoverViewController? {
            vc.data = subject_
            vc.delegate = self
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = sender
            vc.popoverPresentationController?.sourceRect = sender.frame
            vc.popoverPresentationController?.delegate = self
            vc.preferredContentSize = CGSize(width: 320, height: 100.0)
            present(vc, animated: true, completion: nil)
        }
    }
    
    func popoverViewControllerDeselect(vc: UIViewController) {
        vc.dismiss(animated: true, completion: nil)
        self.navigationItem.titleView = nil
        ageResult.accept(ageResult.value)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
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
        if !searchingBattle && selectingTab == TabBarItemTag.Battle {
            battleScrollView.contentOffset = CGPoint.zero
            battleScrollView.isScrollEnabled = false
            tabBar.selectedItem = nil
            selectingTab = nil
            battleViewTopConstraint.constant = 0
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        searchingBattle = false
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let itemTag = TabBarItemTag(rawValue: item.tag) {
            if itemTag == TabBarItemTag.Battle {
                if let tab = selectingTab {
                    switch tab {
                    case .Age:
                        tabBar.selectedItem = ageItem
                    default:
                        tabBar.selectedItem = nil
                    }
                }

                if selectingTab == TabBarItemTag.Battle {
                    battleViewTopConstraint.constant = 0
                    selectingTab = nil
                    UIView.animate(withDuration: 0.2) {
                        self.view.layoutIfNeeded()
                    }
                    return
                }
                if self.battle == nil {
                    if let data_ = data {
                        if data_["battles"][0] != JSON.null {
                            let battle = data_["battles"][0]
                            if let marker = markers[battle["uri"].stringValue] {
                                mapView.animate(toLocation: marker.position)
                            }
                            tabBar.selectedItem = battleItem
                            ageViewTopConstraint.constant = 0
                            selectingTab = TabBarItemTag.Battle
                            updateBattle(newBattle: battle)
                        }
                    }
                } else {
                    ageViewTopConstraint.constant = 0
                    battleViewTopConstraint.constant = SHOW_DETAIL_LESS
                    tabBar.selectedItem = battleItem
                    selectingTab = TabBarItemTag.Battle
                    UIView.animate(withDuration: 0.2) {
                        self.view.layoutIfNeeded()
                    }
                }
                return
            }
            if itemTag == TabBarItemTag.Search {
                if let tab = selectingTab {
                    switch tab {
                    case .Age:
                        tabBar.selectedItem = ageItem
                    case .Battle:
                        tabBar.selectedItem = battleItem
                    default:
                        tabBar.selectedItem = nil
                    }
                }
                if let search: SearchNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "search") as? SearchNavigationController {
                    search.searchNavigationContolloerDelegate = self
                    self.present(search, animated: true, completion: nil)
                }
                return
            }

            ageViewTopConstraint.constant = 0
            battleViewTopConstraint.constant = 0
            
            if selectingTab != itemTag {
                switch itemTag {
                case .Age:
                    ageViewTopConstraint.constant = -60
                    selectingTab = itemTag
                    tabBar.selectedItem = item
                default:
                    break
                }
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
            self.battleScrollView.contentOffset = CGPoint.zero
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
            lessBattleView()
            tabBar.selectedItem = battleItem
            selectingTab = TabBarItemTag.Battle
            
            battleTitleLabel.text = battle_["label"].stringValue
            for subview in self.datesStackView.subviews {
                subview.removeFromSuperview()
            }
            var calendar = Calendar(identifier: .gregorian)
            let timeZone = TimeZone.init(identifier: "UTC")!
            calendar.timeZone = timeZone
            let locale = Locale.init(identifier: Locale.preferredLanguages.first!)
            let f = DateFormatter()
            f.timeZone = timeZone
            var totalHeight: CGFloat = 0
            for date in battle_["dates"] {
                let button = UIButton.init(type: .system)
                let y = date.1["year"].intValue
                let dateString: String
                if date.1["month"].intValue <= 0 {
                    let dateComponents = DateComponents.init(calendar: calendar, timeZone: timeZone, year: y <= 0 ? y + 1 : y)
                    let date = dateComponents.date
                    f.dateFormat = DateFormatter.dateFormat(
                        fromTemplate: "Gy",
                        options: 0,
                        locale: locale)
                    dateString = f.string(from: date!)
                } else {
                    let m = date.1["month"].intValue
                    let d = date.1["day"].intValue
                    let dateComponents = DateComponents.init(
                        calendar: calendar, timeZone: timeZone,
                        year: y <= 0 ? y + 1 : y, month: m, day: d)
                    let date = dateComponents.date
                    f.dateFormat = DateFormatter.dateFormat(fromTemplate: "GydMMM", options: 0, locale: locale)
                    dateString = f.string(from: date!)
                }
                button.setTitle(dateString, for: .normal)
                button.sizeToFit()
                button.rx.controlEvent(.touchUpInside).asControlEvent().subscribe(onNext: {[weak self] _ in
                    guard let self_ = self else {
                        return
                    }
                    self_.single.accept(true)
                    self_.age.accept(y)
                }).disposed(by: disposeBag)
                totalHeight += button.frame.height - 5
                self.datesStackView.addArrangedSubview(button)
            }
            self.datesStackViewHeight.constant = totalHeight
            
            self.battleAbstractTextView.text = battle_["abstract"].stringValue
            let size = self.battleAbstractTextView.sizeThatFits(CGSize.init(
                width: self.battleAbstractTextView.frame.width, height: CGFloat.greatestFiniteMagnitude))
            self.battleAbstractTextViewHeight.constant = size.height
            if let data_ = data {
                for subview in self.commanderStackView.subviews {
                    subview.removeFromSuperview()
                }
                for subview in self.categoryStackView.subviews {
                    subview.removeFromSuperview()
                }
                totalHeight = 0
                for commander in battle_["commanders"] {
                    let commanderData = data_["commanders"][commander.1.stringValue]
                    let commanderLabel = commanderData["label"].stringValue
                    if commanderLabel.count == 0 {
                        continue
                    }
                    let button = UIButton.init(type: .system)
                    button.setTitle(commanderLabel, for: .normal)
                    button.titleLabel?.numberOfLines = 0
                    button.sizeToFit()
                    button.rx.controlEvent(.touchUpInside).asObservable().subscribe(onNext: {[weak self] _ in
                        if let self_ = self {
                            self_.commander.accept(commanderData)
                        }
                    }).disposed(by: disposeBag)
                    totalHeight += button.frame.height - 5
                    self.commanderStackView.addArrangedSubview(button)
                }
                self.commanderStackViewHeight.constant = totalHeight

                totalHeight = 0
                for commander in battle_["subjects"] {
                    let subjectData = data_["subjects"][commander.1.stringValue]
                    let subjectLabel = subjectData["label"].stringValue
                    if subjectLabel.count == 0 {
                        continue
                    }
                    let button = UIButton.init(type: .system)
                    button.setTitle(subjectLabel, for: .normal)
                    button.titleLabel?.numberOfLines = 0
                    button.sizeToFit()
                    button.rx.controlEvent(.touchUpInside).asObservable().subscribe(onNext: {[weak self] _ in
                        if let self_ = self {
                            self_.subject.accept(subjectData)
                        }
                    }).disposed(by: disposeBag)
                    totalHeight += button.frame.height - 5
                    self.categoryStackView.addArrangedSubview(button)
                }
                self.categoryStackViewHeight.constant = totalHeight
            }
        } else {
            battleViewTopConstraint.constant = 0
            tabBar.selectedItem = nil
            selectingTab = nil
        }
        UIView.animate(withDuration: 0.2) {
            if let battle_ = self.battle {
                if let marker = self.markers[battle_["uri"].stringValue] {
                    marker.icon = self.blueMakerIcon
                    marker.zIndex = 100
                }
            }
            self.view.layoutIfNeeded()
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
                moreBattleView()
            } else {
                lessBattleView()
            }
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            break
        default:
            break
        }
    }
    
    func lessBattleView() {
        showingDetail = false
        battleViewTopConstraint.constant = SHOW_DETAIL_LESS
        battleScrollView.setContentOffset(CGPoint.zero, animated: true)
        battleScrollView.isScrollEnabled = false
    }
    
    func moreBattleView() {
        showingDetail = true
        battleViewTopConstraint.constant = SHOW_DETAIL_MORE
        battleScrollView.isScrollEnabled = true
    }
   
    @IBAction func detailViewTapped(_ sender: Any) {
        if !showingDetail {
            moreBattleView()
        } else {
            lessBattleView()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBar.invalidateIntrinsicContentSize()
        self.tabBar.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tabBar.invalidateIntrinsicContentSize()
        self.tabBar.layoutIfNeeded()
    }

    func searchNC(nc: SearchNavigationController, commander: JSON, data: JSON) {
        nc.dismiss(animated: true, completion: nil)
        self.commander.accept(commander)
    }

    var searchingBattle = false
    func searchNC(nc: SearchNavigationController, battle: JSON, data: JSON) {
        nc.dismiss(animated: true) {
            var resultData = data
            resultData["battles"] = [battle]
            self.updateData(data: resultData)
            let date = battle["dates"][0]
            let year = date["year"].intValue
            if self.age.value == year {
                self.commander.accept(nil)
            } else {
                self.searchingBattle = true
                self.age.accept(date["year"].intValue)
            }
            self.updateBattle(newBattle: battle)

            if let marker = self.markers[battle["uri"].stringValue] {
                self.mapView.animate(toLocation: marker.position)
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        ArchivedData.shared.updatePoint(
            lat: position.target.latitude,
            lng: position.target.longitude,
            zoom: position.zoom)
    }
    @IBAction func wikipediaButtonPushed(_ sender: Any) {
        if let battle_ = battle {
            let safari = SFSafariViewController.init(url: URL.init(string: battle_["uri"].stringValue)!)
            safari.modalPresentationStyle = .overFullScreen
            safari.modalTransitionStyle = .coverVertical
            present(safari, animated: true, completion: nil)
        }
    }
    @IBAction func ccBySAButtonPushed(_ sender: UIButton) {
        UIApplication.shared.open(URL.init(string: "https://creativecommons.org/licenses/by-sa/3.0/")!, options: [:], completionHandler: nil)
        
    }
}
