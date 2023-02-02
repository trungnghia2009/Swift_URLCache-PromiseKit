//
//  ImageRepository.swift
//  URLCache
//
//  Created by trungnghia on 02/02/2023.
//

import Foundation
import PromiseKit

protocol ImageRepositoryProtocol {
    func getImage(imageURL: URL) -> Promise<UIImage?>
    func downloadImage(imageURL: URL) -> Promise<UIImage?>
    func loadImageFromCache(imageURL: URL) -> Promise<UIImage?>
}

private class EmptyPromise: Error {}

enum ImageErrorType: Error {
    case badStatusCode(code: Int)
    case imageCacheError
}

public class ImageRepository: ImageRepositoryProtocol {
    
    private let cache = URLCache.shared
    private let queue = DispatchQueue(label: "cache queue", attributes: .concurrent)
    
    /// Determine whether or not we should get the image from a network call or the cache
    /// - Parameter imageURL: Image url
    /// - Returns: Promise<UIImage?>
    func getImage(imageURL: URL) -> Promise<UIImage?> {
        let request = URLRequest(url: imageURL)
        
        if self.cache.cachedResponse(for: request) != nil {
            return self.loadImageFromCache(imageURL: imageURL)
        } else {
            return downloadImage(imageURL: imageURL)
        }
    }
    
    
    /// Deliver a UIImage that must be initialized from the data we received from the dataTask
    /// - Parameter imageURL: Image url
    /// - Returns: Promise<UIImage?>
    func downloadImage(imageURL: URL) -> Promise<UIImage?> {
        print("Download: \(imageURL.absoluteString)")
        return Promise { [weak self] seal in
            self?.handleDownload(seal, imageURL)
        }
    }
    
    private func handleDownload(_ seal: Resolver<UIImage?>, _ imageURL: URL) {
        let request = URLRequest(url: imageURL)
        
        let dataTask = URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
            // Check status code
            guard let response = response,
                  let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                seal.reject(ImageErrorType.badStatusCode(code: (response as? HTTPURLResponse)?.statusCode ?? 400))
                return
            }
            
            // Check data
            guard let data = data, error == nil else {
                seal.reject(error ?? URLError(.badServerResponse))
                return
            }
            
            // Store cachedData and correspond it to a url request
            let cachedData = CachedURLResponse(response: response, data: data)
            self?.cache.storeCachedResponse(cachedData, for: request)
            
            seal.fulfill(UIImage(data: data))
        }
        
        dataTask.resume()
    }
    
    /// Returns a cached url response that corresponds with the specified URL request
    /// - Parameter imageURL: Image url
    /// - Returns: Promise<UIImage?>
    func loadImageFromCache(imageURL: URL) -> Promise<UIImage?> {
        print("LoadCache: \(imageURL.absoluteString)")
        return Promise { [weak self] seal in
            self?.handleCacheLoad(seal, imageURL)
        }
    }
    
    private func handleCacheLoad(_ seal: Resolver<UIImage?>, _ imageURL: URL) {
        let request = URLRequest(url: imageURL)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let data = self?.cache.cachedResponse(for: request)?.data {
                seal.fulfill(UIImage(data: data))
            } else {
                seal.reject(ImageErrorType.imageCacheError)
            }
        }
    }
}
