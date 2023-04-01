//
//  RemoteFeedLoader.swift
//  
//
//  Created by Jacob Rakidzich on 3/31/23.
//

import Foundation

public final class RemoteFeedLoader {
    let url: URL
    let client: HttpClient

    public init( url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (RemoteFeedLoader.Result) -> Void = { _ in }) {
        client.get(from: url) { [weak self] in
            guard let self else { return }
            switch $0 {
            case .success(let (data, response)):
                completion(FeedItemsMapper.map(data, from: response))
            case .failure(_):
                completion(.failure(.connectivity))
            }
        }
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = Swift.Result<[FeedItem], RemoteFeedLoader.Error>
}

internal extension RemoteFeedLoader {
    struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
    }
    
    struct FeedItemRoot: Decodable {
        let items: [Item]
    }
}
