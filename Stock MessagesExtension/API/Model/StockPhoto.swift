//
//  StockPhoto.swift
//  Stock MessagesExtension
//
//  Created by Ayden Panhuyzen on 2019-07-20.
//  Copyright © 2019 Ayden Panhuyzen. All rights reserved.
//

import Foundation

struct StockPhoto: Codable, Hashable {
    let thumbnailURL: URL?, fullImageURL: URL
    let alternativeText: String?
}

struct StockPhotoResults {
    /// The photos retrieved as part of this request.
    let photos: [StockPhoto]
    /**
     A token that can be used to provide information required to retrieve the next page, such as the last photo's ID or the offset from the previous request.
     
     If not provided, pagination cannot be performed, such as if a service does not perform pagination or has reached the end of the returnable photos.
     */
    let paginationToken: String?
}
