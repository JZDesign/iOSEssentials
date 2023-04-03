import Foundation
import XCTest

public extension XCTestCase {
    func trackMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, file: file, line: line)
        }
    }

    func createAndTrackMemoryLeaks<T: AnyObject>(_ initializer: @autoclosure () -> T, file: StaticString = #file, line: UInt = #line) -> T {
        let instance = initializer()
        trackMemoryLeaks(instance)
        return instance
    }
    
    func anyURL() -> URL {
        URL(string: "https://a-url.com")!
    }
    
    func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }
    
    func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
    }
    
    func anyData() -> Data {
        Data("any data".utf8)
    }
    
    func anyNSError() -> NSError {
        NSError(domain: #function, code: #line)
    }
    
}
