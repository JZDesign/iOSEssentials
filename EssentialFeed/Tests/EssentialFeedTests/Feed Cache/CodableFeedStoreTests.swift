import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

final class CodableFeedStoreTests: XCTestCase {
    let testSpecificStoreURL = FileManager
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
        CodableFeedStore(storeURL: testSpecificStoreURL).deleteCachedFeed { _ in }
    }
    
    func test_retrieve_deliversEmptyWhenCacheIsEmpty() throws {
        expect(makeSUT(), toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()

        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed, timeStamp: timestamp), to: sut)
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
        expect(sut, toRetrieve: .found(feed: feed, timeStamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() throws {
        let sut = makeSUT(storeURL: testSpecificStoreURL)
        try! "invalid data".write(to: testSpecificStoreURL, atomically: false, encoding: .utf8)
        expect(sut, toRetrieve: .failure(anyNSError()))
    }

    // MARK: - HELPERS
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        createAndTrackMemoryLeaks(CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL), file: file, line: line)
    }
    
    func expect(
        _ sut: CodableFeedStore,
        toRetrieve expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for cache Retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty),
                (.failure, .failure):
                break
            case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual(expectedFeed, retrievedFeed, file: file, line: line)
                XCTAssertEqual(expectedTimestamp, retrievedTimestamp, file: file, line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
    }
    
    func insert(
        _ cache: (feed: [LocalFeedImage], timeStamp: Date),
        to sut: CodableFeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for insert")
        sut.insert(cache.feed, timeStamp: cache.timeStamp) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
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
        do {
            let cache = try JSONDecoder().decode(Cache.self, from: data)
            completion(.found(feed: cache.feed.map(\.toLocalFeedImage), timeStamp: cache.timeStamp))
        } catch {
            completion(.failure(error))
        }
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

