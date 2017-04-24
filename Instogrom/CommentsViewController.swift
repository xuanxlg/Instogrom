//
//  CommentsViewController.swift
//  Instogrom
//
//  Created by HuangShih-Hsuan on 18/04/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseDatabaseUI
import SDWebImage

class CommentsViewController: UIViewController, UITableViewDelegate {
    
    let USERS: String = "users"
    let POSTS: String = "posts"
    let AUTHOR_UID: String = "authorUID"
    let EMAIL: String = "email"
    let PHOTO_URL: String = "photo_url"
    let COMMENTS: String = "comments"
    let COMMENT: String = "comment"
    let POST_DATE: String = "postDate"
    
    var postKey: String = ""
    @IBOutlet weak var tableView: UITableView!
    
    let dateFormatter = DateFormatter()
    
    var ref: FIRDatabaseReference!
    var messagesRef: FIRDatabaseReference!
    
    var dataSource: FUITableViewDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        debugPrint("postKey: \(postKey)")
        
        if postKey != "" {
            
            ref = FIRDatabase.database().reference()
            messagesRef = ref.child(COMMENTS)
            
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.estimatedRowHeight = 64
            
            let query = messagesRef.child(postKey).queryOrdered(byChild: POST_DATE)
            dataSource = tableView.bind(to: query) { (tableView, indexPath, snapshot) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
                
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
                    
                    cell.userEmail.text = postData[self.EMAIL] as? String
                    
                    debugPrint("\(postData[self.POST_DATE]!)")
                    let postDate = (postData[self.POST_DATE] as! Int) / 1000
                    cell.userPublished.text = self.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(postDate)))
                    
                    if postData[self.COMMENT] != nil {
                        cell.userMessage.text = postData[self.COMMENT] as? String
                    }
                }
                
                self.tableView.refreshControl?.endRefreshing()
                
                return cell
            }
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
