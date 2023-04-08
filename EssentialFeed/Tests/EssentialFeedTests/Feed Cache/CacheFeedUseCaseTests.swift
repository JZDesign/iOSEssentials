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
    
        sut.save(uniqueImageFeed().models) { _ in }

        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
    
        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }

    func test_save_requestsViewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let (items, local) = uniqueImageFeed()

        sut.save(items) { _ in }

        store.completeDeletionSuccessfully()
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(local, timestamp)])
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        var receivedResults = [Error?]()

        sut?.save(uniqueImageFeed().models, completion: { error in
            receivedResults.append(error)
        })
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = createAndTrackMemoryLeaks(FeedStoreSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(LocalFeedLoader(store: store, currentDate: currentDate), file: file, line: line)
        return (sut, store)
    }
    
    func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let item1 = uniqueImage()
        let item2 = uniqueImage()
        return ([item1, item2], [LocalFeedImage.from(item1), LocalFeedImage.from(item2)])
    }
    
    func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line, function: StaticString = #function) {
        let expectation = expectation(description: function.description)
        var receivedError: Error?
        sut.save(uniqueImageFeed().models) { error in
            receivedError = error
            expectation.fulfill()
        }

        action()

        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(receivedError as? NSError, expectedError, file: file, line: line)
    }
}

class FeedStoreSpy: FeedStore {
    
    private(set) var receivedMessages = [ReceivedMessage]()
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        receivedMessages.append(.deleteCachedFeed)
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        receivedMessages.append(.insert(items, timeStamp))
        insertionCompletions.append(completion)
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        receivedMessages.append(.retrieveFromCache)
        retrievalCompletions.append(completion)
    }
    
    
    func completeRetrievalAsEmpty(at index: Int = 0) {
        retrievalCompletions[index](.empty)
    }
    
    func completeRetrievalSuccessfully(with feed: [LocalFeedImage] = [], timeStamp: Date = Date(), at index: Int = 0) {
        retrievalCompletions[index](.found(feed: feed, timeStamp: timeStamp))
    }

    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieveFromCache
    }
}
