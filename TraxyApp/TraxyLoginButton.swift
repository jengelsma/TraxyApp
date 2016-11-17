//
//  TraxyButton.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/15/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyLoginButton: UIButton {
    
    override func awakeFromNib() {
        self.backgroundColor = THEME_COLOR3
        self.tintColor = THEME_COLOR2
        self.layer.borderWidth = 1.0
        self.layer.borderColor = THEME_COLOR3.cgColor
        self.layer.cornerRadius = 5.0
    }
}
