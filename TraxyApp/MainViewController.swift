//
//  MainViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/7/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var userEmail : String?
    var journals : [Journal]?
    
    
    
    var tableViewData: [(sectionHeader: String, journals: [Journal])]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let model = JournalModel()
        self.sortIntoSections(journals: model.getJournals())
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func sortIntoSections(journals: [Journal]) {
        
        // We assume the model already provides them ascending date order.
        
        var currentSection  = [Journal]()
        var futureSection = [Journal]()
        var pastSection = [Journal]()
        
        let today = (Date().short.dateFromShort)!
        for j in journals {
            if today <=  j.endDate! && today >= j.startDate! {
                currentSection.append(j)
            } else if today < j.startDate! {
                futureSection.append(j)
            } else {
                pastSection.append(j)
            }
        }
        
        let cs  = (sectionHeader: "CURRENT", journals: currentSection)
        let fs = (sectionHeader: "FUTURE", journals: futureSection)
        let ps = (sectionHeader: "PAST", journals: pastSection)
        
        self.tableViewData = [cs,fs,ps]
        
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableViewData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewData?[section].journals.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TraxyMainTableViewCell
        
        guard let journal = tableViewData?[indexPath.section].journals[indexPath.row] else {
            return cell
        }
        
        cell.name?.text = journal.name
        cell.subName?.text = journal.location
        cell.coverImage?.image = UIImage(named: "landscape")
        
/*        cell.textLabel?.text = journal.name
        cell.detailTextLabel?.text = journal.location
        if let defaultImage = UIImage(named: "logo") {
            cell.imageView?.image = defaultImage
        }
*/
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.tableViewData?[section].sectionHeader
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = THEME_COLOR2
        header.contentView.backgroundColor = THEME_COLOR3
        //UIColor(red: 0.937, green: 0.820, blue: 0.576, alpha: 1.0)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = THEME_COLOR2
        header.contentView.backgroundColor = THEME_COLOR3        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let journal = tableViewData?[indexPath.section].journals[indexPath.row] else {
            return
        }
        print("Selected \(journal.name)")
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

extension Date {
    struct Formatter {
        static let short: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd-yyyy"
            return formatter
        }()
    }
    
    var short: String {
        return Formatter.short.string(from: self)
    }
}

extension String {

    var dateFromShort: Date? {
        return Date.Formatter.short.date(from: self)
    }
    
}


