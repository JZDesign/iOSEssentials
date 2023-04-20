import Foundation

public final class LocalFeedLoader: FeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    public typealias LoadResult = FeedLoader.Result
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }

            switch result {
            case let .failure(error):
                completion(.failure(error))
        
            case let .success(feed) where feed != nil && FeedCachePolicy.validate(feed.unsafelyUnwrapped.timeStamp, against: self.currentDate()):
                completion(.success(feed.unsafelyUnwrapped.feed.toFeedImage()))
            case .success:
                completion(.success([]))
            }
        }
    }
}

// MARK: - Save

public extension LocalFeedLoader {
    typealias SaveResult = Error?

    func save(_ items: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deleteResult in
            guard let self else { return }

            if case let .failure(cacheDeletionError) = deleteResult {
                completion(cacheDeletionError)
            } else {
                self.cache(items, with: completion)
            }
        }
    }
}

// MARK: - Validate Cache

public extension LocalFeedLoader {
    func validateCache() {
        store.retrieve { [weak self]  result in
            guard let self else { return }

            switch result {
            case .failure:
                self.store.deleteCachedFeed { _ in }

            case let .success(feed) where feed != nil && !FeedCachePolicy.validate(feed.unsafelyUnwrapped.timeStamp, against: self.currentDate()):
                self.store.deleteCachedFeed { _ in }

            case .success:
                break
            }
        }
    }
}

// MARK: - Helpers

private extension LocalFeedLoader {
    func cache(_ items: [FeedImage], with completion: @escaping (Error?) -> Void) {
        store.insert(items.toLocal(), timeStamp: currentDate()) { [weak self] result in
            guard self != nil else { return }
            if case let .failure(error) = result {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
}

private extension Array where Element == LocalFeedImage {
    func toFeedImage() -> [FeedImage] {
        map {
            FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map(LocalFeedImage.from)
    }
}
