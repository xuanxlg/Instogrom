//
//  SignInViewController.swift
//  Instogrom
//
//  Created by HuangShih-Hsuan on 27/03/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {
    
    let USERS: String = "users"
    let SIGN_IN_TIME: String = "sign_in_time"
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    let dateFormatter = DateFormatter()
    
    var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        dateFormatter.timeZone = TimeZone.ReferenceType.local
        
        if FIRAuth.auth()?.currentUser != nil {
            print("\(FIRAuth.auth()?.currentUser?.email)")
        } else {
            print("User log out")
        }
        
    }
    
    @IBAction func signIn(_ sender: Any) {
        guard  let email = emailField.text, let password = passwordField.text else {
            print("Email or password invailid")
            return
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            
            guard let user = user else {
                print("Sign In error: \(error)")
                return
            }
            
            var childUpdates = [String: Any]()
            childUpdates[self.SIGN_IN_TIME] = Int(Date().timeIntervalSince1970 * 1000)
            self.ref.child(self.USERS).child(user.uid).updateChildValues(childUpdates)
            
            print("Sign In success")
        })
    }
    
    
}
