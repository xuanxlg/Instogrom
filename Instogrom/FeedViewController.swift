//
//  FeedViewController.swift
//  Instogrom
//
//  Created by HuangShih-Hsuan on 30/03/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseDatabaseUI
import SDWebImage
import SVProgressHUD

class FeedViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let POSTS: String = "posts"
    let AUTHOR_UID: String = "authorUID"
    let EMAIL: String = "email"
    let IMAGE_PATH: String = "imagePath"
    let IMAGE_URL: String = "imageURL"
    let POST_DATE: String = "postDate"
    let POST_DATE_REVERSED: String = "postDateReversed"
    let POST_IMAGES: String = "post_images"
    
    let dateFormatter = DateFormatter()
    
    var ref: FIRDatabaseReference!
    var postsRef: FIRDatabaseReference!
    
    var dataSource: FUITableViewDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()

        ref = FIRDatabase.database().reference()
        postsRef = ref.child(POSTS)
        
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 320
        
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.delegate = self as? UIGestureRecognizerDelegate
        tableView.addGestureRecognizer(longPressGesture)
        
        let query = postsRef.queryOrdered(byChild: POST_DATE_REVERSED)
        dataSource = tableView.bind(to: query) { (tableView, indexPath, snapshot) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
            
            cell.postKey = snapshot.key
            if let postData = snapshot.value as? [String: Any] {
                cell.email.text = postData[self.EMAIL] as? String
                debugPrint("\(postData[self.POST_DATE]!)")
                let postDate = (postData[self.POST_DATE] as! Int) / 1000
                cell.publishTime.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(postDate)))
                
                let imageURLString = postData[self.IMAGE_URL] as! String
                let imageURL = URL(string: imageURLString)!
                cell.photoImage.sd_setImage(with: imageURL)
            }
            
            return cell
        }
//        ref.observe(.value, with: { snapshot in
//            if let value = snapshot.value as? [String: Any] {
//                debugPrint(value)
//            }
        //        })
        ref.observe(.childAdded, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                debugPrint(value)
            }
        })
        
        ref.observe(.childChanged, with: { snapshot in
            if let value = snapshot.value as? [String: Any] {
                debugPrint(value)
            }
        })
    }
    
    func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let selectedCell = tableView.cellForRow(at: indexPath) as! PostCell
                debugPrint("selectedCell.postKey: \(selectedCell.postKey)")
                debugPrint("selectedCell.email: \(selectedCell.email.text!)")
                debugPrint("selectedCell.publishTime: \(selectedCell.publishTime.text!)")
                
                let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                let deleteAction = UIAlertAction(title: "Delete", style: .default) { anctopn in
                    self.ref.child(self.POSTS).child(selectedCell.postKey).removeValue()
                    
                    let imageRef = FIRStorage.storage().reference().child("\(self.POST_IMAGES)/\(selectedCell.postKey).jpg")
                    imageRef.delete { error in
                        if let error = error {
                            debugPrint("File Delete Fail: \(error)")
                        } else {
                            debugPrint("File Delete Successfully")
                        }
                    }
                }
                actionSheet.addAction(deleteAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { anctopn in
                    
                }
                actionSheet.addAction(cancelAction)
                
                present(actionSheet, animated: true, completion: nil)
                
            }
        }
    }


    @IBAction func signOut(_ sender: Any) {
        try! FIRAuth.auth()?.signOut()
    }
    
    @IBAction func photo(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { anctopn in
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
            }
            
            actionSheet.addAction(cameraAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let photoAction = UIAlertAction(title: "Photo", style: .default) { anctopn in
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
        
        let postsRef = self.postsRef.childByAutoId()
        let postKey = postsRef.key
        
        if FIRAuth.auth()?.currentUser == nil {
            return
        }
        
        //        let imageData = UIImagePNGRepresentation(image)
        if let imageData = UIImageJPEGRepresentation(image, 0.7) {
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let imageRef = FIRStorage.storage().reference().child("\(POST_IMAGES)/\(postKey).jpg")
            
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
                let postDate = Int(metadata.timeCreated!.timeIntervalSince1970 * 1000)
                
                var post = [String: Any]()
                var content = [String: Any]()
                content[self.AUTHOR_UID] = user.uid
                content[self.EMAIL] = user.email!
                content[self.IMAGE_PATH] = imageRef.fullPath
                content[self.IMAGE_URL] = String(describing: metadata.downloadURL()!)
                content[self.POST_DATE] = postDate
                content[self.POST_DATE_REVERSED] = -postDate
                post[postKey] = content
                
                self.ref.child(self.POSTS).updateChildValues(post)
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
    
}
