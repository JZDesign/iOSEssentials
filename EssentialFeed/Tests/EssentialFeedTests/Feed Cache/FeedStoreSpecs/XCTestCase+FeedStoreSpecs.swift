import EssentialFeedAPITestUtilities
import EssentialFeed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    
    func expect<T: FeedStore>(
        _ sut: T,
        toRetrieve expectedResult: T.RetrievalResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for cache Retrieval")
        
        sut.retrieve { retrievedResult in
            
            switch (expectedResult, retrievedResult) {
            case let (.success(expectedfeed), .success(retrievedFeed)):
                XCTAssertEqual(expectedfeed, retrievedFeed)
            case (.failure, .failure):
                break
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.5)
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: FeedStore.RetrievalResult,
        times: UInt,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        (0..<times).forEach { _ in
            expect(sut, toRetrieve: expectedResult, file: file, line: line)
        }
    }
    
    @discardableResult
    func insert(
        _ cache: (feed: [LocalFeedImage], timeStamp: Date),
        to sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let expectation = expectation(description: "Wait for insert")
        var result: Error?
        sut.insert(cache.feed, timeStamp: cache.timeStamp) { error in
            result = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.5)
        return result
    }
    
    
    @discardableResult
    func delete(
        from sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let expectation = expectation(description: "Wait for insert")
        var result: Error?
        sut.deleteCachedFeed { error in
            result = error
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.5)
        return result
    }
}
