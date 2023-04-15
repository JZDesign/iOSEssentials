import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class EssentialFeedCacheIT: XCTestCase {

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

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> FeedLoader {
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
}
