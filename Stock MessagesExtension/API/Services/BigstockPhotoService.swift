//
//  ShutterstockService.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation

class BigstockPhotoService: StockPhotoService {
    static let identifier = "BigstockPhoto"
    static let name = "Bigstock"
    
    struct Response: Codable, StockPhotoResultsProviding {
        let images: [Image]
        let nextStart: Int?
        
        struct Image: Codable {
            let url: String
            let displayTitle: String?
            
            enum CodingKeys: String, CodingKey {
                case url, displayTitle = "display_title"
            }
            
            var stockPhoto: StockPhoto {
                return StockPhoto(thumbnailURL: nil, fullImageURL: URL(string: url)!, alternativeText: displayTitle)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case images = "results", nextStart = "next_start"
        }
        
        var results: StockPhotoResults {
            return StockPhotoResults(photos: images.map { $0.stockPhoto }, paginationToken: nextStart.map { String($0) })
        }
    }
    
    func search(with query: String, count: Int, after paginationToken: String?, completion: @escaping (Result<StockPhotoResults, Error>) -> Void) -> StockPhotoSearchRequest? {
        // We encode the query (which is a path param) using url query allowed character set because slashes should be encoded
        let urlStr = "https://www.bigstockphoto.com/search/\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")/?start=\(paginationToken?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&show=\(count)&photos=y"
        guard let url = URL(string: urlStr) else { completion(.failure(StockPhotoSearchError.noValidURL)); return nil }
        
        var request = URLRequest(url: url)
        request.addValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With") // gives us JSON instead of the web page
        
        return StockPhotoSearchNetworkRequest(jsonResultsProvidingType: Response.self, urlRequest: request, completion: completion)
    }
}
