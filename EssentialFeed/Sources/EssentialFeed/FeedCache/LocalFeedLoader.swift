import Foundation

public final class LocalFeedLoader: FeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        store.retrieve { error in
            if let error {
                completion(.failure(error))
                return
            }
            completion(.success([]))
        }
    }
    
    public func save(_ items: [FeedImage], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            if error == nil {
                self.cache(items, with: completion)
            } else {
                completion(error)
            }
        }
    }
    
    private func cache(_ items: [FeedImage], with completion: @escaping (Error?) -> Void) {
        store.insert(items.toLocal(), timeStamp: currentDate()) { [weak self] error in
            guard self != nil else { return }

            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map(LocalFeedImage.from)
    }
}
