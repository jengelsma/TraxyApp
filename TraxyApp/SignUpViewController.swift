//
//  SignUpViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/7/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var verifyPasswordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.verifyPasswordField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func validateFields() -> Bool {
        
        let pwOk = self.isEmptyOrNil(str: self.passwordField.text)
        if !pwOk {
            print("Password cannot be blank")
        }
        
        let pwMatch = self.passwordField.text == self.verifyPasswordField.text
        if !pwMatch {
            print("Passwords do not match.")
        }
        
        let emailOk = self.isValidEmail(emailStr: self.emailField.text)
        if !emailOk {
            print("Invalid email address")
        }
        
        return emailOk && pwOk && pwMatch
    }
    
    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        if self.validateFields() {
            self.performSegue(withIdentifier: "segueToMainFromSignUp", sender: self)
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMainFromSignUp" {
            if let destVC = segue.destination as? MainViewController {
                destVC.userEmail = self.emailField.text
            }
        }
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

