import Foundation

public final class LocalFeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            if error == nil {
                self.store.insert(items, timeStamp: self.currentDate()) { [weak self] in
                    guard self != nil else { return }
                    completion($0)
                }
            } else {
                completion(error)
            }
        }
    }
}
