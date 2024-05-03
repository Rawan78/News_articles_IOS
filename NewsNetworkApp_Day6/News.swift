//
//  News.swift
//  NewsNetworkApp_Day6
//
//  Created by Rawan Elsayed on 29/04/2024.
//

import Foundation

class News : Codable{
    var author: String?
    var title: String?
    var desription: String?
    var imageUrl: String?
    var url: String?
    var publishedAt: String?
    
    enum KeyConversion : String , CodingKey{
        case author = "author"
        case title = "title"
        case desription = "desription"
        case imageUrl = "imageUrl"
        case url = "url"
        case publishedAt = "publishedAt"
    }
}
