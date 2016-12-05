//
//  JournalEntryTableViewCell.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/5/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class JournalEntryTableViewCell: UITableViewCell {

    @IBOutlet weak var caption: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var containingView: UIView!
    @IBOutlet weak var date: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.containingView.layer.cornerRadius = 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setValues(entry : JournalEntry) {
        self.caption.text = entry.caption
        self.date.text = entry.date?.shortWithTime
    }
}
