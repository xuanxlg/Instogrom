//
//  CommentCell.swift
//  Instogrom
//
//  Created by HuangShih-Hsuan on 18/04/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
    
    var author: String = ""

    @IBOutlet weak var userPhoto: UIImageView!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var userPublished: UILabel!
    @IBOutlet weak var userMessage: UILabel!
    
}
