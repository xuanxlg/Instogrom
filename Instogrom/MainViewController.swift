//
//  MainViewController.swift
//  Instogrom
//
//  Created by HuangShih-Hsuan on 27/03/2017.
//  Copyright © 2017 HuangShih-Hsuan. All rights reserved.
//

import UIKit
import Firebase

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func signOut(_ sender: Any) {
        try! FIRAuth.auth()?.signOut()
    }
    
    @IBAction func photo(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
//        picker.sourceType = .photoLibrary
//        
//        present(picker, animated: true, completion: nil)
        
//        let alert = UIAlertController(title: "TEST", message: "MESSAGE", preferredStyle: .alert)
//        
//        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
//        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
//        
//        alert.addAction(okAction)
//        alert.addAction(cancelAction)
        
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
        debugPrint(info)
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.image = image
        
        dismiss(animated: true, completion: nil)
    }
}
