import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThat_Delete_DeliversErrorOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let deletionError = delete(from: sut)

        XCTAssertNotNil(deletionError)
    }

    func assertThat_Delete_HasNoSideEffectsErrorOnDeletionError(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        delete(from: sut)

        expect(sut, toRetrieve: .success(nil))
    }
}
