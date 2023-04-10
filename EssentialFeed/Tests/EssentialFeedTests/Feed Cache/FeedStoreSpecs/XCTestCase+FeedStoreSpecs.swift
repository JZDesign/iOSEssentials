import EssentialFeed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    
    // MARK: - Assertions
    
    // TODO: move these assertions into separate extensions files per spec protocol
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, times: 2, file: file, line: line)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timeStamp: timestamp), to: sut, file: file, line: line)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp), file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timeStamp: timestamp), to: sut, file: file, line: line)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp), times: 2, file: file, line: line)
    }

    // MARK: - Helpers

    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for cache Retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty),
                (.failure, .failure):
                break
            case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual(expectedFeed, retrievedFeed, file: file, line: line)
                XCTAssertEqual(expectedTimestamp, retrievedTimestamp, file: file, line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.5)
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: RetrieveCachedFeedResult,
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
