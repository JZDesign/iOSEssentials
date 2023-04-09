import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrieveCachedFeedResult) -> Void

    
    /// The completeion handler can be invoked on any thread
    /// Clients are responsible to dispatch to the appropriate threads if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    /// The completeion handler can be invoked on any thread
    /// Clients are responsible to dispatch to the appropriate threads if needed.
    func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion)
    /// The completeion handler can be invoked on any thread
    /// Clients are responsible to dispatch to the appropriate threads if needed.
    func retrieve(completion: @escaping RetrievalCompletion)
}

public enum RetrieveCachedFeedResult {
    case empty
    case found(feed: [LocalFeedImage], timeStamp: Date)
    case failure(Error)
}

/// DTO of the ``FeedImage``
public struct LocalFeedImage: Equatable {
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
}

public extension LocalFeedImage {
    static func from(_ feedItem: FeedImage) -> LocalFeedImage {
        .init(id: feedItem.id, description: feedItem.description, location: feedItem.location, url: feedItem.url)
    }
}


