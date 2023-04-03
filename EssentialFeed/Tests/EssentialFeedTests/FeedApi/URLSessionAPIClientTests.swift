//
//  URLSessionAPIClientTests.swift
//  
//
//  Created by Jacob Rakidzich on 4/1/23.
//

import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

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
        let (receivedData, receivedResponse) = resultValuesFor(data: data, response: response, error: nil)!
    
        XCTAssertEqual(receivedData, data)
        XCTAssertEqual(receivedResponse.url, response.url)
        XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
        
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHttpURLResponseWithNilData() {
        let response = anyHTTPURLResponse()
        let emptyData = Data()
        
        let (receivedData, receivedResponse) = resultValuesFor(data: nil, response: response, error: nil)!
    
        XCTAssertEqual(receivedData, emptyData)
        XCTAssertEqual(receivedResponse.url, response.url)
        XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
    }
    
    // MARK: - Failure Tests
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
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
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> HttpClient {
        createAndTrackMemoryLeaks(URLSessionHttpClient(), file: file, line: line)
    }

    func resultValuesFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        switch resultFor(data: data, response: response, error: error, file: file, line: line) {
        case let .success((data, res)):
            return (data, res)
        default:
            return nil
        }
    }
    
    func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        switch resultFor(data: data, response: response, error: error, file: file, line: line) {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
    
    func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> HttpClientResult? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        var result: HttpClientResult? = nil

        let expectation = expectation(description: #function)

        sut.get(from: anyURL()) {
            result = $0
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 0.1)
        return result
    }
    
    // MARK: - URLProtocolStub

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
