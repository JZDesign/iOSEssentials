import XCTest
import EssentialFeed

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
        let expectation = expectation(description: #function)
        
        var receivedError: Error?
        sut.load { result in
            switch result {
            case .success:
                XCTFail(#function)
            case .failure(let error):
                receivedError = error
            }
            expectation.fulfill()
        }
        
        store.completeRetrieval(with: anyNSError())
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertNotNil(receivedError)
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        let expectation = expectation(description: #function)
        
        var receivedImages: [FeedImage]?
        sut.load { result in
            switch result {
            case .failure:
                XCTFail(#function)
            case .success(let images):
                receivedImages = images
            }
            expectation.fulfill()
        }
        
        store.completeRetrievalSuccessfully()
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(receivedImages, [])
    }
    
    // MARK: - Helpers
    
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = createAndTrackMemoryLeaks(FeedStoreSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(LocalFeedLoader(store: store, currentDate: currentDate), file: file, line: line)
        return (sut, store)
    }
    
}
