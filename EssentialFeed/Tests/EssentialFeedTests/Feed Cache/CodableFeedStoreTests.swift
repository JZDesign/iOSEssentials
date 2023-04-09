import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        CodableFeedStore().deleteCachedFeed { _ in }
    }

    override func tearDown() {
        super.tearDown()
        CodableFeedStore().deleteCachedFeed { _ in }
    }
    
    func test_retrieve_deliversEmptyWhenCacheIsEmpty() throws {
        let sut = makeSUT()
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
        let sut = makeSUT()
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
    
    func test_retrieveAfterInserting_deliversInsertedValues() throws {
        let sut = makeSUT()
        let expectation = expectation(description: #function)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        sut.insert(feed, timeStamp: timestamp) { insertResult in
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                case let .found(feed: returnedFeed, timeStamp: returnedTimestamp):
                    XCTAssertEqual(feed, returnedFeed)
                    XCTAssertEqual(timestamp, returnedTimestamp)
                    break
                default: XCTFail(#function)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    // MARK: - HELPERS
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        createAndTrackMemoryLeaks(CodableFeedStore(), file: file, line: line)
    }
}

class CodableFeedStore: FeedStore {
    private let storeURL = FileManager
        .default
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("image-feed.store")
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timeStamp: Date
    }

    func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        let cache = try! JSONDecoder().decode(Cache.self, from: data)
        completion(.found(feed: cache.feed.map(\.toLocalFeedImage), timeStamp: cache.timeStamp))
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        try? FileManager.default.removeItem(at: storeURL)
        completion(nil)
    }
    
    func insert(_ items: [LocalFeedImage], timeStamp: Date, completion: @escaping InsertionCompletion) {
        let data = try! JSONEncoder().encode(Cache(feed: items.map(CodableFeedImage.from), timeStamp: timeStamp))
        try! data.write(to: storeURL)
        completion(nil)
    }
}

public struct CodableFeedImage: Equatable, Codable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL
    
    public init(
        id: UUID,
        description: String?,
        location: String?,
        url: URL
    ) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
    
    static func from(_ image: LocalFeedImage) -> CodableFeedImage {
        CodableFeedImage(id: image.id, description: image.description, location: image.location, url: image.url)
    }
    
    var toLocalFeedImage: LocalFeedImage {
        LocalFeedImage(id: id, description: description, location: location, url: url)
    }
}

