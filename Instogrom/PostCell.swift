//
//  PostCell.swift
//  Instogrom
//
//  Created by HuangShih-Hsuan on 06/04/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit

class PostCell: UITableViewCell {
    
    var postKey: String = ""
    
    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var publishTime: UILabel!
    @IBOutlet weak var photoImage: UIImageView!
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var postContent: UILabel!
    
}
