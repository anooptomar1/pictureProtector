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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(sharePhoto))
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
            
            vw.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(faceTapped)))
            
            //color its border red and add it to the view
            vw.layer.borderColor = UIColor.red.cgColor
            vw.layer.borderWidth = 2
            imageView.addSubview(vw)
        }
    }
    
    func renderBlurredFaces() {
        
        guard let currentUIImage = inputImage else { return }
        guard let currentCGImage = currentUIImage.cgImage else { return }
        let currentCIImage = CIImage(cgImage: currentCGImage)
        
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(currentCIImage, forKey: kCIInputImageKey)
        filter?.setValue(12, forKey: kCIInputScaleKey)
        
        guard let outputImage = filter?.outputImage else { return }
        
        let blurredImage = UIImage(ciImage: outputImage)
        
        //prepare to render a new image at the full size we need
        let renderer = UIGraphicsImageRenderer(size: currentUIImage.size)
        
        //commence rendering
        let result = renderer.image { ctx in
            
            //draw the original image first
            currentUIImage.draw(at: .zero)
            
            //create an empty clipping path that will hold our faces
            let path = UIBezierPath()
            
            for face in detectedFaces {
                //if this face should be blurred...
                if face.blur {
                    //calculate the position of this face in image coordinates
                    let boundingBox = face.observation.boundingBox
                    let size = CGSize(width: boundingBox.width * currentUIImage.size.width, height: boundingBox.height * currentUIImage.size.height)
                    let origin = CGPoint(x: boundingBox.minX * currentUIImage.size.width, y: (1 - face.observation.boundingBox.minY) * currentUIImage.size.height - size.height)
                    let rect = CGRect(origin: origin, size: size)
                    
                    //convert those coordinates to a path, and add it to our clipping path
                    let miniPath = UIBezierPath(rect: rect)
                    path.append(miniPath)
                }
            }
            //if our clipping path isn't empty, activate it now then draw the blurred image with that mask
            if !path.isEmpty {
                path.addClip()
                blurredImage.draw(at: .zero)
            }
        }
        //show the result in our image view
        imageView.image = result
    }
    
    @objc func faceTapped(_ sender: UITapGestureRecognizer) {
        guard let vw = sender.view else { return }
        detectedFaces[vw.tag].blur = !detectedFaces[vw.tag].blur
        renderBlurredFaces()
    }
    
    @objc func sharePhoto() {
        guard let img = imageView.image else { return }
        let ac = UIActivityViewController(activityItems: [img], applicationActivities: nil)
        
        present(ac, animated: true)
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
















