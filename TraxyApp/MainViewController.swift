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
        
//        let model = JournalModel()
//        self.journals = model.getJournals()
//        self.sortIntoSections(journals: self.journals!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // unregister from listeners here.
        if let r = self.ref {
            r.removeAllObservers()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    



    fileprivate func registerForFireBaseUpdates()
    {
        
        self.ref!.child(self.userId!).observe(.value, with: { [weak self] snapshot in
            guard let strongSelf = self else { return }
            
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
                    var coverPhotoUrl = entry["coverPhotoUrl"] as! String?

                    
                    // if no photo is marked as cover, we will use first photo, if any.
                    if coverPhotoUrl == nil || coverPhotoUrl == "" {
                        if let entries = entry["entries"] as? [String : AnyObject] {
                            for (_,val) in entries.enumerated() {
                                let entry = val.1 as! Dictionary<String,AnyObject>
                                print ("entry=\(entry)")
                                let typeRaw = entry["type"] as! Int?
                                let type = EntryType(rawValue: typeRaw!)
                                if type == .photo {
                                    let url : String? = entry["url"] as! String?
                                    coverPhotoUrl = url
                                    print("Will use \(url) as assumed cover photo")
                                    break
                                }

                            }
                        }
                    }
                    
                    tmpItems.append(Journal(key: key, name: name, location: location, startDate: startDateStr?.dateFromISO8601, endDate: endDateStr?.dateFromISO8601, lat: lat, lng: lng, placeId: placeId, coverPhotoUrl: coverPhotoUrl))
                    
                }
                strongSelf.journals = tmpItems
                strongSelf.sortIntoSections(journals: strongSelf.journals!)
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
            }
         }
     }
}



