import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class CodableFeedStoreTests: XCTestCase {
    func test_retrieve_deliversEmptyWhenCacheIsEmpty() throws {
        let sut = CodableFeedStore()
        let expectation = expectation(description: #function)
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default: XCTFail(#function)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
        let sut = CodableFeedStore()
        let expectation = expectation(description: #function)
        
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default: XCTFail(#function)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
}

struct CodableFeedStore: FeedStore {
    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.empty)
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    }
    
    func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
    }
}