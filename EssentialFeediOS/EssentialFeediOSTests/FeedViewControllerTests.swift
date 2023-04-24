import XCTest

import EssentialFeed
@testable import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    class LoaderSpy {
        private(set) var loadCallCount = 0
    }
}


final class FeedViewController {
    init(loader: FeedViewControllerTests.LoaderSpy) {
    }
}
