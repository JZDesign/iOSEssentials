//
//  RemoteFeedLoaderTests.swift
//  
//
//  Created by Jacob Rakidzich on 3/30/23.
//

import XCTest

final class RemoteFeedLoaderTests: XCTestCase {
    func test_init() {
        let sut = RemoteFeedLoader()
        let client = HttpClient()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_init_doesNotRequestDataFromURL() {
        
    }
}

class RemoteFeedLoader {
}

class HttpClient {
    var requestedURL: URL?
}
