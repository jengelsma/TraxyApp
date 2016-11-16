//
//  TraxyButton.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/15/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyButton: UIButton {
    
    override func awakeFromNib() {
        self.layer.borderWidth = 1.0
        self.layer.borderColor = FOREGROUND_COLOR.cgColor
        self.layer.cornerRadius = 5.0
    }
}
