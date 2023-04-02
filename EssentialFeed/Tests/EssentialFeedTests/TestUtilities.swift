import Foundation
import XCTest

extension XCTestCase {
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
}
