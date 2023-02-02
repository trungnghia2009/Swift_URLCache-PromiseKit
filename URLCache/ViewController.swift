//
//  ViewController.swift
//  URLCache
//
//  Created by trungnghia on 01/02/2023.
//

import UIKit
import PromiseKit

final class ViewController: UIViewController {
    
    @IBOutlet weak var downloadBtn: UIButton!
    
    let imageURL1 = URL(string: "https://rickandmortyapi.com/api/character/avatar/1.jpeg")!
    let imageURL2 = URL(string: "https://rickandmortyapi.com/api/character/avatar/2.jpeg")!
    let imageURL3 = URL(string: "https://rickandmortyapi.com/api/character/avatar/3.jpeg")!
    
    let imageRepository: ImageRepository = ImageRepository()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // First time download
        dowloadImage(imageURL: imageURL1)
        dowloadImage(imageURL: imageURL2)
        dowloadImage(imageURL: imageURL3)
        dowloadImage(imageURL: imageURL1)
        dowloadImage(imageURL: imageURL2)
        dowloadImage(imageURL: imageURL3)
    }
    
    private func dowloadImage(imageURL: URL) {
        firstly {
            imageRepository.getImage(imageURL: imageURL)
        }.done { image in
            if let image = image {
                print("Got image: \(image.size), thread: \(Thread.current)")
            }
        }.catch { error in
            print("Image Error: \(error)")
        }
    }
    
    // Action for loading from cache
    @IBAction func didTapDownloadBtn(_ sender: Any) {
        print("")
        dowloadImage(imageURL: imageURL1)
    }
    
}

