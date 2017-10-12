//
//  ViewController.swift
//  PictureProtector
//
//  Created by Tinnell, Clay on 10/11/17.
//  Copyright © 2017 Tinnell, Clay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var inputImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Import", style: .plain, target: self, action: #selector(importPhoto))
    }
    
    @objc func importPhoto() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
        
        imageView.image = image
        inputImage = image
        
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UINavigationControllerDelegate {
    
}

