import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class EssentialFeedCacheIT: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Self.deleteStoredArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        Self.deleteStoredArtifacts()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() throws {
        let sut = makeSUT()
        let expectation = expectation(description: #function)
        
        sut.load { result in
            switch result {
            case .failure(let error):
                XCTFail("\(#function): \(error.localizedDescription)")
            case .success(let feed):
                XCTAssertEqual(feed, [])
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.5)
    }
    
    func test_load_deliversItemsSavedOnSeparateInstances() {
        let loadSUT = makeSUT()
        let saveSUT = makeSUT()
        
        let feed = uniqueImageFeed().models
                
        expect(saveSUT, toSave: feed)
        expect(loadSUT, toRetrieve: .success(feed))
    }
    
    func test_save_overridesItemsSavedOnASeparateInstance() {
        let loadSUT = makeSUT()
        let firstSaveSUT = makeSUT()
        let secondSaveSUT = makeSUT()
        
        let firstSaveFeed = uniqueImageFeed().models
        let secondSaveFeed = uniqueImageFeed().models
                
        expect(firstSaveSUT, toSave: firstSaveFeed)
        expect(secondSaveSUT, toSave: secondSaveFeed)
        expect(loadSUT, toRetrieve: .success(secondSaveFeed))
    }
    
    // MARK: - Helpers

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalFeedLoader {
        // using this bundle cause a model not found error. Why?
//        let bundle = Bundle(for: CoreDataFeedStore.self)
        let store = try! CoreDataFeedStore(storeURL: Self.testSpecificStoreURL)//, bundle: bundle)
        trackMemoryLeaks(store, file: file, line: line)
        return createAndTrackMemoryLeaks(
            LocalFeedLoader(
                store: store,
                currentDate: Date.init
            ),
            file: file,
            line: line)
    }
    
    static let cachesDirectory: URL = FileManager
        .default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first!
    
    static let testSpecificStoreURL: URL = cachesDirectory
        .appendingPathComponent("\(type(of: EssentialFeedCacheIT.self)).store")
    
    private static func deleteStoredArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    
    func expect(
        _ sut: LocalFeedLoader,
        toRetrieve expectedResult: LocalFeedLoader.LoadResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for cache Retrieval")
        sut.load { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.success(let expectedFeed), .success(let retrievedFeed)):
                XCTAssertEqual(expectedFeed, retrievedFeed)
            case (.failure(let expectedError), .failure(let retrievedError)):
                XCTAssertEqual(expectedError as NSError, retrievedError as NSError)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
    func expect(
        _ sut: LocalFeedLoader,
        toSave feed: [FeedImage],
        andCompleteWith expectedResult: LocalFeedLoader.SaveResult = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for cache Retrieval")
        sut.save(feed) { retrievedError in
            XCTAssertEqual(expectedResult as? NSError, retrievedError as? NSError)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
    
}
