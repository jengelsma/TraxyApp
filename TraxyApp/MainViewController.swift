//
//  MainViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/7/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Kingfisher

class MainViewController: TraxyTopLevelViewController, UITableViewDataSource, UITableViewDelegate, AddJournalDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var tableViewData: [(sectionHeader: String, journals: [Journal])]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let model = JournalModel()
//        self.journals = model.getJournals()
//        self.sortIntoSections(journals: self.journals!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func logoutFromNavStack(segue: UIStoryboardSegue) {
        // we end up here when a downstream child we pushed to detects no user session
        print("reset main's nav stack to top")
    }
    
    override func journalsDidLoad() {
        if let j = self.journals {
            self.sortIntoSections(journals: j)
        } else {
            self.tableViewData?.removeAll()
        }
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
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "FancyCell", for: indexPath) as! TraxyMainTableViewCell
        
        guard let journal = tableViewData?[indexPath.section].journals[indexPath.row] else {
            return cell
        }
        
        cell.name?.text = journal.name
        cell.subName?.text = journal.location
        
        if let coverUrl = journal.coverPhotoUrl {
            let url = URL(string: coverUrl)
            cell.coverImage?.kf.indicatorType = .activity
            cell.coverImage?.kf.setImage(with: url)
        } else {
            cell.coverImage?.image = UIImage(named: "landscape")
        }
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

    // MARK: - AddJournalDelegate
    func save(journal: Journal) {
        let newChild = self.ref?.child(self.userId!).childByAutoId()
        newChild?.setValue(self.toDictionary(vals: journal))
        
        //self.journals?.append(journal)
        //self.sortIntoSections(journals: self.journals!)
    }

    func toDictionary(vals: Journal) -> NSDictionary {

        return [
            "name": vals.name! as NSString,
            "address": vals.location! as NSString,
            "startDate" : NSString(string: (vals.startDate?.iso8601)!) ,
            "endDate": NSString(string: (vals.endDate?.iso8601)!),
            "lat" : NSNumber(value: vals.lat!),
            "lng" : NSNumber(value: vals.lng!),
            "placeId" : vals.placeId! as NSString
        ]
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addJournalSegue" {
            if let destVC = segue.destination as? AddJournalViewController {
                destVC.delegate = self
            }
        } else if segue.identifier == "showJournalSegue" {
            if let destVC = segue.destination as? JournalTableViewController {
                let indexPath = self.tableView.indexPathForSelectedRow
                let values = self.tableViewData?[indexPath!.section]
                destVC.journal  = values?.journals[indexPath!.row]
                destVC.userId = self.userId
            }
         }
     }
}



