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
    
    let USERS: String = "users"
    let POSTS: String = "posts"
    let COMMENTS: String = "comments"
    let COMMENT: String = "comment"
    let AUTHOR_UID: String = "authorUID"
    let EMAIL: String = "email"
    let IMAGE_PATH: String = "imagePath"
    let IMAGE_URL: String = "imageURL"
    let POST_DATE: String = "postDate"
    let POST_DATE_REVERSED: String = "postDateReversed"
    let POST_IMAGES: String = "post_images"
    let PHOTO_URL: String = "photo_url"
    let POST_CONTENT: String = "post_content"
    let LIKE_POST: String = "like_post"
    let LIKE_DATE: String = "like_date"
    
    let dateFormatter = DateFormatter()
    
    var ref: FIRDatabaseReference!
    var postsRef: FIRDatabaseReference!
    var messagesRef: FIRDatabaseReference!
    
    var dataSource: FUITableViewDataSource!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let selectedCell = tableView.cellForRow(at: indexPath!) as! PostCell
        debugPrint("selectedCell.messages: \(selectedCell.comments)")
        if selectedCell.comments > 0 {
            if segue.identifier == "showMessages" {
                let contentVC = segue.destination as! CommentsViewController
                contentVC.postKey = selectedCell.postKey
            }
        } else {
            
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ref = FIRDatabase.database().reference()
        postsRef = ref.child(POSTS)
        messagesRef = ref.child(COMMENTS)
        
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
                
                cell.author = postData[self.AUTHOR_UID] as! String
                
                self.ref.child(self.USERS).child(postData[self.AUTHOR_UID] as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    
                    if value?[self.PHOTO_URL] != nil {
                        DispatchQueue.main.async {
                            let imageURLString = value?[self.PHOTO_URL] as! String
                            let url = URL(string: imageURLString)!
                            cell.userPhoto.sd_setImage(with: url)
                        }
                    }
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
                
                cell.email.text = postData[self.EMAIL] as? String
                
                debugPrint("\(postData[self.POST_DATE]!)")
                let postDate = (postData[self.POST_DATE] as! Int) / 1000
                cell.publishTime.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(postDate)))
                
                let likes = (postData[self.LIKE_POST] as? [String: Any])?.count
                if likes != nil {
                    if likes! > 0 {
                        if likes! > 99 {
                            cell.likesCount.text = "99+"
                        } else {
                            cell.likesCount.text = "\(likes!)"
                        }
                    }
                }
                
                self.ref.child(self.POSTS).child(cell.postKey).child(self.LIKE_POST).child((FIRAuth.auth()?.currentUser)!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let userLiked = snapshot.value as? [String: Any]!
                    
                    if userLiked == nil {
                        cell.currentUserIsLike = false
                        cell.likeImage.isHighlighted = false
                        cell.likesCount.textColor = UIColor.red
                    } else {
                        cell.currentUserIsLike = true
                        cell.likeImage.isHighlighted = true
                        cell.likesCount.textColor = UIColor.white
                    }
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
                
                self.ref.child(self.COMMENTS).child(cell.postKey).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let commentsCount = (snapshot.value as? [String: Any])?.count
                    
                    if commentsCount != nil {
                        if commentsCount! > 0 {
                            
                            cell.comments = commentsCount!
                            
                            if commentsCount! > 99 {
                                cell.commentsCount.text = "99+"
                            } else {
                                cell.commentsCount.text = "\(commentsCount!)"
                            }
                            cell.commentView.isHidden = false
                        } else {
                            cell.commentView.isHidden = true
                        }
                    } else {
                        cell.commentView.isHidden = true
                    }
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
                
                let imageURLString = postData[self.IMAGE_URL] as! String
                let imageURL = URL(string: imageURLString)!
                cell.photoImage.sd_setImage(with: imageURL)
                
                if postData[self.POST_CONTENT] != nil {
                    cell.postContent.text = postData[self.POST_CONTENT] as? String
                }
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
                
                let user = (FIRAuth.auth()?.currentUser)!
                
                var likePostTitle = "Like / Unlike this Post"
                if selectedCell.currentUserIsLike {
                    likePostTitle = "Unlike this Post"
                } else {
                    likePostTitle = "Like this Post"
                }
                
                let likeAction = UIAlertAction(title: likePostTitle, style: .default) { anctopn in
                    var post = [String: Any]()
                    var content = [String: Any]()
                    content[self.LIKE_DATE] = self.dateFormatter.string(from: Date())
                    post[user.uid] = content
                    
                    if selectedCell.currentUserIsLike {
                        self.ref.child(self.POSTS).child(selectedCell.postKey).child(self.LIKE_POST).child(user.uid).removeValue()
                    } else {
                        self.ref.child(self.POSTS).child(selectedCell.postKey).child(self.LIKE_POST).updateChildValues(post)
                    }
                    
                }
                actionSheet.addAction(likeAction)
                
                let commentAction = UIAlertAction(title: "Comment", style: .default) { anctopn in
                    let alertController = UIAlertController(title: "Comment this post", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addTextField { (alertTextField : UITextField) in
                        alertTextField.placeholder = "your comment"
                    }
                    alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                    let submitAction = UIAlertAction(title: "Submit", style: UIAlertActionStyle.default) { anctopn in
                        let contentText = alertController.textFields![0].text
                        
                        let messageDate = Int(Date().timeIntervalSince1970 * 1000)
                        
                        var newMessage = [String: Any]()
                        var messageInfo = [String: Any]()
                        messageInfo[self.AUTHOR_UID] = user.uid
                        messageInfo[self.EMAIL] = user.email as Any
                        messageInfo[self.COMMENT] = contentText
                        messageInfo[self.POST_DATE] = messageDate
                        newMessage[String(messageDate)] = messageInfo
                        
                        self.ref.child(self.COMMENTS).child(selectedCell.postKey).updateChildValues(newMessage)
                        self.ref.child(self.POSTS).child(selectedCell.postKey).child(self.COMMENT).setValue(String(messageDate))
                    }
                    alertController.addAction(submitAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                actionSheet.addAction(commentAction)
                
                if selectedCell.author == user.uid {
                    let contentAction = UIAlertAction(title: "Edit Content", style: .default) { anctopn in
                        
                        let alertController = UIAlertController(title: "Edit Content", message: "Please enter post's content", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addTextField { (alertTextField : UITextField) in
                            alertTextField.placeholder = "Enter content"
                            alertTextField.text = selectedCell.postContent.text
                        }
                        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                        let submitAction = UIAlertAction(title: "Submit", style: UIAlertActionStyle.default) { anctopn in
                            let contentText = alertController.textFields![0].text
                            self.ref.child(self.POSTS).child(selectedCell.postKey).child(self.POST_CONTENT).setValue(contentText)
                        }
                        alertController.addAction(submitAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                    actionSheet.addAction(contentAction)
                    
                    
                    
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
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { anctopn in
                    
                }
                actionSheet.addAction(cancelAction)
                
                present(actionSheet, animated: true, completion: nil)
                
            }
        }
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
