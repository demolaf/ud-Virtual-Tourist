//
//  FlickrPhotoSearchResponse.swift
//  Virtual Tourist
//
//  Created by Ademola Fadumo on 23/06/2023.
//

import Foundation

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let flickrPhotoSearchResponse = try? JSONDecoder().decode(FlickrPhotoSearchResponse.self, from: jsonData)

// MARK: - FlickrPhotoSearchResponse
struct FlickrPhotoSearchResponse: Codable {
    let photos: FlickrPhotos
    let stat: String
}

// MARK: - Photos
struct FlickrPhotos: Codable {
    let page, pages, perpage, total: Int
    let photo: [FlickrPhoto]
}

// MARK: - Photo
struct FlickrPhoto: Codable {
    let id: String
    let secret, server: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
}
