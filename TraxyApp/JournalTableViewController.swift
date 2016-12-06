//
//  JournalTableViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/30/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import FirebaseDatabase
import FirebaseStorage
import Firebase
import AssetsLibrary

class JournalTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AddJournalEntryDelegate {

    var capturedImage : UIImage?
    var captureVideoUrl : URL?
    var captureType : EntryType = .photo
    
    var journal: Journal?
    var entries : [JournalEntry] = []
    
    fileprivate var ref : FIRDatabaseReference?
    fileprivate var storageRef : FIRStorageReference?
    fileprivate var userId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200

        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                self.userId = user.uid
                self.ref = FIRDatabase.database().reference().child(self.userId!).child(self.journal!.key!)
                self.configureStorage()
                self.registerForFireBaseUpdates()
            } else {
                // No user is signed in.
                self.performSegue(withIdentifier: "logoutSegue", sender: self)
            }
        }
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

        //cell.textLabel?.text = entry.date?.short
        //cell.detailTextLabel?.text = entry.caption
        cell.setValues(entry: entry)
        if let imageURL = entry.url {
            if imageURL.hasPrefix("gs://") {
                FIRStorage.storage().reference(forURL: imageURL).data(withMaxSize: INT64_MAX){ (data, error) in
                    if let error = error {
                        print("Error downloading: \(error)")
                        return
                    }
                    //cell.imageView?.image = UIImage.init(data: data!)
                    cell.optionalImage?.image = UIImage.init(data: data!)
                    cell.setNeedsLayout()
                }
//            } else if let URL = URL(string: imageURL), let data = try? Data(contentsOf: URL) {
//                cell.thumbnail?.image = UIImage.init(data: data)
//                cell.setNeedsDisplay()
//            }
            } else if let url = URL(string: imageURL) {
                let image = self.thumbnailForVideoAtURL(url: url)
                cell.optionalImage?.image = image
                cell.setNeedsLayout()
            } 
        }
        
        
        
        return cell
        
    }

    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.journal?.name
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = THEME_COLOR2
        header.contentView.backgroundColor = THEME_COLOR3
    }
 
    @IBAction func addEntryButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: "What would you like to add?", preferredStyle: .actionSheet)
        
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
            
        }
        alertController.addAction(addAudioAction)
    
        self.present(alertController, animated: true) { 
            
        }

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
            }
        }
    }
    
    
    // MARK: AddJournalEntryDelegate
    func save(entry: JournalEntry) {
    
        switch(entry.type!) {
        case .photo:
            if let image = self.capturedImage {
                let imageData = UIImageJPEGRepresentation(image, 0.8)
                let imagePath = "\(self.userId!)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
                let metadata = FIRStorageMetadata()
                metadata.contentType = "image/jpeg"
                if let sr = self.storageRef {
                    sr.child(imagePath)
                        .put(imageData!, metadata: metadata) { [weak self] (metadata, error) in
                            if let error = error {
                                print("Error uploading: \(error)")
                                return
                            }
                            guard let strongSelf = self else { return }
                            //strongSelf.sendMessage(withData: [Constants.MessageFields.imageURL: strongSelf.storageRef.child((metadata?.path)!).description])
                            
                            let vals = strongSelf.toDictionary(vals: entry)
                            vals["url"]  = strongSelf.storageRef?.child((metadata?.path)!).description
                            let newChild = strongSelf.ref?.child("entries").childByAutoId()
                            newChild?.setValue(vals)
                            
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
            let newChild = self.ref?.child("entries").childByAutoId()
            newChild?.setValue(vals)
        default:
            print("other stuff")
        }
    }
    
    func toDictionary(vals: JournalEntry) -> NSMutableDictionary {
        
        return [
            "caption": vals.caption! as NSString,
            "lat": vals.lat! as NSNumber,
            "lng": vals.lng! as NSNumber,
            "date" : NSString(string: (vals.date?.iso8601)!) ,
            "type" : NSNumber(value: vals.type!.rawValue),
            "lng" : NSNumber(value: 0.0),
        ]
        
    }

    

}
