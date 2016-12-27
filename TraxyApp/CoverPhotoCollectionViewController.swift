//
//  CoverPhotoCollectionViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/27/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit


class CoverPhotoCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    fileprivate let insets = UIEdgeInsets(top: 18.0, left: 18.0, bottom: 18.0, right: 18.0)
    fileprivate let ROW_SIZE : CGFloat  = 4.0
    fileprivate let cellId = "PhotoCell"
    @IBOutlet weak var collectionView: UICollectionView!
    
    var entries : [Dictionary<String,AnyObject>]?
    var journal : Journal? {
        didSet {
            self.entries = []
            if let e = journal?.entries {
                for (_,val) in e.enumerated() {
                    let entry = val.1 as! Dictionary<String,AnyObject>
                    print ("entry=\(entry)")
                    let typeRaw = entry["type"] as! Int?
                    let type = EntryType(rawValue: typeRaw!)
                    if type == .photo {
                        self.entries?.append(entry)
                    }
                }
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.allowsMultipleSelection = false
        if self.journal == nil {
            self.journal = Journal()
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView.register(CoverPhotoCollectionViewCell.self, forCellWithReuseIdentifier: cellId)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let entries = self.entries {
            return entries.count
        }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! CoverPhotoCollectionViewCell
    
        
        cell.photo.image = UIImage(named: "landscape")
        
        if let entry = self.entries?[indexPath.row] {
            if let url = entry["url"] as? String {
                cell.photo?.kf.indicatorType = .activity
                cell.photo?.kf.setImage(with: URL(string: url))
                if self.journal?.coverPhotoUrl == url {
                    cell.isSelected = true
                    self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .top)
                } 
            }
        }

        // Configure the cell
        //cell.backgroundColor = UIColor.brown
        return cell
    }

    // MARK: UICollectionViewDelegate

    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let entry = self.entries?[indexPath.row] {
            self.journal?.coverPhotoUrl = entry["url"] as? String
        }
        
        /*
        // unfortunately, we need to manually deselect the other one! 
        if var indexPaths = self.collectionView.indexPathsForSelectedItems {
            indexPaths.remove(at: indexPaths.index(of: indexPath)!)
            for ip in indexPaths {
                self.collectionView.deselectItem(at: ip, animated: true)
            }
        }
 */
        
    }
 
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        

        
        return false
    }

*/
    
    /*
    // Uncomment this method to specify if the specified item should be selected
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let entry = self.entries?[indexPath.row] {
            if self.journal?.coverPhotoUrl == (entry["url"] as? String)! {
                return true
            } else {
                return false
            }
        }
        return false
    }
 */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}


extension CoverPhotoCollectionViewController : UICollectionViewDelegateFlowLayout {
    


    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let paddingSpace = self.insets.left * (ROW_SIZE + 1.0)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / ROW_SIZE
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.insets
    }
    

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.insets.left
    }
}

