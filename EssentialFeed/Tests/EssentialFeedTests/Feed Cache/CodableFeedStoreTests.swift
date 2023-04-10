import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    let testSpecificStoreURL = FileManager
        .default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("\(type(of: CodableFeedStoreTests.self)).store")

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

    func test_retrieve_deliversEmptyWhenCacheIsEmpty() {
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: makeSUT())
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: makeSUT())
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: makeSUT())
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: makeSUT())
    }
    
    // TODO: Finish moving the tests into the extensions files.
    func test_retrieve_deliversFailureOnRetrievalError() {
        let url = testSpecificStoreURL
        let sut = makeSUT(storeURL: url)
        try! "invalid data".write(to: url, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure () {
        let url = testSpecificStoreURL
        let sut = makeSUT(storeURL: url)
        try! "invalid data".write(to: url, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()), times: 2)
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
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL: invalidURL)
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .empty)
    }

    func test_insert_doesNotDeliverErrorOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let insertionError = insert((feed, timeStamp: timestamp), to: sut)
        
        XCTAssertNil(insertionError)
    }
    
    func test_insert_doesNotDeliverErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let insertionError = insert((latestFeed, timeStamp: latestTimestamp), to: sut)

        XCTAssertNil(insertionError)
        expect(sut, toRetrieve: .found(feed: latestFeed, timeStamp: latestTimestamp))
    }
    
    // MARK: - DELETE
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
        
        delete(from: sut)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noPermissionsToDelete = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let sut = makeSUT(storeURL: noPermissionsToDelete)
        
        let deletionError = delete(from: sut)

        XCTAssertNotNil(deletionError)
    }
    
     func test_delete_hasNoSideEffectsErrorOnDeletionError() {
         let noPermissionsToDelete = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
         let sut = makeSUT(storeURL: noPermissionsToDelete)
         
         delete(from: sut)

         expect(sut, toRetrieve: .empty)
     }
    
    func test_delete_doesNotDeliverErrorOnEmptyCache() {
        let sut = makeSUT()
        expect(sut, toRetrieve: .empty)
        
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError)
    }
    
    func test_delete_doesNotDeliverErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
        
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError)
    }
    
    // MARK: - Serial side effects
    
    func test_storeSideEffects_runSerially() {
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

        wait(for: [operation1, operation2, operation3], timeout: 1.5)
        XCTAssertEqual(completedOrder, [operation1, operation2, operation3], "Expected side-effects to run in order but they did not")
    }
    // MARK: - HELPERS
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        createAndTrackMemoryLeaks(CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL), file: file, line: line)
    }
}
