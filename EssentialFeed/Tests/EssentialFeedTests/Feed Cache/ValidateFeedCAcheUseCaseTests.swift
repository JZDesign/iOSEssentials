import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class ValidateFeedCAcheUseCaseTests: XCTestCase {
    
    
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
    
    func test_validateCache_doesNotDeleteCacheOnLessThanSevenDaysOldCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.adding(days: -7).adding(seconds: 1))
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache])
    }
    
    
    func test_validateCache_shouldDeleteCacheOnSevenDaysOldCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.adding(days: -7))
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache, .deleteCachedFeed])
    }
    
    func test_validateCache_shouldDeleteCacheOnMoreThanSevenDaysOldCache() {
        let date = Date()
        let (sut, store) = makeSUT(currentDate: { date })
        let feed = uniqueImageFeed()
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.local, timeStamp: date.adding(days: -7).adding(seconds: -1))
        XCTAssertEqual(store.receivedMessages, [.retrieveFromCache, .deleteCachedFeed])
    }
    

    // MARK: - Helpers

    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = createAndTrackMemoryLeaks(FeedStoreSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(LocalFeedLoader(store: store, currentDate: currentDate), file: file, line: line)
        return (sut, store)
    }

}
