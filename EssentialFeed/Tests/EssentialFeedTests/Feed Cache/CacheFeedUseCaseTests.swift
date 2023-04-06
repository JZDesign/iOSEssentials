//
//  CacheFeedUseCaseTests.swift
//  
//
//  Created by Jacob Rakidzich on 4/5/23.
//

import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageCacheUponCreation() throws {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
    
        sut.save(items) { _ in }

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let deletionError = anyNSError()
        
        let exp = expectation(description: #function)
        var receievedError: Error?
        sut.save(items) {
            receievedError = $0
            exp.fulfill()
        }
        sut.store.completeDeletion(with: deletionError)
        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(receievedError as? NSError, deletionError)
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }

    func test_save_failsOnInsertionError() {
        let (sut, _) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let insertionError = anyNSError()
        
        let exp = expectation(description: #function)
        var receievedError: Error?
        sut.save(items) {
            receievedError = $0
            exp.fulfill()
        }
        sut.store.completeDeletionSuccessfully()
        sut.store.completeInsertion(with: insertionError)
        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(receievedError as? NSError, insertionError)
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, _) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        let exp = expectation(description: #function)
        var receievedError: Error?

        sut.save(items) {
            receievedError = $0
            exp.fulfill()
        }

        sut.store.completeDeletionSuccessfully()
        sut.store.completeInsertionSuccessfully()

        wait(for: [exp], timeout: 0.1)

        XCTAssertNil(receievedError)
    }

    func test_save_requestsViewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [uniqueItem(), uniqueItem()]

        sut.save(items) { _ in }

        sut.store.completeDeletionSuccessfully()
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }
    
    // MARK: - Helpers
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = createAndTrackMemoryLeaks(FeedStore(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(LocalFeedLoader(store: store, currentDate: currentDate), file: file, line: line)
        return (sut, store)
    }
    
    func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
}

class FeedStore {
    typealias FeedStoreCompletion = (Error?) -> Void
    
    private(set) var receivedMessages = [ReceivedMessage]()
    private var deletionCompletions = [FeedStoreCompletion]()
    private var insertionCompletions = [FeedStoreCompletion]()
    
    func deleteCachedFeed(completion: @escaping FeedStoreCompletion) {
        receivedMessages.append(.deleteCachedFeed)
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ items: [FeedItem], timeStamp: Date, completion: @escaping FeedStoreCompletion) {
        receivedMessages.append(.insert(items, timeStamp))
        insertionCompletions.append(completion)
    }

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
}


class LocalFeedLoader {
    let store: FeedStore
    let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timeStamp: currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}
