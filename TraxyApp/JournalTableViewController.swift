
//
//  JournalTableViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/30/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices
import FirebaseDatabase
import FirebaseStorage
import Firebase
import AssetsLibrary
import Kingfisher

class JournalTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AddJournalEntryDelegate {

    var capturedImage : UIImage?
    var captureVideoUrl : URL?
    var captureType : EntryType = .photo
    
    var journal: Journal!
    var entries : [JournalEntry] = []
    var entryToEdit : JournalEntry?
    
    fileprivate var ref : FIRDatabaseReference?
    fileprivate var storageRef : FIRStorageReference?
    fileprivate var userId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
        self.clearsSelectionOnViewWillAppear = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                self.userId = user.uid
                self.ref = FIRDatabase.database().reference().child(self.userId!).child(self.journal.key!)
                self.configureStorage()
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

    func configureStorage() {
        let storageUrl = FIRApp.defaultApp()?.options.storageBucket
        self.storageRef = FIRStorage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    fileprivate func registerForFireBaseUpdates()
    {
        
        self.ref!.child("entries").observe(.value, with: { snapshot in
            
            if let postDict = snapshot.value as? [String : AnyObject] {
                var tmpItems = [JournalEntry]()
                for (key,val) in postDict.enumerated() {
                    print("key = \(key) and val = \(val)")
                    let entry = val.1 as! Dictionary<String,AnyObject>
                    print ("entry=\(entry)")
                    let key = val.0
                    let caption : String? = entry["caption"] as! String?
                    let url : String? = entry["url"] as! String?
                    let dateStr  = entry["date"] as! String?
                    let lat = entry["lat"] as! Double?
                    let lng = entry["lng"] as! Double?
                    let typeRaw = entry["type"] as! Int?
                    let type = EntryType(rawValue: typeRaw!)
                    
                    tmpItems.append(JournalEntry(key: key, type: type, caption: caption, url: url, date: dateStr?.dateFromISO8601, lat: lat, lng: lng))
                }
                self.entries = tmpItems
                self.tableView.reloadData()
            }
        })
        
    }
    
    // MARK: - IBActions
    @IBAction func imageButtonPressed(_ sender: UIButton) {

        let row = Int(sender.tag)
        print("Row \(row) image button pressed.")
        let indexPath = IndexPath(row: row, section: 0)
        let cell = self.tableView.cellForRow(at: indexPath) as! JournalEntryTableViewCell
        if let tnImg = cell.thumbnailImage {
            self.capturedImage = tnImg.image
        }
        self.entryToEdit = cell.entry
        if let entry = cell.entry {
            switch(entry.type!) {
            case .photo:
                self.performSegue(withIdentifier: "viewPhoto", sender: self)
            case .audio:
                let audioUrl = URL(string: entry.url!)
                let player = AVPlayer(url: audioUrl!)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                self.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
            default: break
            }
        }
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        let row = Int(sender.tag)
        print("Row \(row) edit button pressed.")
        let indexPath = IndexPath(row: row, section: 0)
        let cell = self.tableView.cellForRow(at: indexPath) as! JournalEntryTableViewCell
        if let tnImg = cell.thumbnailImage {
            self.capturedImage = tnImg.image
        }
        self.entryToEdit = cell.entry
        self.captureType = (self.entryToEdit?.type)!
        self.performSegue(withIdentifier: "confirmSegue", sender: self)
    }
    
    @IBAction func addEntryButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: "What kind of entry would you like to add to your journal?", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // ...
        }
        alertController.addAction(cancelAction)
        
        let addTextAction = UIAlertAction(title: "Text Entry", style: .default) { (action) in
            self.captureType = .text
            self.capturedImage = nil
            self.performSegue(withIdentifier: "confirmSegue", sender: self)
        }
        alertController.addAction(addTextAction)
        
        let addCameraAction = UIAlertAction(title: "Photo or Video Entry", style: .default) { (action) in
            let picker = UIImagePickerController()
            picker.allowsEditing = false
            picker.sourceType = .camera
            picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            picker.modalPresentationStyle = .fullScreen
            picker.delegate = self
            self.present(picker, animated: true, completion: {
                print("picture taken")
            })
        }
        alertController.addAction(addCameraAction)
        
