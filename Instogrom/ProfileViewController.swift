//
//  ProfileViewController.swift
//  Instogrom
//
//  Created by HuangShih-Hsuan on 11/04/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseDatabaseUI
import SDWebImage
import SVProgressHUD

class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let USERS: String = "users"
    let EMAIL: String = "email"
    let IS_EMAIL_VERIFIED: String = "is_email_verified"
    let DISPLAY_NAME: String = "display_name"
    let PROVIDER_ID: String = "provider_id"
    let PHOTO_URL: String = "photo_url"
    let REFRESH_TOKEN: String = "refresh_token"
    let SIGN_UP_TIME: String = "sign_up_time"
    
    let dateFormatter = DateFormatter()
    
    var ref: FIRDatabaseReference!
    
    var dataSource: FUITableViewDataSource!
    
    @IBOutlet weak var userIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()

        DispatchQueue.main.async {
            self.userIcon.frame.size = CGSize(width: (self.userIcon.frame.size.width), height: (self.userIcon.frame.size.width))
            
            let user = (FIRAuth.auth()?.currentUser)!
            self.ref.child(self.USERS).child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? NSDictionary
                
                DispatchQueue.main.async {
                    let url = URL(string: value?[self.PHOTO_URL] as! String)
                    self.showPhoto(url: url!)
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
        
    }

    @IBAction func photo(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "User photo by Camera", style: .default) { anctopn in
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            }
            
            actionSheet.addAction(cameraAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let photoAction = UIAlertAction(title: "User photo by Photo Library", style: .default) { anctopn in
                picker.sourceType = .photoLibrary
                self.present(picker, animated: true, completion: nil)
            }
            
            actionSheet.addAction(photoAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { anctopn in
            
        }
        
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        if FIRAuth.auth()?.currentUser == nil {
            return
        }
        
        //        let imageData = UIImagePNGRepresentation(image)
        if let imageData = UIImageJPEGRepresentation(image, 0.7) {
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let imageRef = FIRStorage.storage().reference().child("user.jpg")
            
            SVProgressHUD.setDefaultMaskType(.black)
            SVProgressHUD.showProgress(0, status: "Uploading...")
            
            let uploadTask = imageRef.put(imageData, metadata: metadata) { metadata, error in
                
                SVProgressHUD.dismiss()
                
                guard let metadata = metadata else {
                    debugPrint("Uploaded Fail")
                    return
                }
                
                debugPrint(metadata.downloadURL()!)
                debugPrint("Uploaded")
                
                let user = (FIRAuth.auth()?.currentUser)!
                self.ref.child(self.USERS).child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    
                    var currentUser = [String: Any]()
                    var userInfo = [String: Any]()
                    userInfo[self.EMAIL] = user.email as Any
                    userInfo[self.IS_EMAIL_VERIFIED] = value?[self.IS_EMAIL_VERIFIED] as Any
                    userInfo[self.DISPLAY_NAME] = value?[self.DISPLAY_NAME] as Any
                    userInfo[self.PROVIDER_ID] = value?[self.PROVIDER_ID] as Any
                    userInfo[self.PHOTO_URL] = metadata.downloadURL()?.absoluteString as Any
                    userInfo[self.REFRESH_TOKEN] = value?[self.REFRESH_TOKEN] as Any
                    userInfo[self.SIGN_UP_TIME] = value?[self.SIGN_UP_TIME] as Any
                    currentUser[user.uid] = userInfo
                    
                    self.ref.child(self.USERS).updateChildValues(currentUser)
                    
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
                
                self.showPhoto(url: metadata.downloadURL()!)
                
            }
            
            uploadTask.observe(.progress, handler: { (snapshot) in
                guard let progress = snapshot.progress else {
                    return
                }
                
                SVProgressHUD.showProgress(Float(progress.fractionCompleted), status: "Uploading...")
            })
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func showPhoto(url: URL) {
        print("url: \(url)")
        if url != nil {
            // Creating a session object with the default configuration.
            // You can read more about it here https://developer.apple.com/reference/foundation/urlsessionconfiguration
            let session = URLSession(configuration: .default)
            
            SVProgressHUD.setDefaultMaskType(.black)
            SVProgressHUD.show()
            
            // Define a download task. The download task will download the contents of the URL as a Data object and then you can do what you wish with that data.
            let downloadPicTask = session.dataTask(with: url) { (data, response, error) in
                
                SVProgressHUD.dismiss()
                
                // The download has finished.
                if let e = error {
                    print("Error downloading cat picture: \(e)")
                } else {
                    // No errors found.
                    // It would be weird if we didn't have a response, so check for that too.
                    if let res = response as? HTTPURLResponse {
                        print("Downloaded cat picture with response code \(res.statusCode)")
                        if let imageData = data {
                            // Finally convert that Data into an image and do what you wish with it.
                            //                            self.imageView.image = UIImage(data: imageData)
                            DispatchQueue.main.async {
                                let urlImage = UIImage(data: imageData)
                                
                                self.userIcon.image = urlImage
                            }
                            
                            // Do something with your image.
                        } else {
                            print("Couldn't get image: Image is nil")
                        }
                    } else {
                        print("Couldn't get response code for some reason")
                    }
                }
            }
            
            downloadPicTask.resume()
        }
    }
    
    @IBAction func resetPassword(_ sender: Any) {
        self.showAlert(title: "Reset Password", message: "Confirm to reset password?", buttons: 2)
    }
    
    private func showAlert(title: String, message: String, buttons: Int) {
        let actionSheetController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if (buttons == 1) {
            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(cancelAction)
        } else {
            let okAction: UIAlertAction = UIAlertAction(title: "Confirm", style: .default) { action -> Void in
                
                FIRAuth.auth()?.sendPasswordReset(withEmail: (FIRAuth.auth()?.currentUser)!.email!, completion: { error in
                    if let error = error {
                        self.showAlert(title: "Error", message: "\(error)", buttons: 1)
                    } else {
                        self.showAlert(title: "Password Reset Successfully", message: "Please receive the e-mail and reset password", buttons: 1)
                    }
                })
                
            }
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancle", style: .cancel) { action -> Void in
                //Just dismiss the action sheet
            }
            actionSheetController.addAction(okAction)
            actionSheetController.addAction(cancelAction)
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    @IBAction func signOutButton(_ sender: Any) {
        try! FIRAuth.auth()?.signOut()
    }

}
