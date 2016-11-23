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

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddJournalDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var userEmail : String?
    var journals : [Journal]?
    
    fileprivate var ref : FIRDatabaseReference?
    fileprivate var userId : String? = ""
    
    var tableViewData: [(sectionHeader: String, journals: [Journal])]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let model = JournalModel()
        self.journals = model.getJournals()
        self.sortIntoSections(journals: self.journals!)
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                self.userId = user.uid
                self.ref = FIRDatabase.database().reference()
                self.registerForFireBaseUpdates()
            } else {
                // No user is signed in.
                self.performSegue(withIdentifier: "logoutSegue", sender: self)
            }
        }
        

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    



    fileprivate func registerForFireBaseUpdates()
    {
        
        self.ref!.child(self.userId!).observe(.value, with: { snapshot in
            
            if let postDict = snapshot.value as? [String : AnyObject] {
                var tmpItems = [Journal]()
                for (_,val) in postDict.enumerated() {
                    //print("key = \(key) and val = \(val)")
                    let entry = val.1 as! Dictionary<String,AnyObject>
                    print ("entry=\(entry)")
                    let key = val.0
                    let name : String? = entry["name"] as! String?
                    let location : String?  = entry["address"] as! String?
                    let startDateStr  = entry["startDate"] as! String?
                    let endDateStr = entry["endDate"] as! String?
                    let lat = entry["lat"] as! Double?
                    let lng = entry["lng"] as! Double?
                    let placeId = entry["placeId"] as! String?
                    tmpItems.append(Journal(key: key, name: name, location: location, startDate: startDateStr?.dateFromISO8601, endDate: endDateStr?.dateFromISO8601, lat: lat, lng: lng, placeId: placeId))
                }
                self.journals = tmpItems
                self.sortIntoSections(journals: self.journals!)
            }
        })
        
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
            "lat" : NSNumber(value: 0.0),
            "lng" : NSNumber(value: 0.0),
            "placeId" : vals.placeId! as NSString
        ]
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addJournalSegue" {
            if let destVC = segue.destination as? AddJournalViewController {
                destVC.delegate = self
            }
        }
    }
}



