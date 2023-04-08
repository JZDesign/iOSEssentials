import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class ValidateFeedCacheUseCaseTests: XCTestCase {

    func test_load_doesNotMessageStoreOnCreation() {
        let (sut, store) = makeSUT()
        sut.load { _ in }
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache, .deleteCachedFeed])
    }

    func test_validateCache_doesNotDeleteCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        sut.validateCache()
        store.completeRetrievalAsEmpty()
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    func test_validateCache_doesNotDeleteCacheOnNotExpiredCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge().adding(seconds: 1))
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    
    func test_validateCache_shouldDeleteCacheWhenAtExpirationCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge())
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache, .deleteCachedFeed])
    }
    
    func test_validateCache_shouldDeleteCacheOnExpiredCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.minusFeedCacheMaxAge().adding(seconds: -1))
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache, .deleteCachedFeed])
    }
    
    
    
    func test_load_doesNotDeleteCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

        sut?.validateCache()
        sut = nil
        store.completeRetrieval(with: anyNSError())
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }

    // MARK: - Helpers

    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = createAndTrackMemoryLeaks(FeedStoreSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(LocalFeedLoader(store: store, currentDate: currentDate), file: file, line: line)
        return (sut, store)
    }

}
