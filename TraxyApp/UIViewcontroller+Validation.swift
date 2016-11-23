//
//  UIViewcontroller+Validation.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/7/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

extension UIViewController {

    func isEmptyOrNil(str : String?) -> Bool {
        guard let s = str, !s.isEmpty else {
            return false
        }
        return true
    }
    
    func isValidEmail(emailStr : String? ) -> Bool
    {
        var emailOk = false
        if let email = emailStr {
            let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", regex)
            emailOk = emailPredicate.evaluate(with: email)
        }
        return emailOk
    }
    
    func reportError(msg: String) {
        let alert = UIAlertController(title: "Failed", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
