//
//  RemoteFeedLoaderTests.swift
//  
//
//  Created by Jacob Rakidzich on 3/30/23.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertEqual(client.messages.count, 0)
    }
    
    func test_load_requestsDataFromURL() {
        let (sut, client) = makeSUT(url: URL(string: "https://another-url.com")!)
        sut.load { _ in }
        XCTAssertEqual(client.messages.map(\.url), [URL(string: "https://another-url.com")])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT(url: URL(string: "https://another-url.com")!)
        sut.load { _ in }
        sut.load { _ in }
        XCTAssertEqual(client.messages.count, 2)
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT(url: URL(string: "https://another-url.com")!)
        expect(sut, toCompleteWith: failure(.connectivity)) {
            client.complete(with: NSError())
        }
    }
    
    func test_load_deliversErrorOnNon200HttpResponse() {
        let (sut, client) = makeSUT(url: URL(string: "https://another-url.com")!)
        [199, 201, 300, 400, 500].enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                client.complete(withStatusCode: code, at: index, data: makeItemsJSON([]))
            }
        }
    }
    
    func test_load_deliversErrorOn200HttpResponseWithInvalidJson() {
        let (sut, client) = makeSUT(url: URL(string: "https://another-url.com")!)
        
        expect(sut, toCompleteWith: failure(.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HttpResponseWithEmptyJsonList() {
        let (sut, client) = makeSUT(url: URL(string: "https://another-url.com")!)

        expect(sut, toCompleteWith: .success([])) {
            client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        }
    }
    
    func test_load_deliversItemsOn200HttpResponseWithValidItems() {
        let (sut, client) = makeSUT(url: URL(string: "https://another-url.com")!)
        
        let item1 = makeItem(imageURL: URL(string: "https://a-url.com")!)
        
        let item2 = makeItem(
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://another-url.com")!
        )
        
        expect(sut, toCompleteWith: .success([item1.model, item2.model])) {
            let validJSON = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: validJSON)
        }
    }
    
    func test_load_doesNotDeliverResultAfterSutIsDeallocated() {
        var (sut, client): (RemoteFeedLoader?, HttpClientSpy) = makeSUT()
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        sut = nil

        client.complete(withStatusCode: 200, data: makeItemsJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        client: HttpClientSpy = HttpClientSpy(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (RemoteFeedLoader, HttpClientSpy) {
        let sut = createAndTrackMemoryLeaks(RemoteFeedLoader(url: url, client: client), file: file, line: line)
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWith expectedResult: RemoteFeedLoader.Result,
        file: StaticString = #file,
        line: UInt = #line,
        when action: () -> Void
    ) {
        let expectation = expectation(description: #function)
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("Expected result: \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            
            }
            expectation.fulfill()
        }
        action()
        wait(for: [expectation], timeout: 0.1)
    }
    
    func makeItem(
        id: UUID = UUID(),
        description: String? = nil,
        location: String? = nil,
        imageURL: URL
    ) -> (model: FeedItem, json: [String: Any]) {
        (
            FeedItem(
                id: id,
                description: description,
                location: location,
                imageURL: imageURL
            ),
            [
                "id" : id.uuidString,
                "description" : description,
                "location" : location,
                "image" : imageURL.absoluteString
            ].compactMapValues { $0 }
        )
    }
    
    func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: ["items" : items])
    }

    func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }
    
}

// MARK: - Spy

fileprivate extension RemoteFeedLoaderTests {
    class HttpClientSpy: HttpClient {
        var messages = [(url: URL, completion: (HttpClientResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, at index: Int = 0, data: Data) {
            let response = HTTPURLResponse(
                url: URL(string: "http://a-url.com")!,
                statusCode: code,
                httpVersion: nil,
                headerFields: [:]
            )!
            messages[index].completion(.success((data, response)))
        }
    }
}
