//
//  PopooverViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/20.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import SwiftyJSON
import SafariServices

protocol PopoverViewControllerDelegate : class {
    func popoverViewControllerDeselect(vc: UIViewController)
}


class PopoverViewController: UIViewController {
    
    var data: JSON?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var abstractTextView: UITextView!
    @IBOutlet weak var abstractTextViewHeight: NSLayoutConstraint!
    
    weak var delegate: PopoverViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        if let data_ = data {
            self.titleLabel.text = data_["label"].stringValue
            self.abstractTextView.text = data_["abstract"].stringValue
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let calcTextViewHeight = self.abstractTextView.sizeThatFits(CGSize(width: self.abstractTextView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        self.abstractTextViewHeight.constant = calcTextViewHeight
        self.view.layoutIfNeeded()
    }
    
    @IBAction func closeButtonPushed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let calcTextViewHeight = self.abstractTextView.sizeThatFits(CGSize(width: self.abstractTextView.frame.width, height: CGFloat.greatestFiniteMagnitude)).height
        if self.abstractTextViewHeight.constant != calcTextViewHeight {
            self.abstractTextViewHeight.constant = calcTextViewHeight
            self.view.layoutIfNeeded()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func wikipediaButtonPushed(_ sender: UIButton) {
        if let data_ = data {
            let safari = SFSafariViewController.init(url: URL.init(string: data_["uri"].stringValue)!)
            safari.modalPresentationStyle = .overFullScreen
            safari.modalTransitionStyle = .coverVertical
            present(safari, animated: true, completion: nil)
        }
    }
    @IBAction func deselectButtonPushed(_ sender: UIButton) {
        delegate?.popoverViewControllerDeselect(vc: self)
    }
    @IBAction func ccBySAButtonPushed(_ sender: Any) {
        UIApplication.shared.open(URL.init(string: "https://creativecommons.org/licenses/by-sa/3.0/")!, options: [:], completionHandler: nil)
    }
    
}
