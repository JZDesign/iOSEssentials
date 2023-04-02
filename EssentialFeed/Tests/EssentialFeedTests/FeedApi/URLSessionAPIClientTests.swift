//
//  URLSessionAPIClientTests.swift
//  
//
//  Created by Jacob Rakidzich on 4/1/23.
//

import XCTest
import EssentialFeed

protocol HttpSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HttpSessionTask
}

protocol HttpSessionTask {
    func resume()
}

class URLSessionHttpClient {
    private let session: HttpSession
    
    init(session: HttpSession) {
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
    private let url = URL(string: "https://a-url.com")!
    private let session = URLSessionSpy()
    private lazy var sut = URLSessionHttpClient(session: session)

    func test_getFromURL_resumesDataTaskWithURL() {
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        sut.get(from: url) { _ in }
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let error = NSError(domain: #function, code: #line)
        session.stub(url: url, error: error)
        let expectation = expectation(description: #function)
    
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("Expected failure with error: \(error), got \(result) instead.")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
    }
    
    // MARK: - Helpers

    private class URLSessionSpy: HttpSession {
        private var stubs = [URL: Stub]()

        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HttpSessionTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }

        func stub(url: URL, task: HttpSessionTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        private struct Stub {
            let task: HttpSessionTask
            let error: Error?
        }
    }

    private class FakeURLSessionDataTask: HttpSessionTask {
        func resume() {}
    }

    private class URLSessionDataTaskSpy: HttpSessionTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}
