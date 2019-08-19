//
//  ShutterstockService.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation

class AdobeService: StockPhotoService {
    static let identifier = "Adobe"
    static let name = "Adobe Stock"
    
    struct Response: Codable, StockPhotoResultsProviding {
        let items: [String: Image]
        let page: Int, totalPages: Int
        
        struct Image: Codable {
            let thumbnailURL: String, fullURL: String
            let title: String?
            
            enum CodingKeys: String, CodingKey {
                case title, thumbnailURL = "thumbnail_url", fullURL = "content_thumb_large_url"
            }
            
            var stockPhoto: StockPhoto {
                return StockPhoto(thumbnailURL: URL(string: thumbnailURL), fullImageURL: URL(string: fullURL)!, alternativeText: title)
            }
            
        }
        
        enum CodingKeys: String, CodingKey {
            case items, page = "search_page", totalPages = "num_pages"
        }
        
        var paginationToken: String? {
            guard page < totalPages else { return nil }
            return String(page + 1)
        }
        
        var results: StockPhotoResults {
            return StockPhotoResults(photos: items.values.map { $0.stockPhoto }, paginationToken: paginationToken)
        }
    }
    
    func search(with query: String, count: Int, after paginationToken: String?, completion: @escaping (Result<StockPhotoResults, Error>) -> Void) -> StockPhotoSearchRequest? {
        var components = URLComponents(string: "https://stock.adobe.com/Ajax/Search?filters%5Bcontent_type%3Aphoto%5D=1&filters%5Bcontent_type%3Aillustration%5D=0&filters%5Bcontent_type%3Azip_vector%5D=0&filters%5Bcontent_type%3Avideo%5D=0&filters%5Bcontent_type%3Atemplate%5D=0&filters%5Bcontent_type%3A3d%5D=0&filters%5Binclude_stock_enterprise%5D=0&filters%5Bcontent_type%3Aimage%5D=1&filters%5Bis_editorial%5D=0&order=relevance&safe_search=1&search_type=usertyped")!
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "k", value: query))
        queryItems.append(URLQueryItem(name: "search_page", value: paginationToken))
        queryItems.append(URLQueryItem(name: "limit", value: String(count)))
        components.queryItems = queryItems
        guard let url = components.url else { completion(.failure(StockPhotoSearchError.noValidURL)); return nil }
        
        return StockPhotoSearchNetworkRequest(jsonResultsProvidingType: Response.self, url: url, completion: completion)
    }
}
