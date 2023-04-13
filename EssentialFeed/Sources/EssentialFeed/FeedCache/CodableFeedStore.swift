import Foundation

public class CodableFeedStore: FeedStore {
    let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
    
    // MARK: - FeedStore Implementation

    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURLSurvivingSelf = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeURLSurvivingSelf) else {
                completion(.empty)
                return
            }
            do {
                let cache = try JSONDecoder().decode(Cache.self, from: data)
                completion(.found(feed: cache.feed.map(\.toLocalFeedImage), timeStamp: cache.timeStamp))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeURLSurvivingSelf = self.storeURL
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeURLSurvivingSelf.path) else {
                return completion(nil)
            }
            do {
                try FileManager.default.removeItem(at: storeURLSurvivingSelf)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        let storeURLSurvivingSelf = self.storeURL
        queue.async(flags: .barrier) {
            do {
                let data = try JSONEncoder().encode(Cache(feed: items.map(CodableFeedImage.from), timeStamp: timeStamp))
                try data.write(to: storeURLSurvivingSelf)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}

private extension CodableFeedStore {
    struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timeStamp: Date
    }
}

public struct CodableFeedImage: Equatable, Codable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    public init(
        id: UUID,
        description: String?,
        location: String?,
        url: URL
    ) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
    
    static func from(_ image: LocalFeedImage) -> CodableFeedImage {
        CodableFeedImage(id: image.id, description: image.description, location: image.location, url: image.url)
    }
    
    var toLocalFeedImage: LocalFeedImage {
        LocalFeedImage(id: id, description: description, location: location, url: url)
    }
}

