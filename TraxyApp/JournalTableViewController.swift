
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
import Photos

class JournalTableViewController: UITableViewController, UINavigationControllerDelegate {

    var capturedImage : UIImage?
    var captureVideoUrl : URL?
    var captureType : EntryType = .photo
    
    var journal: Journal!
    var entries : [JournalEntry] = []
    var entryToEdit : JournalEntry?
    
    fileprivate var ref : FIRDatabaseReference?
    fileprivate var storageRef : FIRStorageReference?
    fileprivate var userId : String?
    
    // MARK: - UIViewController overrides and their helpers
    
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
    
    func registerForFireBaseUpdates()
    {
        
        self.ref!.child("entries").observe(.value, with: { [weak self] snapshot in
            guard let strongSelf = self else { return }
            if let postDict = snapshot.value as? [String : AnyObject] {
                var tmpItems = [JournalEntry]()
                for (key,val) in postDict.enumerated() {
                    print("key = \(key) and val = \(val)")
                    let entry = val.1 as! Dictionary<String,AnyObject>
                    print ("entry=\(entry)")
                    let key = val.0
                    let caption : String? = entry["caption"] as! String?
                    let url : String? = entry["url"] as! String?
                    var thumbnailUrl : String? = entry["thumbnailUrl"] as? String
                    if thumbnailUrl == nil {
                        thumbnailUrl = ""
                    } else {
                        print(thumbnailUrl!)
                    }
                    let dateStr  = entry["date"] as! String?
                    let lat = entry["lat"] as! Double?
                    let lng = entry["lng"] as! Double?
                    let typeRaw = entry["type"] as! Int?
                    let type = EntryType(rawValue: typeRaw!)
                    
                    tmpItems.append(JournalEntry(key: key, type: type, caption: caption, url: url, thumbnailUrl: thumbnailUrl!, date: dateStr?.dateFromISO8601, lat: lat, lng: lng))
                }
                strongSelf.entries = tmpItems
                strongSelf.tableView.reloadData()
            }
        })
        
    }
    
    // MARK: - IBActions and helpers
    
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
            case.video:
                self.showContentOfUrlWithAVPlayer(url: entry.url!)
            case .audio:
                self.showContentOfUrlWithAVPlayer(url: entry.url!)
            default: break
            }
        }
    }
    
    func showContentOfUrlWithAVPlayer(url : String) {
        let mediaUrl = URL(string: url)
        let player = AVPlayer(url: mediaUrl!)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
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
            self.displayCameraIfPermitted()

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

    func displayCameraIfPermitted() {
        let cameraMediaType = AVMediaTypeVideo
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .denied:
            self.displaySettingsAppAlert()
        case .authorized:
            self.displayImagePicker()
        case .restricted:
            self.displaySettingsAppAlert()
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(forMediaType: cameraMediaType) { granted in
                if granted {
                    DispatchQueue.main.sync {
                        self.displayImagePicker()
                    }
                } else {
                    print("Denied access to \(cameraMediaType)")
                }
            }
        }
    }
    
    func displayImagePicker()
    {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func displaySettingsAppAlert()
    {
        let avc = UIAlertController(title: "Camera Permission Required", message: "You need to provide this app permissions to use your camera for this feature. You can do this by going to your Settings app and going to Privacy -> Camera", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default ) {action in
            UIApplication.shared.open(NSURL(string: UIApplicationOpenSettingsURLString)! as URL, options: [:], completionHandler: nil)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        avc.addAction(settingsAction)
        avc.addAction(cancelAction)
        
        self.present(avc, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "confirmSegue" {
            if let destCtrl = segue.destination as? JournalEntryConfirmationViewController {
                destCtrl.imageToConfirm = self.capturedImage
                destCtrl.delegate = self
                destCtrl.type = self.captureType
                destCtrl.entry = self.entryToEdit  // will be nil on new item
                destCtrl.journal = self.journal
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
                destCtrl.journal = self.journal
            }
        }
    }
    
    
}


// MARK: - UITableViewDelegate and UITableViewDataSource

extension JournalTableViewController  {
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.journal.name
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = THEME_COLOR2
        header.contentView.backgroundColor = THEME_COLOR3
    }
    

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
        if let iv = cell.thumbnailImage {
            iv.image = UIImage(named: "landscape")
        }
        switch(entry.type!) {
        case .photo:
            if let imageURL = entry.url {
                let url = URL(string: imageURL)
                cell.thumbnailImage.kf.indicatorType = .activity
                cell.thumbnailImage.kf.setImage(with: url)
            }
            cell.playButton.isHidden = true
        case .video:
                let url = URL(string: entry.thumbnailUrl)
                cell.thumbnailImage.kf.indicatorType = .activity
                cell.thumbnailImage.kf.setImage(with: url)
                cell.playButton.isHidden = false
                cell.playButton.tag = indexPath.row
        default: break
        }
        
        return cell
        
    }
}


// MARK: - UIImagePickerControllerDelegate and helpers

