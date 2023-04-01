//
//  FeedItemsMapper.swift
//  
//
//  Created by Jacob Rakidzich on 3/31/23.
//

import Foundation

internal struct FeedItemsMapper {
    private static var OK_200: Int { 200 }

    internal static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        do {
            guard response.statusCode == OK_200 else {
                throw RemoteFeedLoader.Error.invalidData
            }
            let items = try JSONDecoder()
                .decode(RemoteFeedLoader.FeedItemRoot.self, from: data)
                .items
                .map(\.item)
            
            return .success(items)
        } catch {
            return .failure(.invalidData)
        }
    }
}

fileprivate extension RemoteFeedLoader.Item { 
    var item: FeedItem {
        .init(id: id, description: description, location: location, imageURL: image)
    }
}
