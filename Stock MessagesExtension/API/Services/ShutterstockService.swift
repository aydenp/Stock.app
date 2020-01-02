//
//  ShutterstockService.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation

class ShutterstockService: StockPhotoService {
    static let identifier = "Shutterstock"
    static let name = "Shutterstock"
    
    struct Response: Codable, StockPhotoResultsProviding {
        let data: [Image]
        let meta: Meta
        
        struct Image: Codable {
            let attributes: Attributes
            
            var stockPhoto: StockPhoto {
                return StockPhoto(thumbnailURL: attributes.displays.thumbnail.url, fullImageURL: attributes.displays.full.url, alternativeText: attributes.alt)
            }
            
            struct Attributes: Codable {
                let displays: Displays
                let alt: String?
            
                struct Displays: Codable {
                    let thumbnail: DisplayImage, full: DisplayImage
                    
                    enum CodingKeys: String, CodingKey {
                        // if it weren't 4 am i'd check if these can change (probably)
                        case thumbnail = "260nw", full = "1500w"
                    }
                    
                    struct DisplayImage: Codable {
                        let src: String, width: Float, height: Float
                        
                        var url: URL! {
                            return URL(string: src)
                        }
                    }
                }
            }
        }
        
        struct Meta: Codable {
            let pagination: Pagination
            
            struct Pagination: Codable {
                let pageNumber: Int
                let totalPages: Int
                
                enum CodingKeys: String, CodingKey {
                    case pageNumber = "page_number", totalPages = "total_pages"
                }
                
                var token: String? {
                    guard pageNumber <= totalPages else { return nil }
                    return String(pageNumber + 1)
                }
            }
        }
        
        var results: StockPhotoResults {
            return StockPhotoResults(photos: data.map { $0.stockPhoto }, paginationToken: meta.pagination.token)
        }
    }
    
    func search(with query: String, count: Int, after paginationToken: String?, completion: @escaping (Result<StockPhotoResults, Error>) -> Void) -> StockPhotoSearchRequest? {
        var components = URLComponents(string: "https://www.shutterstock.com/studioapi/images/search?allow_inject=true&fields%5Bimages%5D=displays&fields%5Bimages%5D=alt&filter%5Bimage_type%5D=photo")!
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "q", value: query))
        if let number = paginationToken { queryItems.append(URLQueryItem(name: "page[number]", value: number)) }
        queryItems.append(URLQueryItem(name: "page[size]", value: String(count)))
        components.queryItems = queryItems
        guard let url = components.url else { completion(.failure(StockPhotoSearchError.noValidURL)); return nil }
        
        return StockPhotoSearchNetworkRequest(jsonResultsProvidingType: Response.self, url: url, completion: completion)
    }
}