        let selectCameraRollAction = UIAlertAction(title: "Select from Camera Roll", style: .default) { (action) in
            let picker = UIImagePickerController()
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            picker.modalPresentationStyle = .fullScreen
            picker.delegate = self
            self.present(picker, animated: true, completion: {
                print("picture selected")
            })
        }
        alertController.addAction(selectCameraRollAction)
        
        
        let addAudioAction = UIAlertAction(title: "Audio Entry", style: .default) { (action) in
            self.performSegue(withIdentifier: "recordAudio", sender: self)
        }
        alertController.addAction(addAudioAction)
        
        self.present(alertController, animated: true) {
            self.entryToEdit = nil // always creating a new entry when this alert is displayed.
        }
        
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.entries.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let entry = self.entries[indexPath.row]
        var cellIds = ["NA", "TextCell", "PhotoCell", "AudioCell", "PhotoCell"]

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIds[entry.type!.rawValue], for: indexPath) as! JournalEntryTableViewCell

        cell.editButton?.tag = indexPath.row
        if let imgButton = cell.imageButton {
            imgButton.tag = cell.editButton!.tag
        }
        
        cell.setValues(entry: entry)
        
        switch(entry.type!) {
        case .photo:
            if let imageURL = entry.url {
                let url = URL(string: imageURL)
                cell.thumbnailImage.kf.indicatorType = .activity
                cell.thumbnailImage.kf.setImage(with: url)
            }
        default: break
        }
        
        return cell
        
    }

    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.journal.name
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = THEME_COLOR2
        header.contentView.backgroundColor = THEME_COLOR3
    }
 
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled")
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            if mediaType == kUTTypeMovie as String {
                print("got video")
                self.capturedImage = self.thumbnailForVideoAtURL(url: info[UIImagePickerControllerMediaURL] as! URL)
                self.captureVideoUrl = info[UIImagePickerControllerMediaURL] as? URL
                self.captureType = .video
                
                let isVideoCompatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum((self.captureVideoUrl?.absoluteString)!)
                print("bool: \(isVideoCompatible)") // This logs out "bool: false"
                
                let library = ALAssetsLibrary()
                
                library.writeVideoAtPath(toSavedPhotosAlbum: self.captureVideoUrl, completionBlock: { (url, error) -> Void in
                    self.captureVideoUrl = url
                })
            } else {
                print("got image")
                self.capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
                self.captureType = .photo
            }
        }



        self.performSegue(withIdentifier: "confirmSegue", sender: self)
    }
    
    private func thumbnailForVideoAtURL(url: URL) -> UIImage? {
        
        let asset = AVAsset(url: url as URL)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("error")
            return nil
        }
    }
    


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "confirmSegue" {
            if let destCtrl = segue.destination as? JournalEntryConfirmationViewController {
                destCtrl.imageToConfirm = self.capturedImage
                destCtrl.delegate = self
                destCtrl.type = self.captureType
                destCtrl.entry = self.entryToEdit  // will be nil on new item
                destCtrl.currentCoverUrl = self.journal.coverPhotoUrl
            }
        } else if segue.identifier == "viewPhoto" {
            if let destCtrl = segue.destination as? PhotoViewController {
                destCtrl.imageToView = self.capturedImage
                destCtrl.captionToView = self.entryToEdit?.caption
            }
        } else if segue.identifier == "recordAudio" {
            if let destCtrl = segue.destination as? AudioViewController {
                destCtrl.entry = self.entryToEdit // will be nil if new item.
                destCtrl.delegate = self
            }
        }
    }
    
    
    // MARK: - AddJournalEntryDelegate
    
    func updateJournalCoverPhoto(vals : Journal)
    {
        let vals = [
//            "name": vals.name! as NSString,
//            "address": vals.location! as NSString,
//            "startDate" : NSString(string: (vals.startDate?.iso8601)!) ,
//            "endDate": NSString(string: (vals.endDate?.iso8601)!),
//            "lat" : NSNumber(value: 0.0),
//            "lng" : NSNumber(value: 0.0),
//            "placeId" : vals.placeId! as NSString,
            "coverPhotoUrl" : vals.coverPhotoUrl! as NSString
        ]
        self.ref?.updateChildValues(vals)
        //self.ref?.setValue(vals)
    }
    
    func save(entry: JournalEntry, isCover: Bool) {
        
        switch(entry.type!) {
        case .photo:
            if let key = entry.key {
                if isCover {
                    self.journal.coverPhotoUrl = entry.url
                    self.updateJournalCoverPhoto(vals: self.journal)
                } else {
                    // if we turned off and it is current the cover we update as well. 
                    if entry.url == self.journal.coverPhotoUrl {
                        self.journal.coverPhotoUrl = ""
                        self.updateJournalCoverPhoto(vals: self.journal)
                    }
                }
                let vals = self.toDictionary(vals: entry)
                self.saveEntryToFireBase(key: key, ref: self.ref, vals: vals)
            } else {
                if let image = self.capturedImage {
                    let imageData = UIImageJPEGRepresentation(image, 0.8)
                    let imagePath = "\(self.userId!)/photos/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                    let metadata = FIRStorageMetadata()
                    metadata.contentType = "image/jpeg"
                    if let sr = self.storageRef {
                        sr.child(imagePath)
                            .put(imageData!, metadata: metadata) { [weak self] (metadata, error) in
                                if let error = error {
                                    print("Error uploading: \(error)")
                                    return
                                }
                                
                                // having uploaded the image, now store the data.
                                guard let strongSelf = self else { return }

                                var newEntry = entry
                                newEntry.url = metadata?.downloadURL()?.absoluteString
                                let vals = strongSelf.toDictionary(vals: newEntry)
                                
                                strongSelf.saveEntryToFireBase(key: entry.key, ref: strongSelf.ref, vals: vals)
                                if isCover {
                                    strongSelf.journal.coverPhotoUrl = metadata?.downloadURL()?.absoluteString
                                    strongSelf.updateJournalCoverPhoto(vals: strongSelf.journal)
                                }
                        }
                    }
                }
            }
        case .video:
            print("video")
            let vals = self.toDictionary(vals: entry)
            vals["url"]  = self.captureVideoUrl?.absoluteString
            let newChild = self.ref?.child("entries").childByAutoId()
            newChild?.setValue(vals)
        case .text:
            let vals = self.toDictionary(vals: entry)
            vals["url"]  = ""
            self.saveEntryToFireBase(key: entry.key, ref: self.ref, vals: vals)
        case .audio:
            if let key = entry.key {
                let vals = self.toDictionary(vals: entry)
                self.saveEntryToFireBase(key: key, ref: self.ref, vals: vals)
            } else {
                do {
                    if let urlStr = entry.url {
                        let url = URL(string: urlStr)
                        let audioData = try Data(contentsOf: url!)
                        print("got data")
                        let audioPath = "\(self.userId!)/audio/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).m4a"
                        let metadata = FIRStorageMetadata()
                        metadata.contentType = "audio/mp4"
                        if let sr = self.storageRef {
                            sr.child(audioPath)
                                .put(audioData, metadata: metadata) { [weak self] (metadata, error) in
                                    if let error = error {
                                        print("Error uploading: \(error)")
                                        return
                                    }
                                    
                                    // having uploaded the image, now store the data.
                                    guard let strongSelf = self else { return }
                                    let vals = strongSelf.toDictionary(vals: entry)
                                    vals["url"]  = metadata?.downloadURL()!.absoluteString
                                    strongSelf.saveEntryToFireBase(key: entry.key, ref: strongSelf.ref, vals: vals)
                                    
                            }
                        }
                    }
                    
                } catch {
                    print("oops that wasn't good now")
                }
            }
        }
        
    }
    
    func saveEntryToFireBase(key: String?, ref : FIRDatabaseReference?, vals: NSMutableDictionary) {
        if let k = key {
            let oldChild = ref?.child("entries").child(k)
            oldChild?.setValue(vals)
        } else {
            let newChild = ref?.child("entries").childByAutoId()
            newChild?.setValue(vals)
        }
    }

    func toDictionary(vals: JournalEntry) -> NSMutableDictionary {
        
        return [
            "caption": vals.caption! as NSString,
            "lat": vals.lat! as NSNumber,
            "lng": vals.lng! as NSNumber,
            "date" : NSString(string: (vals.date?.iso8601)!) ,
            "type" : NSNumber(value: vals.type!.rawValue),
            "url" : vals.url! as NSString
        ]
        
    }
}
