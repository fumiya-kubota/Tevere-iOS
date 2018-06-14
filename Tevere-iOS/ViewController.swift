//
//  ViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/12.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {

    @IBOutlet weak var mapView: GMSMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera = GMSCameraPosition.camera(withLatitude: 41.89083333333333, longitude: 12.477222222222222, zoom: 5.0)
        self.mapView.camera = camera
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

