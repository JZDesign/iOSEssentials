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
        session.dataTask(with: url, completionHandler: { data, response, error in
            if let error {
                completion(.failure(error))
            } else if let data, data.count > 0, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }).resume()
    }
    
    private class UnexpectedValuesRepresentation: Error {}
}

final class URLSessionAPIClientTests: XCTestCase {
    // MARK: - Setup/Teardown
    override func setUp() {
        URLProtocolStub.startInterceptingRequests()
        super.setUp()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        super.tearDown()
    }
    
    // MARK: - Success Tests
    
    func test_getFromURL_performGETRequestWithURL() {
        let url = anyURL()
        
        URLProtocolStub.stub(
            data: nil,
            response: HTTPURLResponse(url: url, mimeType: nil, expectedContentLength: 1, textEncodingName: nil),
            error: nil
        )
        
        let expectation = expectation(description: #function)
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(url, request.url)
            expectation.fulfill()
        }

        makeSUT().get(from: url) { _ in }
        wait(for: [expectation], timeout: 0.1)
    }
    
    func test_getFromURL_succeedsOnHttpURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        URLProtocolStub.stub(data: data, response: response, error: nil)
        let expectation = expectation(description: #function)
        makeSUT().get(from: anyURL()) { result in
            switch result {
            case let .success((receivedData, receivedResponse)):
                XCTAssertEqual(data, receivedData)
                XCTAssertEqual(response.url, receivedResponse.url)
                XCTAssertEqual(response.statusCode, receivedResponse.statusCode)
            default:
                XCTFail("Expected success, got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
    }
    
    // MARK: - Failure Tests
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }

    func test_getFromURL_failsOnRequestError() {
        let error = anyNSError()
        let receivedError = resultErrorFor(data: nil, response: nil, error: error)! as NSError
        XCTAssertEqual(receivedError.domain, error.domain)
        XCTAssertEqual(receivedError.code, error.code)
    }
    
    // MARK: - Helpers
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHttpClient {
        createAndTrackMemoryLeaks(URLSessionHttpClient(), file: file, line: line)
    }

    func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        var receievedError: Error? = nil

        let expectation = expectation(description: #function)

        sut.get(from: anyURL()) { result in
            switch result {
            case .failure(let error):
                receievedError = error
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.1)
        return receievedError
    }

    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub? = nil
        private static var requestObserver: ((URLRequest) -> Void)? = nil

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
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
