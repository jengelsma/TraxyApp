//
//  ViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 11/2/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import UIKit

class LoginViewController: TraxyLoginViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // dismiss keyboard when tapping outside of text fields
        let detectTouch = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(detectTouch)
        
        // make this controller the delegate of the text fields.
        self.emailField.delegate = self
        self.passwordField.delegate = self

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
            print("Password cannot be blank")
        }
        
        let emailOk = self.isValidEmail(emailStr: self.emailField.text)
        if !emailOk {
            print("Invalid email address")
        }
        
        return emailOk && pwOk
    }

    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        if self.validateFields() {
            print("Congratulations!  You entered correct values.")
            self.performSegue(withIdentifier: "segueToMain", sender: self)
        }
    }
    
    @IBAction func logout(segue : UIStoryboardSegue) {
        print("Logged out")
        self.passwordField.text = ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMain" {
            if let destVC = segue.destination as? MainViewController {
                destVC.userEmail = self.emailField.text
            }
        }
    }
}

extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else {
            if self.validateFields() {
                print("Congratulations!  You entered correct values.")
            }
        }
        return true
    }
}
