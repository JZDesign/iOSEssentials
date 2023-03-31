//
//  RemoteFeedLoaderTests.swift
//  
//
//  Created by Jacob Rakidzich on 3/30/23.
//

import XCTest

final class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        _ = RemoteFeedLoader()

        XCTAssertNil(HttpClient.shared.requestedURL)
    }
    
    func test_load_requestsDataFromURL() {
        RemoteFeedLoader().load()
        
        XCTAssertNotNil(HttpClient.shared.requestedURL)
    }
}

class RemoteFeedLoader {
    func load() {
        HttpClient.shared.requestedURL = URL(string: "https://a-url.com")!
    }
}

class HttpClient {
    static let shared = HttpClient()
    private init() {}
    var requestedURL: URL?
}
