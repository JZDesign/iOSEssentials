import EssentialFeedAPITestUtilities
import EssentialFeed
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
    
    func assertThat_Retrieve_DeliversEmptyOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThat_Retrieve_HasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .empty, times: 2, file: file, line: line)
    }
    
    func assertThat_Retrieve_DeliversFoundValuesOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timeStamp: timestamp), to: sut, file: file, line: line)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp), file: file, line: line)
    }
    
    func assertThat_Retrieve_HasNoSideEffectsOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timeStamp: timestamp), to: sut, file: file, line: line)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp), times: 2, file: file, line: line)
    }
    
    // MARK: - Insert
    
    func assertThat_Insert_OverridesPreviouslyCachedValues(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp), file: file, line: line)
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((latestFeed, timeStamp: latestTimestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: latestFeed, timeStamp: latestTimestamp), file: file, line: line)
    }

    func assertThat_Insert_DoesNotDeliverErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let insertionError = insert((feed, timeStamp: timestamp), to: sut)
        
        XCTAssertNil(insertionError)
    }

    func assertThat_Insert_DoesNotDeliverErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp), file: file, line: line)
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        let insertionError = insert((latestFeed, timeStamp: latestTimestamp), to: sut)

        XCTAssertNil(insertionError)
        expect(sut, toRetrieve: .found(feed: latestFeed, timeStamp: latestTimestamp), file: file, line: line)
    }
    
    // MARK: - Delete
    
    func assertThat_Delete_HasNoSideEffectsOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThat_Delete_EmptiesPreviouslyInsertedCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
        
        delete(from: sut)
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThat_Delete_DoesNotDeliverErrorOnEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
        
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError)
    }

    func assertThat_Delete_DoesNotDeliverErrorOnNonEmptyCache(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        insert((feed, timeStamp: timestamp), to: sut, file: file, line: line)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp), file: file, line: line)
        
        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError)
    }
    
    // MARK: - Side Effects
    
    func assertThat_StoreSideEffects_RunSerially(
        on sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
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
}
