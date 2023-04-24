import UIKit
import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

@testable import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeedActions_requestsTheFeedFromTheLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadCallCount, 0, "Expecting no load request on initialization")
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1, "Expecting the first load event on viewDidLoad")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 2, "Expecting another load event when a user triggers a refresh")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadCallCount, 3, "Expecting another load event when a user triggers a refresh")
    }
    
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expecting a loading indicator to appear when viewDidLoad gets invoked")
        
        loader.completeFeedLoading(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expecting a loading indicator to disappear when the load job is completes successfully")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expecting a loading indicator to appear when a manual refresh occurs")
        
        loader.completeFeedLoading(with: anyNSError(), at: 1)
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expecting a loading indicator to disappear when the load job is complete, even if it's an error")
    }
    
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let images = [
            makeImage(description: "a description", location: "a location"),
            makeImage(description: nil, location: "a location"),
            makeImage(description: "a description", location: nil),
            makeImage(description: nil, location: nil),
        ]
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: images, at: 0)
        assertThat(sut, isRendering: images)
    }
    
    func test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError() {
        let image0 = uniqueImage()
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0], at: 0)
        assertThat(sut, isRendering: [image0])
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: anyNSError(), at: 1)
        assertThat(sut, isRendering: [image0])
    }
    
    // MARK: - Helpers

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = createAndTrackMemoryLeaks(LoaderSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(FeedViewController(loader: loader), file: file, line: line)
        return (sut, loader)
    }
    
    func assertThat(_ sut: FeedViewController, isRendering images: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(sut.numberOfRenderedFeedImageViews(), images.count)
        
        images.enumerated().forEach { (index, image) in
            assertThat(sut, hasViewConfiguredFor: image, at: index)
        }
    }
    
    func assertThat(_ sut: FeedViewController, hasViewConfiguredFor image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
        guard let view = sut.feedImageView(at: index) as? FeedImageCell else {
            XCTFail("Expected to find a FeedImageCell at index: \(index) but found none", file: file, line: line)
            return
        }
        XCTAssertEqual(view.isShowingLocation, (image.location != nil), file: file, line: line)
        XCTAssertEqual(view.locationText, image.location, file: file, line: line)
        XCTAssertEqual(view.descriptionText, image.description, file: file, line: line)
    }
    
    class LoaderSpy: FeedLoader {
        var loadCallCount: Int {
            completions.count
        }
    
        private(set) var completions = [(FeedLoader.Result) -> Void]()

        func load(completion: @escaping (Result<[EssentialFeed.FeedImage], Error>) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading(with images: [FeedImage] = [], at index: Int = 0) {
            completions[index](.success(images))
        }
        
        func completeFeedLoading(with error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }
        
    }
}

// MARK: - DSL Helpers

extension FeedViewController {
    var feedImageSection: Int {
        0
    }
    
    func feedImageView(at index: Int) -> UITableViewCell? {
        let dataSource = tableView.dataSource
        let index = IndexPath(row: index, section: feedImageSection)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }
    
    func numberOfRenderedFeedImageViews() -> Int {
        tableView.numberOfRows(inSection: feedImageSection)
    }
    
    
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

extension FeedImageCell {
    var isShowingLocation: Bool {
        !locationContainer.isHidden
    }
    
    var locationText: String? {
        locationLabel.text
    }
    
    var descriptionText: String? {
        descriptionLabel.text
    }
}
