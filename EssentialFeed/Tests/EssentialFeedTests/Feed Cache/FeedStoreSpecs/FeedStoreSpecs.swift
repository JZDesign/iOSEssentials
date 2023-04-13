import Foundation

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_deliversFailureOnRetrievalError()
    func test_retrieve_hasNoSideEffectsOnFailure()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_deliversErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_hasNoSideEffectsErrorOnDeletionError()
}

protocol FeedStoreSpecs {
    func test_retrieve_deliversEmptyWhenCacheIsEmpty()
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    func test_retrieve_deliversFoundValuesOnNonEmptyCache()
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache()
    
    func test_insert_overridesPreviouslyCachedValues()
    func test_insert_doesNotDeliverErrorOnEmptyCache()
    func test_insert_doesNotDeliverErrorOnNonEmptyCache()
    
    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_emptiesPreviouslyInsertedCache()
    func test_delete_doesNotDeliverErrorOnEmptyCache()
    func test_delete_doesNotDeliverErrorOnNonEmptyCache()
    
    func test_storeSideEffects_runSerially()
}

typealias FailableFeedStoreSpecs = FeedStoreSpecs & FailableDeleteFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableRetrieveFeedStoreSpecs
