//
//  CoverPhotoCollectionViewCell.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/27/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class CoverPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photo: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            self.photo.layer.borderWidth = isSelected ? 5 : 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.photo.layer.borderColor = THEME_COLOR2.cgColor
        isSelected = false
    }
}
