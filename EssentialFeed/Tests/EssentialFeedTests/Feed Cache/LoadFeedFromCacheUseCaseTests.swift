import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotMessageStoreUponCreation() throws {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let error = anyNSError()
        expect(sut, toCompleteWith: .failure(error)) {
            store.completeRetrieval(with: error)
        }
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalAsEmpty()
        }
    }
    
    func test_load_deliversCachedImagesWhenCacheIsNotExpired() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        expect(sut, toCompleteWith: .success(feed.models)) {
            store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge().adding(seconds: 1))
        }
    }
    
    func test_load_DeliversNoImagesWhenCacheIsAtExpiration() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge())
        }
    }

    func test_load_DeliversNoImagesWhenCacheIsExpired() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge().adding(seconds: -1))
        }
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        store.completeRetrievalAsEmpty()
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    func test_load_hasNoSideEffectsOnNotExpiredCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.load(completion: { _ in })
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge().adding(seconds: 1))
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpirationCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.load(completion: { _ in })
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge())
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    func test_load_hasNoSideEffectsOnExpiredCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.load(completion: { _ in })
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge().adding(seconds: -1))
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [FeedLoader.Result]()
        sut?.load { receivedResults.append($0) }
        sut = nil
        store.completeRetrievalAsEmpty()
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Helpers

    
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = createAndTrackMemoryLeaks(FeedStoreSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(LocalFeedLoader(store: store, currentDate: currentDate), file: file, line: line)
        return (sut, store)
    }
    
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: FeedLoader.Result,
        file: StaticString = #file,
        line: UInt = #line,
        when action: () -> Void
    ) {
        let expectation = expectation(description: #function)
        
        sut.load { result in
            switch (result, expectedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(result) instead")
            }
            expectation.fulfill()
        }
        action()
        wait(for: [expectation], timeout: 0.1)
    }
}
