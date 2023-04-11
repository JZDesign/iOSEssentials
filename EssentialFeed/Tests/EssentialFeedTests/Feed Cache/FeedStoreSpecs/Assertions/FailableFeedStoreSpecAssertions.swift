import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThat_Retrieve_DeliversFailureOnRetrievalError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .failure(anyNSError()), file: file, line: line)
    }
    
    func assertThat_Retrieve_HasNoSideEffectsOnFailure(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .failure(anyNSError()), times: 2, file: file, line: line)
    }
}
