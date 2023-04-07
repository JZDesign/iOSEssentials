import Foundation

public protocol FeedStore {
    typealias FeedStoreCompletion = (Error?) -> Void

    func deleteCachedFeed(completion: @escaping FeedStoreCompletion)
    func insert(_ items: [FeedItem], timeStamp: Date, completion: @escaping FeedStoreCompletion)
}
