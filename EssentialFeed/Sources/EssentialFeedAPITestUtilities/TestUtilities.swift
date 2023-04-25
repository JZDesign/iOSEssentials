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
    
    func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    func makeImage(description: String?, location: String?, url: URL = anyURL()) -> FeedImage {
        FeedImage(id: UUID(), description: description, location: location, url: url)
    }
    
    func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let item1 = uniqueImage()
        let item2 = uniqueImage()
        return ([item1, item2], [LocalFeedImage.from(item1), LocalFeedImage.from(item2)])
    }
}

public extension Date {
    private var maxCacheAge: Int { 7 }

    func minusFeedCacheMaxAge() -> Date {
        adding(days: -maxCacheAge)
    }

    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

public func anyURL() -> URL {
    URL(string: "https://a-url.com")!
}

public func nonHTTPURLResponse() -> URLResponse {
    URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
}

public func anyHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
}

public func anyData() -> Data {
    Data("any data".utf8)
}

public func anyNSError() -> NSError {
    NSError(domain: #function, code: #line)
}
