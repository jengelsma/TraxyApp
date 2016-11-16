//
//  TraxyLoginTextField.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/16/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyLoginTextField: UITextField {
    
    override func awakeFromNib() {

        self.tintColor = THEME_COLOR3
        self.layer.borderWidth = 1.0
        self.layer.borderColor = THEME_COLOR3.cgColor
        self.layer.cornerRadius = 5.0

        self.textColor = THEME_COLOR3
        self.backgroundColor = UIColor.clear
        self.borderStyle = .roundedRect

        guard let ph = self.placeholder  else {
            return
        }
        
        self.attributedPlaceholder =
            NSAttributedString(string: ph, attributes: [NSForegroundColorAttributeName : THEME_COLOR3])
    }
}
