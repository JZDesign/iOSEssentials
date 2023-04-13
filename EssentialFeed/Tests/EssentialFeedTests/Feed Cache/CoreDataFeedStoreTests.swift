import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class CoreDataFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    
    func test_retrieve_deliversEmptyWhenCacheIsEmpty() {
        assertThat_Retrieve_DeliversEmptyOnEmptyCache(on: makeSUT())
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        assertThat_Retrieve_HasNoSideEffectsOnEmptyCache(on: makeSUT())
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        assertThat_Retrieve_DeliversFoundValuesOnNonEmptyCache(on: makeSUT())
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
//        assertThat_Retrieve_HasNoSideEffectsOnNonEmptyCache(on: makeSUT())
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
//        let url = testSpecificStoreURL
//        let sut = makeSUT(storeURL: url)
//        try! "invalid data".write(to: url, atomically: false, encoding: .utf8)
//        expect(sut, toRetrieve: .failure(anyNSError()))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure () {
//        let url = testSpecificStoreURL
//        let sut = makeSUT(storeURL: url)
//        try! "invalid data".write(to: url, atomically: false, encoding: .utf8)
//        expect(sut, toRetrieve: .failure(anyNSError()), times: 2)
    }
    
    // MARK: - INSERT

    func test_insert_overridesPreviouslyCachedValues() {
//        assertThat_Insert_OverridesPreviouslyCachedValues(on: makeSUT())
    }
    
    func test_insert_deliversErrorOnInsertionError() {
//        let invalidURL = URL(string: "invalid://store-url")!
//        let sut = makeSUT(storeURL: invalidURL)
//        assertThat_Insert_DeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_hasNoSideEffectsOnInsertionError() {
//        let invalidURL = URL(string: "invalid://store-url")!
//        let sut = makeSUT(storeURL: invalidURL)
//        assertThat_Insert_HasNoSideEffectsOnInsertionError(on: sut)
    }

    func test_insert_doesNotDeliverErrorOnEmptyCache() {
//        assertThat_Insert_DoesNotDeliverErrorOnEmptyCache(on: makeSUT())
    }
    
    func test_insert_doesNotDeliverErrorOnNonEmptyCache() {
//        assertThat_Insert_DoesNotDeliverErrorOnNonEmptyCache(on: makeSUT())
    }
    
    // MARK: - DELETE
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
//        assertThat_Delete_HasNoSideEffectsOnEmptyCache(on: makeSUT())
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
//        assertThat_Delete_EmptiesPreviouslyInsertedCache(on: makeSUT())
    }
    
    func test_delete_deliversErrorOnDeletionError() {
//        let noPermissionsToDelete = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
//        let sut = makeSUT(storeURL: noPermissionsToDelete)
//
//        assertThat_Delete_DeliversErrorOnDeletionError(on: sut)
    }
    
     func test_delete_hasNoSideEffectsErrorOnDeletionError() {
//         let noPermissionsToDelete = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
//         let sut = makeSUT(storeURL: noPermissionsToDelete)
//         assertThat_Delete_HasNoSideEffectsErrorOnDeletionError(on: sut)
     }
    
    func test_delete_doesNotDeliverErrorOnEmptyCache() {
//        assertThat_Delete_DoesNotDeliverErrorOnEmptyCache(on: makeSUT())
    }
    
    func test_delete_doesNotDeliverErrorOnNonEmptyCache() {
//        assertThat_Delete_DoesNotDeliverErrorOnNonEmptyCache(on: makeSUT())
    }
    
    // MARK: - Serial side effects
    
    func test_storeSideEffects_runSerially() {
//        assertThat_StoreSideEffects_RunSerially(on: makeSUT())
    }

    // MARK: - HELPERS
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> FeedStore {
        createAndTrackMemoryLeaks(try! CoreDataFeedStore(storeURL: URL(fileURLWithPath: "/dev/null")), file: file, line: line)
    }
}
