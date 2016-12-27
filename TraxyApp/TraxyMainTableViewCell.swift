//
//  TraxyMainTableViewCell.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/17/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyMainTableViewCell: UITableViewCell {

    @IBOutlet weak var subName: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var translucentView: UIView!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.coverImage.backgroundColor = THEME_COLOR3
        self.editButton.backgroundColor = THEME_COLOR3
        self.editButton.titleLabel?.textColor = THEME_COLOR2
        self.editButton.layer.cornerRadius = 10.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
