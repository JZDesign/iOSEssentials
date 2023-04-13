import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThat_Insert_DeliversErrorOnInsertionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let insertionError = insert((feed, timeStamp: timestamp), to: sut)
        XCTAssertNotNil(insertionError, "Expected cace to fail with an error due to the invalid cache url")
    }

    func assertThat_Insert_HasNoSideEffectsOnInsertionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .empty)
    }
}
