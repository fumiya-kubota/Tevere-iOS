//
//  SearchNavigationController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/21.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol SearchNavicationControllerDelegate: class {
    func searchNC(nc: SearchNavigationController, commander: JSON, data: JSON)
    func searchNC(nc: SearchNavigationController, battle: JSON, data: JSON)
}

class SearchNavigationController: UINavigationController {
    weak var searchNavigationContolloerDelegate: SearchNavicationControllerDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func selectCommander(commander: JSON, data: JSON) {
        self.searchNavigationContolloerDelegate?.searchNC(nc: self, commander: commander, data: data)
    }

    func selectBattle(battle: JSON, data: JSON) {
        self.searchNavigationContolloerDelegate?.searchNC(nc: self, battle: battle, data: data)
    }
}
