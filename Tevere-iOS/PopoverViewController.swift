//
//  PopooverViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/20.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol PopoverViewControllerDelegate : class {
    func popoverViewControllerDeselect(vc: PopoverViewController)
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
    
    @IBAction func deselectButtonPushed(_ sender: UIButton) {
        delegate?.popoverViewControllerDeselect(vc: self)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
