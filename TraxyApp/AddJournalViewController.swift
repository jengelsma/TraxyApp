//
//  AddJournalViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/21/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import Eureka
import GooglePlacePicker

protocol AddJournalDelegate {
    func save(journal: Journal)
}

class AddJournalViewController: FormViewController {

    var delegate : AddJournalDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textRowValidationUpdate : (TextRow.Cell, TextRow) -> ()  = { cell, row in
            if !row.isValid {
                cell.titleLabel?.textColor = .red
            } else {
                cell.titleLabel?.textColor = .black
            }
        }
        TextRow.defaultCellUpdate =  textRowValidationUpdate
        TextRow.defaultOnRowValidationChanged = textRowValidationUpdate

        let dateRowValidationUpdate : (DateRow.Cell, DateRow) -> () = { cell, row in
            if !row.isValid {
                cell.textLabel?.textColor = .red
            } else {
                cell.textLabel?.textColor = .black
            }
        }
        DateRow.defaultCellUpdate = dateRowValidationUpdate
        DateRow.defaultOnRowValidationChanged = dateRowValidationUpdate
        
        let labelRowValidationUpdate : (LabelRow.Cell, LabelRow) -> () = { cell, row in
            if !row.isValid {
                cell.textLabel?.textColor = .red
            } else {
                cell.textLabel?.textColor = .black
            }
        }
        LabelRow.defaultCellUpdate = labelRowValidationUpdate
        LabelRow.defaultOnRowValidationChanged = labelRowValidationUpdate


        
        // Describe our beautiful eureka form
        form = Section("Trip Information")
            <<< TextRow(){ row in
                row.title = "Journal Title"
                row.placeholder = "Descriptive title"
                row.tag = "TitleTag"
                row.add(rule: RuleRequired())
            }
            
            <<< LabelRow () { row in
                row.title = "General Location"
                row.value = "Tap to search"
                row.tag = "LocTag"
                var rules = RuleSet<String>()
                rules.add(rule: RuleClosure(closure: { (loc) -> ValidationError? in
                    if loc == "Tap to search" {
                        return ValidationError(msg: "You must select a location")
                    } else {
                        return nil
                    }
                }))
                row.add(ruleSet:rules)
                
            }.onCellSelection { cell, row in
                // crank up Google's place picker when row is selected.
                let autocompleteController = GMSAutocompleteViewController()
                autocompleteController.delegate = self
                self.present(autocompleteController, animated: true, completion: nil)
            }
            
            +++ Section("Trip Dates")
            <<< DateRow(){ row in
                row.title = "Start Date"
                row.value = Date()
                row.tag = "StartDateTag"
                row.add(rule: RuleRequired())
            }
            <<< DateRow(){ row in
                row.title = "End Date"
                row.value = Date(timeIntervalSinceNow: 86401)
                row.tag = "EndDateTag"
                row.validationOptions = .validatesOnChange
                var rules = RuleSet<Date>()
                rules.add(rule: RuleRequired())
                rules.add(rule: RuleClosure(closure: { (date) -> ValidationError? in
                    let sdRow: DateRow! = self.form.rowBy(tag: "StartDateTag")
                    let sDate = sdRow.value as Date?
                    if sDate! > date! {
                        return ValidationError(msg:"End date must come after start date")
                    } else {
                        return nil
                    }
                }))
                row.add(ruleSet: rules)

            }
       
        
        let cancelButton : UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(AddJournalViewController.cancelPressed))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        let saveButton : UIBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(AddJournalViewController.savePressed))
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
       let errors = self.form.validate()
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
            
            self.delegate?.save(journal: Journal(name: title, location: location, startDate: startDate, endDate: endDate, lat: -1, lng: -1, placeId: nil))
           _ = self.navigationController?.popViewController(animated: true)
        }
    }

}

extension AddJournalViewController: GMSAutocompleteViewControllerDelegate {

    public func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(error.localizedDescription)
    }
    
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: ", place.name)
        print("PlaceId: ", place.placeID)
        print("Place address: ", place.formattedAddress)
        print("Place attributions: ", place.attributions)
        //        self.fieldValues[0] = place.name
        //        self.fieldValues[1] = place.formattedAddress!
        //        self.loadFirstPhotoForPlace(placeID: place.placeID, imageView:self.coverPhoto)
        //        self.place = place
        //        self.tableView.reloadData()
        
        let row: LabelRow? = form.rowBy(tag: "LocTag")
        row?.value = place.name
        row?.validate()
        self.dismiss(animated: true, completion: nil)
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        // TODO: handle the error.
        print("Error: ", error.description)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        self.dismiss(animated: true, completion: nil)
        let row: LabelRow? = form.rowBy(tag: "LocTag")
        row?.validate()
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

