//
//  StockPhotoService.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-19.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation

typealias StockPhotoSearchCompletionBlock = (Result<StockPhotoResults, Error>) -> Void

protocol StockPhotoService: class {
    /// An internal identifier for this service.
    static var identifier: String { get }
    
    /// The user-friendly name of this stock photo service (e.g. Shutterstock).
    static var name: String { get }
    
    /**
    Get stock photos with the provided information.

    - parameter query: The string to query the service with.
    - parameter paginationToken: If applicable, a token with context about pagination, from the last retrieved results. See more on `StockPhotoResults.paginationToken`.
    - parameter completion: A block to run on completion.
     
     - returns: An object representing the search request being made. See `StockPhotoSearchRequest`.
         */
    func search(with query: String, count: Int, after paginationToken: String?, completion: @escaping StockPhotoSearchCompletionBlock) -> StockPhotoSearchRequest?
}

/// Optional methods on the search request being made, such as cancellation.
protocol StockPhotoSearchRequest {
    /// A method which will cancel the running request, if necessary.
    func cancel()
}

/// A pre-made search request that allows you to create a custom completion handler representing a network search's data task.
class StockPhotoSearchNetworkRequest: StockPhotoSearchRequest {
    let dataTask: URLSessionDataTask
    
    init(dataTask: URLSessionDataTask) {
        self.dataTask = dataTask
        dataTask.resume()
    }
    
    convenience init(urlRequest: URLRequest, completion: @escaping (Result<Data, Error>, URLResponse?) -> Void) {
        self.init(dataTask: URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else { completion(.failure(error ?? StockPhotoSearchError.noData), response); return }
            completion(.success(data), response)
        })
    }
    
    convenience init(url: URL, completion: @escaping (Result<Data, Error>, URLResponse?) -> Void) {
        self.init(urlRequest: URLRequest(url: url), completion: completion)
    }
    
    convenience init<T: Decodable>(jsonType: T.Type, urlRequest: URLRequest, completion: @escaping (Result<T, Error>, URLResponse?) -> Void) {
        self.init(urlRequest: urlRequest, completion: { (result, response) in
            do {
                let data = try result.get()
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded), response)
            } catch let error {
                completion(.failure(error), response)
            }
        })
    }

    convenience init<T: Decodable>(jsonType: T.Type,url: URL, completion: @escaping (Result<T, Error>, URLResponse?) -> Void) {
        self.init(jsonType: jsonType, urlRequest: URLRequest(url: url), completion: completion)
    }
    
    convenience init<T: Decodable & StockPhotoResultsProviding>(jsonResultsProvidingType: T.Type, urlRequest: URLRequest, completion: @escaping (Result<StockPhotoResults, Error>) -> Void) {
        self.init(jsonType: T.self, urlRequest: urlRequest, completion: { (result, response) in
            switch result {
            case .success(let response): completion(.success(response.results))
            case .failure(let error): completion(.failure(error))
            }
        })
    }
    
    convenience init<T: Decodable & StockPhotoResultsProviding>(jsonResultsProvidingType: T.Type,url: URL, completion: @escaping (Result<StockPhotoResults, Error>) -> Void) {
        self.init(jsonResultsProvidingType: jsonResultsProvidingType, urlRequest: URLRequest(url: url), completion: completion)
    }
    
    func cancel() {
        dataTask.cancel()
    }
}

protocol StockPhotoResultsProviding {
    var results: StockPhotoResults { get }
}

enum StockPhotoSearchError: Error {
    /// No data was retrieved during the search, but there is no more approprate error to display.
    case noData
    /// An unknown error occurred during deserialization.
    case deserializationError
    /// A URL could not be formed to create a network request.
    case noValidURL
}