extension JournalTableViewController : UIImagePickerControllerDelegate {
    
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
                
//                let lib = PHPhotoLibrary.shared()
//                var placeHolderAsset : PHObjectPlaceholder? = nil
//                lib.performChanges({ 
//                    let newRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.captureVideoUrl!)
//                    newRequest?.creationDate = Date()
//                    placeHolderAsset = newRequest?.placeholderForCreatedAsset
//                }, completionHandler: { (success, error) in
//                    if success {
//                        print("success")
//                    } else {
//                        print("Not good")
//                    }
//                })
                
//                let library = ALAssetsLibrary()
//                
//                library.writeVideoAtPath(toSavedPhotosAlbum: self.captureVideoUrl, completionBlock: { (url, error) -> Void in
//                    self.captureVideoUrl = url
//                })
            } else {
                print("got image")
                self.capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
                self.captureType = .photo
            }
        }
        
        
        
        self.performSegue(withIdentifier: "confirmSegue", sender: self)
    }
    
    
    func thumbnailForVideoAtURL(url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("error")
            return nil
        }

        
    }
//    
//    func thumbnailForVideoAtURL(url: URL) -> UIImage? {
//        
//        let asset = AVAsset(url: url as URL)
//        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
//        
//        var time = asset.duration
//        time.value = min(time.value, 2)
//        
//        do {
//            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
//            return UIImage(cgImage: imageRef)
//        } catch {
//            print("error")
//            return nil
//        }
//    }
}



// MARK: - AddJournalEntryDelegate and helpers

extension JournalTableViewController : AddJournalEntryDelegate {
    
    func updateJournalCoverPhoto(coverPhotoUrl : String?)
    {
        let vals = [
            "coverPhotoUrl" : coverPhotoUrl! as NSString
        ]
        self.ref?.updateChildValues(vals)
    }
    
    func savePhoto(entry: JournalEntry, isCover: Bool) {
        if let key = entry.key {
            if isCover {
                self.journal.coverPhotoUrl = entry.url
                self.updateJournalCoverPhoto(coverPhotoUrl: self.journal.coverPhotoUrl)
            } else {
                // if we turned off and it is current the cover we update as well.
                if entry.url == self.journal.coverPhotoUrl {
                    self.journal.coverPhotoUrl = ""
                    self.updateJournalCoverPhoto(coverPhotoUrl: self.journal.coverPhotoUrl)
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
                                strongSelf.updateJournalCoverPhoto(coverPhotoUrl:strongSelf.journal.coverPhotoUrl)
                            }
                    }
                }
            }
        }
    }
    
    func saveAudio(entry: JournalEntry) {
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
    
    func saveVideo(entry: JournalEntry) {
        if let key = entry.key {
            let vals = self.toDictionary(vals: entry)
            self.saveEntryToFireBase(key: key, ref: self.ref, vals: vals)
        } else {
            do {
                if let url = self.captureVideoUrl {
                    let videoData = try Data(contentsOf: url)
                    print("got data")
                    let videoPath = "\(self.userId!)/video/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).mp4"
                    let metadata = FIRStorageMetadata()
                    metadata.contentType = "video/mp4"
                    if let sr = self.storageRef {
                        sr.child(videoPath)
                            .put(videoData, metadata: metadata) { [weak self] (metadata, error) in
                                if let error = error {
                                    print("Error uploading: \(error)")
                                    return
                                }
                                
                                // having uploaded the image, now store the data.
                                guard let strongSelf = self else { return }
                                let vals = strongSelf.toDictionary(vals: entry)
                                vals["url"]  = metadata?.downloadURL()!.absoluteString
                                
                                // now save thumbnail image.
                                if let image = strongSelf.capturedImage {
                                    let imageData = UIImageJPEGRepresentation(image, 0.8)
                                    let imagePath = "\(strongSelf.userId!)/photos/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                                    let metadata = FIRStorageMetadata()
                                    metadata.contentType = "image/jpeg"
                                    if let sr = strongSelf.storageRef {
                                        sr.child(imagePath)
                                            .put(imageData!, metadata: metadata) { [weak self] (metadata, error) in
                                                if let error = error {
                                                    print("Error uploading: \(error)")
                                                    return
                                                }
                                                
                                                // having uploaded the image, now store the data.
                                                guard let strongSelf = self else { return }
                                                vals["thumbnailUrl"] = metadata?.downloadURL()!.absoluteString
                                                strongSelf.saveEntryToFireBase(key: entry.key, ref: strongSelf.ref, vals: vals)
                                            
                                        }
                                    }
                                }

                                
                                //strongSelf.saveEntryToFireBase(key: entry.key, ref: strongSelf.ref, vals: vals)
                        }
                    }
                }
                
            } catch {
                print("oops that wasn't good now")
            }
        }
    }

    
    
    func save(entry: JournalEntry, isCover: Bool) {
        
        switch(entry.type!) {
        case .photo:
            self.savePhoto(entry: entry, isCover: isCover)
        case .video:
            print("video")
//            let vals = self.toDictionary(vals: entry)
//            vals["url"]  = self.captureVideoUrl?.absoluteString
//            let newChild = self.ref?.child("entries").childByAutoId()
//            newChild?.setValue(vals)
            self.saveVideo(entry: entry)
        case .text:
            let vals = self.toDictionary(vals: entry)
            vals["url"]  = ""
            self.saveEntryToFireBase(key: entry.key, ref: self.ref, vals: vals)
        case .audio:
            self.saveAudio(entry: entry)
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
            "url" : vals.url! as NSString,
            "thumbnailUrl" : vals.thumbnailUrl as NSString
        ]
        
    }
    
}
