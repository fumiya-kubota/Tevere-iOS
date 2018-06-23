//
//  CommanderPopoverViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/23.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import SwiftyJSON

class SubjectPopoverViewController: UIViewController {
    var data: JSON?

    @IBOutlet weak var titleLabel: UILabel!
    weak var delegate: PopoverViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let data_ = data {
            self.titleLabel.text = data_["label"].stringValue
        }
    }
    @IBAction func deselectButtonPushed(_ sender: UIButton) {
        delegate?.popoverViewControllerDeselect(vc: self)

    }
    @IBAction func closeButtonPushed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
