//
//  ShutterstockService.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation

class iStockPhotoService: StockPhotoService {
    static let identifier = "iStock"
    static let name = "iStock"
    
    struct Response: Codable, StockPhotoResultsProviding {
        let assets: [Image]
        let page: Int, lastPage: Int
        
        struct Image: Codable {
            let thumbUrl: String
            let previewUrl: String
            let caption: String?

            var stockPhoto: StockPhoto {
                let previewUrlNoQuery = previewUrl.firstIndex(of: "?").map { String(previewUrl[previewUrl.startIndex..<$0]) } ?? previewUrl
                let thumbnailURL = URL(string: thumbUrl)!
                return StockPhoto(thumbnailURL: thumbnailURL, fullImageURL: URL(string: previewUrlNoQuery)!, alternativeText: caption)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case assets, page, lastPage = "last_page"
        }
        
        var paginationToken: String? {
            guard page < lastPage else { return nil }
            return String(page + 1)
        }
    
        var results: StockPhotoResults {
            return StockPhotoResults(photos: assets.map { $0.stockPhoto }, paginationToken: paginationToken)
        }
    }
    
    private var withheldItems = [StockPhoto]()
    private var latestQuery: String? {
        didSet {
            guard oldValue != latestQuery else { return }
            withheldItems.removeAll()
        }
    }
    
    func search(with query: String, count: Int, after paginationToken: String?, completion: @escaping (Result<StockPhotoResults, Error>) -> Void) -> StockPhotoSearchRequest? {
        // they don't let us set how many images we get, so we'll fake it!
        func fakePagination(results: StockPhotoResults?) {
            let allItems = withheldItems + (results?.photos ?? [])
            let items = Array(allItems.prefix(count))
            completion(.success(StockPhotoResults(photos: items, paginationToken: results?.paginationToken ?? paginationToken)))
            withheldItems = Array(allItems.dropFirst(count))
        }
        
        latestQuery = query
        guard withheldItems.count < count else { fakePagination(results: nil); return nil }
        
        var components = URLComponents(string: "https://www.istockphoto.com/us/search/2/image?excludenudity=true&assettype=image&mediatype=photography&sort=best")!
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "phrase", value: query))
        queryItems.append(URLQueryItem(name: "page", value: paginationToken))
        components.queryItems = queryItems
        guard let url = components.url else { completion(.failure(StockPhotoSearchError.noValidURL)); return nil }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept") // gives us JSON instead of JSONP(?)
        
        return StockPhotoSearchNetworkRequest(jsonResultsProvidingType: Response.self, urlRequest: request, completion: { (result) in
            switch result {
            case .success(let results): fakePagination(results: results)
            default: completion(result)
            }
        })
    }
}
