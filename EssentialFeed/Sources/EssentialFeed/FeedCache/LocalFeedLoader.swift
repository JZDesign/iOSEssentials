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
                // In lesson **Proper Memory-Management of Captured References Within Deeply Nested Closures + Identifying Highly-Coupled Modules**
                // They didn't just pass a reference of the completion block through, they did another weak self closure then invoked the completion from within the other closure
                // I ran the tests 100k + times and I also tried using a dispatch queue and could not replicate the issue.
                self.store.insert(items, timeStamp: self.currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}
