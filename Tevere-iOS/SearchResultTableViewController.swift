//
//  SearchResultTableViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/21.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import SwiftyJSON

class SearchResultCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var abstractTextView: UITextView!
    
}

class SearchResultTableViewController: UITableViewController {
    
    var searchResult: JSON? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResult!["result"]
        let nc: SearchNavigationController = self.navigationController as! SearchNavigationController
        if indexPath.section == 0 {
            let commander = result["commanders"][indexPath.row]
            nc.selectCommander(commander: commander, data: searchResult!)
        } else {
            let battle = result["battles"][indexPath.row]
            nc.selectBattle(battle: battle, data: searchResult!)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let result = searchResult!["result"]
        if section == 0 {
            return result["commanders"].count
        } else if section == 1 {
            return result["battles"].count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SearchResultCell
        let result = searchResult!["result"]
        let data: JSON
        if indexPath.section == 0 {
            data = result["commanders"][indexPath.row]
        } else {
            data = result["battles"][indexPath.row]
        }
        cell.titleLabel.text = data["label"].stringValue
        cell.abstractTextView.text = data["abstract"].stringValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "司令官"
        } else if section == 1 {
            return "戦い"
        }
        return nil
    }
}
