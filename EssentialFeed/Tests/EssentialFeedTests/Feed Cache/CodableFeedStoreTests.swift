import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class FeedStoreTests: XCTestCase {
    let testSpecificStoreURL = FileManager
        .default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("\(type(of: FeedStoreTests.self)).store")

    override func setUp() {
        super.setUp()
        ensureEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        ensureEmptyStoreState()
    }
    
    private func ensureEmptyStoreState() {
        CodableFeedStore(storeURL: testSpecificStoreURL).deleteCachedFeed { _ in }
    }
    
    // MARK: - RETRIEVE

    func test_retrieve_deliversEmptyWhenCacheIsEmpty() throws {
        expect(makeSUT(), toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() throws {
        let sut = makeSUT(storeURL: testSpecificStoreURL)
        try! "invalid data".write(to: testSpecificStoreURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure () throws {
        let sut = makeSUT(storeURL: testSpecificStoreURL)
        try! "invalid data".write(to: testSpecificStoreURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    // MARK: - INSERT

    func test_insert_overridesPreviouslyCachedValues() {
        let sut = makeSUT()
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((latestFeed, timeStamp: latestTimestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: latestFeed, timeStamp: latestTimestamp))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidURL)
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let insertionError = insert((feed, timeStamp: timestamp), to: sut)
        XCTAssertNotNil(insertionError, "Expected cace to fail with an error due to the invalid cache url")
    }

    // MARK: - DELETE
    
    func test_delete_hasNoSideEffectsOnEmptyCache() throws {
        let sut = makeSUT()
        
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() throws {
        let sut = makeSUT()
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
        
        delete(from: sut)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() throws {
        let noPermissionsToDelete = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let sut = makeSUT(storeURL: noPermissionsToDelete)
        
        let deletionError = delete(from: sut)
        XCTAssertNotNil(deletionError)

        expect(sut, toRetrieve: .empty)
    }
    
    func test_storeSideEffects_runSerially() throws {
        let sut = makeSUT()
        let operation1 = expectation(description: "Operation 1")
        let operation2 = expectation(description: "Operation 2")
        let operation3 = expectation(description: "Operation 3")
        var completedOrder = [XCTestExpectation]()

        sut.insert(uniqueImageFeed().local, timeStamp: Date()) { _ in
            completedOrder.append(operation1)
            operation1.fulfill()
        }

        sut.deleteCachedFeed { _ in
            completedOrder.append(operation2)
            operation2.fulfill()
        }

        sut.insert(uniqueImageFeed().local, timeStamp: Date()) { _ in
            completedOrder.append(operation3)
            operation3.fulfill()
        }

        wait(for: [operation1, operation2, operation3], timeout: 0.5)
        XCTAssertEqual(completedOrder, [operation1, operation2, operation3], "Expected side-effects to run in order but they did not")
    }
    
    // MARK: - HELPERS
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        createAndTrackMemoryLeaks(CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL), file: file, line: line)
    }
    
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
        wait(for: [expectation], timeout: 0.1)
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
        wait(for: [expectation], timeout: 0.1)
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
        wait(for: [expectation], timeout: 0.1)
        return result
    }
}
