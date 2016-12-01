//
//  JournalEntryConfirmationViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/1/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class JournalEntryConfirmationViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var imageToConfirm : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.image = imageToConfirm
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
