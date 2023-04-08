import Foundation
import EssentialFeed
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
    
    func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let item1 = uniqueImage()
        let item2 = uniqueImage()
        return ([item1, item2], [LocalFeedImage.from(item1), LocalFeedImage.from(item2)])
    }
}

public extension Date {
    func minusFeedCacheMaxAge() -> Date {
        adding(days: -7)
    }
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
