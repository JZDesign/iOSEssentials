//
//  CacheFeedUseCaseTests.swift
//  
//
//  Created by Jacob Rakidzich on 4/5/23.
//

import XCTest

final class CacheFeedUseCaseTests: XCTestCase {
    let store = FeedStore()
    lazy var sut = LocalFeedLoader(store: store)

    func test_init_doesNotDeleteCacheUponCreation() throws {
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}

class FeedStore {
    var deleteCachedFeedCallCount = 0
}

class LocalFeedLoader {
    let store: FeedStore

    init(store: FeedStore) {
        self.store = store
    }
}
