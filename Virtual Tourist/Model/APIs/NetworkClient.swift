//
//  NetworkClient.swift
//  Virtual Tourist
//
//  Created by Ademola Fadumo on 23/06/2023.
//

import Foundation
import UIKit

class NetworkClient {
    struct Auth {
        static let apiKey = "a94042ba749226231a89ae4f6669dd5f"
    }
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest"
        static let apiKeyParam = "?api_key=\(Auth.apiKey)"
        static let responseFormat = "&format=json"
        
        case getPhotosBySearch(lat: Double, lon: Double, page: Int)
        
        var stringValue: String {
            switch self {
            case let .getPhotosBySearch(lat, lon, page):
                return "\(Endpoints.base)/\(Endpoints.apiKeyParam)" + "&method=flickr.photos.search" + Endpoints.responseFormat + "&lat=\(lat)" + "&lon=\(lon)" + "&page=\(page)" + "&nojsoncallback=1" + "&per_page=50"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    func getImage(url: URL, completion: @escaping (Data?) -> Void) -> URLSessionTask {
        return get(url: url, response: Data.self, skipDecoding: true) { response, error in
            if let data = response as? Data {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
    
    func getPhotosForLocation(lat: Double, lon: Double, page: Int = 1, completion: @escaping ([URL], Error?) -> Void) -> URLSessionTask {
        print(Endpoints.getPhotosBySearch(lat: lat, lon: lon, page: page).url)
        
        return get(url: Endpoints.getPhotosBySearch(lat: lat, lon: lon, page: page).url, response: FlickrPhotoSearchResponse.self) { response, error in
            if let response = response as? FlickrPhotoSearchResponse {
                
                var imageUrls: [URL] = []
                
                response.photos.photo.forEach { element in
                    if let url = self.constructURLs(serverId: element.server, id: element.id, secret: element.secret) {
                        imageUrls.append(url)
                    } else {
                        print("Error occurred fetching for \(element)")
                    }
                }
                
                completion(imageUrls, error)
            } else {
                completion([], error)
            }
        }
    }
    
    private func constructURLs(serverId: String, id: String, secret: String) -> URL? {
        return URL(string: "https://live.staticflickr.com/\(serverId)/\(id)_\(secret)_w.jpg")
    }
    
    @discardableResult
    private func get<ResponseType: Decodable>(url: URL, response: ResponseType.Type, skipDecoding: Bool = false, completion: @escaping (Any?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            do {
                if skipDecoding {
                    DispatchQueue.main.async {
                        completion(data, nil)
                    }
                } else {
                    let responseObject = try JSONDecoder().decode(ResponseType.self, from: data)
                    
                    DispatchQueue.main.async {
                        completion(responseObject, nil)
                    }
                }
            } catch {
                
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
        return task
    }
}
