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
        
        let saveExpectation = expectation(description: "\(#function) save")
        
        saveSUT.save(feed) { saveError in
            XCTAssertNil(saveError)
            saveExpectation.fulfill()
        }
        wait(for: [saveExpectation], timeout: 0.2)
        
        let loadExpectation = expectation(description: "\(#function) load")
        loadSUT.load { result in
            switch result {
            case .failure(let error):
                XCTFail("\(#function): \(error.localizedDescription)")
            case .success(let feedResult):
                XCTAssertEqual(feedResult, feed)
            }
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 0.2)
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
}
