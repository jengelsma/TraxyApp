//
//  SignUpViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/7/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignUpViewController: TraxyLoginViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var verifyPasswordField: UITextField!
    var validationErrors = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.verifyPasswordField.delegate = self
        
        // dismiss keyboard when tapping outside of text fields
        let detectTouch = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(detectTouch)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dismissKeyboard()
    {
        self.view.endEditing(true)
    }
    
    func validateFields() -> Bool {
        
        let pwOk = self.isEmptyOrNil(str: self.passwordField.text)
        if !pwOk {
            self.validationErrors += "Password cannot be blank. "
        }
        
        let pwMatch = self.passwordField.text == self.verifyPasswordField.text
        if !pwMatch {
            self.validationErrors += "Passwords do not match. "
        }
        
        let emailOk = self.isValidEmail(emailStr: self.emailField.text)
        if !emailOk {
            self.validationErrors += "Invalid email address."
        }
        
        return emailOk && pwOk && pwMatch
    }
    
    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        if self.validateFields() {
            Auth.auth().createUser(withEmail: self.emailField.text!, password: self.passwordField.text!) { (user, error) in
                if let  _ = user {
                   self.performSegue(withIdentifier: "unwindToMainFromSignUp", sender: self)
                    //self.dismiss(animated: true, completion: nil)
                } else {
                    self.passwordField.text = ""
                    self.verifyPasswordField.text = ""
                    self.passwordField.becomeFirstResponder()
                    self.reportError(msg: (error?.localizedDescription)!)
                }
            }
        } else {
            self.reportError(msg: self.validationErrors)
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMainFromSignUp" {
            if let destVC = segue.destination as? MainViewController {
                destVC.userEmail = self.emailField.text
            }
        }
    }
*/

}

extension SignUpViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.verifyPasswordField.becomeFirstResponder()
        } else {
            if self.validateFields() {
                print("Congratulations!  You entered correct values.")
            }
        }
        return true
    }
}

