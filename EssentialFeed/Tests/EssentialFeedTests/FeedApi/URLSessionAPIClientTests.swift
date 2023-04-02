//
//  URLSessionAPIClientTests.swift
//  
//
//  Created by Jacob Rakidzich on 4/1/23.
//

import XCTest

class URLSessionHttpClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url, completionHandler: { _, _, _ in })
    }
}

final class URLSessionAPIClientTests: XCTestCase {
    private let url = URL(string: "https://a-url.com")!
    private let session = URLSessionSpy()
    private lazy var sut = URLSessionHttpClient(session: session)

    func test() {
        sut.get(from: url)
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    // MARK: - Helpers

    private class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            return FakeURLSessionDataTask()
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {}
}
