//
//  URLSessionAPIClientTests.swift
//  
//
//  Created by Jacob Rakidzich on 4/1/23.
//

import XCTest
import EssentialFeed

class URLSessionHttpClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        session.dataTask(with: url, completionHandler: { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }).resume()
    }
}

final class URLSessionAPIClientTests: XCTestCase {
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let error = NSError(domain: #function, code: 1_000_000)
        URLProtocolStub.startInterceptingRequests()
        URLProtocolStub.stub(url: url, data: nil, response: nil, error: error)

        let sut = URLSessionHttpClient()

        let expectation = expectation(description: #function)
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
                XCTAssertEqual(receivedError.code, error.code)
            default:
                XCTFail("Expected failure with error: \(error), got \(result) instead.")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
        URLProtocolStub.stopInterceptingRequests()
    }
    
    // MARK: - Helpers

    private class URLProtocolStub: URLProtocol {
        private static var stubs = [URL: Stub]()

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
        }

        static func stub(url: URL, data: Data?, response: URLResponse?, error: Error?) {
            stubs[url] = Stub(data: data, response: response, error: error)
        }

        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            return URLProtocolStub.stubs[url] != nil
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
    }
}
