//
//  ViewController.swift
//  PictureProtector
//
//  Created by Tinnell, Clay on 10/11/17.
//  Copyright © 2017 Tinnell, Clay. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var inputImage: UIImage?
    var detectedFaces = [(observation: VNFaceObservation, blur: Bool)]()
    
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
    
    func detectFaces() {
        guard let image = inputImage else { return }
        guard let ciImage = CIImage(image: image) else { return }
        
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                guard let observations = request.results as? [VNFaceObservation] else { return }
                self.detectedFaces = Array(zip(observations, [Bool](repeating: false, count: observations.count)))
                self.addBlurRects()
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func addBlurRects() {
        //remove any existing face rectangles
        imageView.subviews.forEach { $0.removeFromSuperview() }
        
        //find the size of the image inside the imageView
        let imageRect = imageView.contentClippingRect
        
        //loop over all the faces that were detectd
        for (index, face) in detectedFaces.enumerated() {
            //pull out the face position
            let boundingBox = face.observation.boundingBox
            
            //calculate its size
            let size = CGSize(width: boundingBox.width * imageRect.width, height: boundingBox.height * imageRect.height)
            
            //calculate its position
            var origin = CGPoint(x: boundingBox.minX * imageRect.width, y: (1 - face.observation.boundingBox.minY) * imageRect.height - size.height)
            
            //offset the position based on the content clipping rect
            origin.y += imageRect.minY
            
            //place a UIView there
            let vw = UIView(frame: CGRect(origin: origin, size: size))
            
            //store its face number as its tag
            vw.tag = index
            
            //color its border red and add it to the view
            vw.layer.borderColor = UIColor.red.cgColor
            vw.layer.borderWidth = 2
            imageView.addSubview(vw)
        }
    }
    
    override func viewDidLayoutSubviews() {
        addBlurRects()
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else { return }
        
        imageView.image = image
        inputImage = image
        
        dismiss(animated: true, completion: nil)
        self.detectFaces()
    }
}

extension ViewController: UINavigationControllerDelegate {
    
}
















