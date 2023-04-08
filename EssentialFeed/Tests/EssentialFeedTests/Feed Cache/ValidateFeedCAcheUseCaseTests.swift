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

    // MARK: - Helpers

    func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let item1 = uniqueImage()
        let item2 = uniqueImage()
        return ([item1, item2], [LocalFeedImage.from(item1), LocalFeedImage.from(item2)])
    }
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = createAndTrackMemoryLeaks(FeedStoreSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(LocalFeedLoader(store: store, currentDate: currentDate), file: file, line: line)
        return (sut, store)
    }

}
