import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class CodableFeedStoreTests: XCTestCase {
    let url = FileManager
        .default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent("\(type(of: CodableFeedStoreTests.self)).store")

    override func setUp() {
        super.setUp()
        ensureEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        ensureEmptyStoreState()
    }
    
    private func ensureEmptyStoreState() {
        CodableFeedStore(storeURL: url).deleteCachedFeed { _ in }
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
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
        let sut = makeSUT()
        let expectation = expectation(description: #function)
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        sut.insert(feed, timeStamp: timestamp) { insertResult in
            sut.retrieve { firstRetrieveResult in
                sut.retrieve { secondRetrieveResult in
                    switch (firstRetrieveResult, secondRetrieveResult) {
                    case let (.found(firstFound), .found(secondFound)):
                        XCTAssertEqual(firstFound.feed, secondFound.feed)
                        XCTAssertEqual(firstFound.timeStamp, secondFound.timeStamp)
                        break
                    default: XCTFail(#function)
                    }
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    // MARK: - HELPERS
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        createAndTrackMemoryLeaks(CodableFeedStore(storeURL: url), file: file, line: line)
    }
}

class CodableFeedStore: FeedStore {
    let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
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

