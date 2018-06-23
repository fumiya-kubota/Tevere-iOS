//
//  SearchWordViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/21.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire
import SwiftyJSON


enum UserDefaultsDomain: String {
    case SearchHistory = "cc.tevere.search.history"
}

class SearchWordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var tableViewBottomMargin: NSLayoutConstraint!
    var searchResult: JSON? = nil
    var searchHistory: [String]
    var searchText: String? = nil
    
    required init?(coder aDecoder: NSCoder) {
        let userDefaults = UserDefaults.standard
        if let searchHistory = userDefaults.array(forKey: UserDefaultsDomain.SearchHistory.rawValue) {
            self.searchHistory = searchHistory as! [String]
        } else {
            searchHistory = []
        }
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.searchBar.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboradWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboradWillHidden(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            searchHistory.remove(at: searchHistory.count - indexPath.row - 1)
            tableView.deleteRows(at: [indexPath], with: .fade)
            let userDefaults = UserDefaults.standard
            userDefaults.set(searchHistory, forKey: UserDefaultsDomain.SearchHistory.rawValue)

        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = searchHistory[searchHistory.count - indexPath.row - 1]
        return cell
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let text = searchBar.text else {
            return
        }
        let searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if searchText.count > 0 {
            search(searchText: searchText)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        search(searchText: searchHistory[searchHistory.count - indexPath.row - 1])
    }
    
    func search(searchText: String) {
        var searchHistory = self.searchHistory
        if let index = searchHistory.index(of: searchText) {
            searchHistory.remove(at: index)
        }
        searchHistory.append(searchText)
        while searchHistory.count > 30 {
            searchHistory.removeFirst()
        }
        self.searchText = searchText
        self.searchHistory = searchHistory
        let userDefaults = UserDefaults.standard
        userDefaults.set(self.searchHistory, forKey: UserDefaultsDomain.SearchHistory.rawValue)
        self.tableView.reloadData()
        SVProgressHUD.show()
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        let url = "https://tevere.cc/api/search?text=\(encodedText!)"
        Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseJSON{ response in
            switch response.result {
            case .success:
                let data:JSON = JSON(response.result.value ?? kill)
                self.searchResult = data
                SVProgressHUD.dismiss()
                self.performSegue(withIdentifier: "result", sender: nil)
            case .failure(let error):
                print(error)
                SVProgressHUD.showError(withStatus: "Error")
                SVProgressHUD.dismiss(withDelay: 0.5)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let searchResultViewConroller:SearchResultTableViewController = segue.destination as! SearchResultTableViewController
        searchResultViewConroller.title = self.searchText
        searchResultViewConroller.searchResult = searchResult
    }
    
    
    
    @objc func keyboradWillShow(sender: NSNotification) {
        let keyboardFrame = (sender.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = (sender.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval)
        let curve = UIViewAnimationCurve.init(rawValue: sender.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! Int)
        UIView.beginAnimations("keyboardWillShow", context: nil)
        UIView.setAnimationCurve(curve!)
        UIView.setAnimationDuration(duration)
        tableViewBottomMargin.constant = keyboardFrame.height
        self.view.layoutIfNeeded()
        UIView.commitAnimations()
    }
    
    @objc func keyboradWillHidden(sender: NSNotification) {
        tableViewBottomMargin.constant = 0
        self.view.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButtonPushed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}
