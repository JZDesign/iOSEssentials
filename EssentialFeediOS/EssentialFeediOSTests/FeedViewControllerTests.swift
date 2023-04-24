import UIKit
import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

@testable import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeedActions_requestsTheFeedFromTheLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0)
   
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 3)
    }

    func test_loadFeedActions_correctlyDisplaysAndHidesTheLoadingIndicator() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator)

        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator)
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator)

        loader.completeFeedLoading(at: 1)

        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    // MARK: - Helpers
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = createAndTrackMemoryLeaks(LoaderSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(FeedViewController(loader: loader), file: file, line: line)
        return (sut, loader)
    }
    
    class LoaderSpy: FeedLoader {
        var loadCallCount: Int {
            completions.count
        }
    
        private(set) var completions = [(FeedLoader.Result) -> Void]()

        func load(completion: @escaping (Result<[EssentialFeed.FeedImage], Error>) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading(at index: Int = 0) {
            completions[index](.success([]))
        }
        
    }
}


final class FeedViewController: UITableViewController {
    var loader: FeedLoader? = nil
    
    init(loader: FeedLoader) {
        self.loader = loader
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshControl()
        load()
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        loader?.load { [refreshControl] _ in
            refreshControl?.endRefreshing()
        }
    }
}

extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing ?? false
    }
}

extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({
                (target as NSObject).perform(Selector($0))
            })
        })
    }
}
