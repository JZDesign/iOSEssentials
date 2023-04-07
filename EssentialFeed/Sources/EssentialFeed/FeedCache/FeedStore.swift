import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [LocalFeedItem], timeStamp: Date, completion: @escaping InsertionCompletion)
}

/// DTO of the ``FeedItem``
public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(
        id: UUID,
        description: String?,
        location: String?,
        imageURL: URL
    ) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}

public extension LocalFeedItem {
    static func from(_ feedItem: FeedItem) -> LocalFeedItem {
        .init(id: feedItem.id, description: feedItem.description, location: feedItem.location, imageURL: feedItem.imageURL)
    }
}

