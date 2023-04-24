import UIKit
import XCTest
import EssentialFeed
@testable import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadsFeed() {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    class LoaderSpy: FeedLoader {
        func load(completion: @escaping (Result<[EssentialFeed.FeedImage], Error>) -> Void) {
            loadCallCount += 1
        }
        
        private(set) var loadCallCount = 0
    }
}


final class FeedViewController: UIViewController {
    var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader?.load { _ in
        }
    }
}
