//
//  JournalEntryConfirmationViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/1/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import Eureka


protocol AddJournalEntryDelegate : class {
    func save(entry: JournalEntry, isCover: Bool)
}

var previewImage : UIImage?

class JournalEntryConfirmationViewController: FormViewController {

    var imageToConfirm : UIImage?
    weak var delegate : AddJournalEntryDelegate?
    var type : EntryType?
    var entry : JournalEntry?
    var journal : Journal!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        previewImage = imageToConfirm
        
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
        
        var textEntryLabel = "Enter caption"
        if self.type == .text {
            textEntryLabel = "Enter text entry"
            self.navigationItem.title = "Text Entry"
        }
        
        var caption : String = ""
        var date : Date = self.journal.startDate!
        if let e = self.entry {
            caption = e.caption!
            date = e.date!
        } else {
            self.entry = JournalEntry(key: nil, type: self.type, caption: caption, url: nil, date: date, lat: 0.0, lng: 0.0)
        }
        
        form = Section() {
            $0.tag = "FirstSection"
            if self.type != .text  && self.type != .audio {
                $0.header = HeaderFooterView<MediaPreviewView>(.class)
            }
        }
            <<< TextAreaRow(textEntryLabel){ row in
                row.placeholder = textEntryLabel
                row.value = caption
                row.tag = "CaptionTag"
                row.add(rule: RuleRequired())
            }
            

            
            +++ Section("Date and Location Recorded")
            <<< DateTimeInlineRow(){ row in
                row.title = "Date"
                row.value = date
                row.tag = "DateTag"
                row.maximumDate = self.journal.endDate
                row.minimumDate = self.journal.startDate
                row.dateFormatter?.dateStyle = .medium
                row.dateFormatter?.timeStyle = .short
                row.add(rule: RuleRequired())
            }
            
            <<< LabelRow () { row in
                row.title = "Location"
                row.value = "Tap for current"
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
                    print("TODO: will finish this next chapter!")
        }
        
        
        if self.type! == .photo {
            let firstSection = form.sectionBy(tag: "FirstSection")
            let switchRow = SwitchRow() { row in
                    row.title = "Use as Cover Photo"
                    row.tag = "CoverTag"
                
                if self.journal.coverPhotoUrl != "" && self.journal.coverPhotoUrl == entry?.url {
                    row.value = true
                }
            }.onChange({ (row) in
                print("row value = \(row.value)")
            })
            
            firstSection?.append(switchRow)
        }

    }
 

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        if let del = self.delegate {

            let (caption,date,_,coverPhoto) = self.extractFormValues()

            if var e = self.entry {
                e.caption = caption
                e.date = date
                del.save(entry: e, isCover: coverPhoto)
            }
        }
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func extractFormValues() -> (String, Date, String, Bool)
    {
        let captionRow: TextAreaRow! = form.rowBy(tag: "CaptionTag")
        //let locRow: LabelRow! = form.rowBy(tag: "LocTag")
        let dateRow : DateTimeInlineRow! = form.rowBy(tag: "DateTag")
        let locationRow : LabelRow! = form.rowBy(tag: "LocTag")
        
        let caption = captionRow.value! as String
        //let location = locRow.value! as String
        let date = dateRow.value! as Date
        let loc = locationRow.value! as String
        
        var coverPhoto = false
        if self.type! == .photo {
            if let switchRow: SwitchRow = form.rowBy(tag: "CoverTag") as? SwitchRow {
                if let val : Bool = switchRow.value {
                    coverPhoto = val
                }
            }
        }
        
        return (caption,date,loc,coverPhoto)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    class MediaPreviewView: UIView {
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            // size image view to a third of available vertical space.
            let screenSize: CGRect = UIScreen.main.bounds
            let width = screenSize.width
            let height = screenSize.height / 3.0
            
            var image : UIImage
            if let img = previewImage {
                image = img
            } else {
                image = UIImage()
            }
            let imageView = UIImageView(image: image)

            //imageView.autoresizingMask = .flexibleWidth
            imageView.contentMode = .scaleAspectFill
            imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            self.frame = CGRect(x: 0, y: 0, width: width, height: height)

            self.clipsToBounds = true
            self.addSubview(imageView)

            // Use auto layout to make image fill the containing view.
//            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: imageView, attribute: .leading, multiplier: 1.0, constant: 0.0).isActive = true
//            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: imageView, attribute: .trailing, multiplier: 1.0, constant: 0.0).isActive = true
//            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: imageView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
//            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: imageView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true

        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    


}


