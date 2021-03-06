//
//  SearchResultTableViewController.swift
//  Tevere-iOS
//
//  Created by Fumiya-Kubota on 2018/06/21.
//  Copyright © 2018年 sasau. All rights reserved.
//

import UIKit
import SwiftyJSON

class BattleCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var abstractTextView: UITextView!
    @IBOutlet weak var metaLabel: UILabel!
    
}

class CommanderCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var abstractTextView: UITextView!
    @IBOutlet weak var metaLabel: UILabel!
    
}


class SearchResultTableViewController: UITableViewController {
    
    var searchResult: JSON? = nil
    let formatter = DateFormatter()
    var calendar = Calendar(identifier: .gregorian)
    let locale = Locale.init(identifier: Locale.preferredLanguages.first!)
    let timeZone = TimeZone.init(identifier: "UTC")!
    override func viewDidLoad() {
        super.viewDidLoad()
        calendar.timeZone = timeZone
        formatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "Gy",
            options: 0,
            locale: locale)
        
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
        let result = searchResult!["result"]
        let data: JSON
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Commander", for: indexPath) as! CommanderCell
            data = result["commanders"][indexPath.row]
            let battles = data["battles"].intValue
            cell.titleLabel.text = data["label"].stringValue
            cell.abstractTextView.text = data["abstract"].stringValue
            cell.metaLabel.text = "\(battles)"
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Battle", for: indexPath) as! BattleCell
            data = result["battles"][indexPath.row]
            let year = data["dates"][0]["year"].intValue
            let dateComponents = DateComponents.init(calendar: calendar, timeZone: timeZone, year: year <= 0 ? year + 1 : year)
            let date = dateComponents.date!
            cell.titleLabel.text = data["label"].stringValue
            cell.abstractTextView.text = data["abstract"].stringValue
            cell.metaLabel.text = formatter.string(from: date)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("Commanders", comment: "Commanders")
        } else if section == 1 {
            return NSLocalizedString("Battles", comment: "Battles")
        }
        return nil
    }
}
