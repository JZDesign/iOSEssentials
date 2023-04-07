//
//  RemoteFeedLoader.swift
//  
//
//  Created by Jacob Rakidzich on 3/31/23.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    let url: URL
    let client: HttpClient

    public init( url: URL, client: HttpClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (RemoteFeedLoader.Result) -> Void) {
        client.get(from: url) { [weak self] in
            guard self != nil else { return }
            switch $0 {
            case .success(let (data, response)):
                completion(Self.map(data, from: response))
            case .failure(_):
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let models = try decodeResponse(data, from: response).map(\.feedItem)
            return .success(models)
        } catch {
            return .failure(error)
        }
    }

    private static var OK_200: Int { 200 }

    static func decodeResponse(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        do {
            guard response.statusCode == OK_200 else {
                throw RemoteFeedLoader.Error.invalidData
            }
            return try JSONDecoder()
                .decode(FeedItemRoot.self, from: data)
                .items
                  
        } catch {
            throw RemoteFeedLoader.Error.invalidData
        }
    }

    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
}

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}

struct FeedItemRoot: Decodable {
    let items: [RemoteFeedItem]
}

fileprivate extension RemoteFeedItem {
    var feedItem: FeedItem {
        .init(id: id, description: description, location: location, imageURL: image)
    }
}
