//
//  SignUpViewController.swift
//  Instogrom
//
//  Created by HuangShih-Hsuan on 27/03/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
    let USERS: String = "users"
    let EMAIL: String = "email"
    let IS_EMAIL_VERIFIED: String = "is_email_verified"
    let DISPLAY_NAME: String = "display_name"
    let PROVIDER_ID: String = "provider_id"
    let PHOTO_URL: String = "photo_url"
    let REFRESH_TOKEN: String = "refresh_token"
    let SIGN_UP_TIME: String = "sign_up_time"
    
    let dateFormatter = DateFormatter()
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var confirmPasswordField: UITextField!
    
    var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ref = FIRDatabase.database().reference()
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        dateFormatter.timeZone = TimeZone.ReferenceType.local
    }

    @IBAction func signUp(_ sender: Any) {
        guard  let email = emailField.text, let password = passwordField.text, let confirmPassword = confirmPasswordField.text else {
            print("Email or password invailid")
            return
        }
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { (user, error) in
            
            guard let user = user else {
                print("Sign Up error: \(error)")
                return
            }
            
            print("user: \(user.description)")
            
//            let userInfo = [
//                "email": user.email as Any,
//                "is_email_verified": user.isEmailVerified,
//                "name": user.displayName as Any,
//                "provider_id": user.providerID,
//                "refresh_token": user.refreshToken as Any,
//                "is_anonymous": user.isAnonymous
//            ] as [String : Any]
//            
//            self.ref.child("users").child(user.uid).setValue(userInfo)
            
            var newUser = [String: Any]()
            var userInfo = [String: Any]()
            userInfo[self.EMAIL] = user.email as Any
            userInfo[self.IS_EMAIL_VERIFIED] = user.isEmailVerified as Any
            userInfo[self.DISPLAY_NAME] = user.displayName as Any
            userInfo[self.PROVIDER_ID] = user.providerID as Any
            userInfo[self.PHOTO_URL] = user.photoURL as Any
            userInfo[self.REFRESH_TOKEN] = user.refreshToken as Any
            userInfo[self.SIGN_UP_TIME] = self.dateFormatter.string(from: Date()) as Any
            newUser[user.uid] = userInfo
            
            self.ref.child(self.USERS).updateChildValues(newUser)
            
            
        
            let emailArray = user.email?.components(separatedBy: "@")
            var childUpdates = [String: Any]()
            childUpdates[self.DISPLAY_NAME] = emailArray?[0] as Any
            self.ref.child(self.USERS).child(user.uid).updateChildValues(childUpdates)
            
            print("Sign Up success")
            
        }
    }
    
    @IBAction func backToSignIn(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

}
