//
//  JournalEditorViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/27/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import Eureka

protocol JournalEditorDelegate : class {
    func save(journal: Journal)
}

class JournalEditorViewController: UIViewController {

    var journalForm : AddJournalViewController!
    var coverSelect : CoverPhotoCollectionViewController!
    
    weak var delegate : JournalEditorDelegate?
    var journal : Journal?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.journal == nil {
            self.journal = Journal()
        }
        
        let cancelButton : UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(JournalEditorViewController.cancelPressed))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        let saveButton : UIBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(JournalEditorViewController.savePressed))
        self.navigationItem.rightBarButtonItem = saveButton
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func cancelPressed()
    {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func savePressed()
    {
        
        let form = self.journalForm.form
        let errors = form.validate()
        if errors.count > 0 {
            print("fix ur errors!")
        } else {
            let titleRow: TextRow! = form.rowBy(tag: "TitleTag")
            let locRow: LabelRow! = form.rowBy(tag: "LocTag")
            let startDateRow : DateRow! = form.rowBy(tag: "StartDateTag")
            let endDateRow : DateRow! = form.rowBy(tag: "EndDateTag")
            
            let title = titleRow.value! as String
            let location = locRow.value! as String
            let startDate = startDateRow.value! as Date
            let endDate = endDateRow.value! as Date
            
            self.journal?.name = title
            self.journal?.location = location
            self.journal?.startDate = startDate
            self.journal?.endDate = endDate
            self.journal?.coverPhotoUrl = self.coverSelect.journal?.coverPhotoUrl
            self.journal?.lat = self.journalForm.journal?.lat
            self.journal?.lng = self.journalForm.journal?.lng
            self.journal?.placeId = self.journalForm.journal?.placeId
            
            self.delegate?.save(journal: self.journal!)
            _ = self.navigationController?.popViewController(animated: true)
        }
    }



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "formSegue" {
            self.journalForm = segue.destination as! AddJournalViewController
            self.journalForm.journal = self.journal
        } else if segue.identifier == "coverSegue" {
            self.coverSelect = segue.destination as! CoverPhotoCollectionViewController
            self.coverSelect.journal = journal
        }
    }


}
