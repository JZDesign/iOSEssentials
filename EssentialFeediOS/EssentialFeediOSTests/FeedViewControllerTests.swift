import UIKit
import XCTest
import EssentialFeed
import EssentialFeedAPITestUtilities

@testable import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {
    
    func test_loadFeedActions_requestsTheFeedFromTheLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loadFeedRequestCallCount, 0, "Expecting no load request on initialization")
        
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadFeedRequestCallCount, 1, "Expecting the first load event on viewDidLoad")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedRequestCallCount, 2, "Expecting another load event when a user triggers a refresh")
        
        sut.simulateUserInitiatedFeedReload()
        XCTAssertEqual(loader.loadFeedRequestCallCount, 3, "Expecting another load event when a user triggers a refresh")
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
    
    func test_feedImageView_loadsImageURLWhenVisible() {
        let images = [
            makeImage(description: "a description", location: "a location", url: URL(string: "http://url-0.com")!),
            makeImage(description: nil, location: nil, url: URL(string: "http://url-1.com")!),
        ]
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: images)
        XCTAssertEqual(loader.loadedImageURLs, [])
        
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(loader.loadedImageURLs, [images.first!.url], "Expected first image URL request once the first view became visible")

        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, images.map(\.url), "Expected all image URLs to be requested once the views became visible")
    }

    func test_feedImageView_cancelsImageURLLoadingWhenViewIsNoLongerVisible() {
        let images = [
            makeImage(description: "a description", location: "a location", url: URL(string: "http://url-0.com")!),
            makeImage(description: nil, location: nil, url: URL(string: "http://url-1.com")!),
        ]
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: images)
        XCTAssertEqual(loader.loadedImageURLs, [])
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(loader.cancelledImageURLs, [images.first!.url], "Expected first image URL request once the first view became visible")

        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(loader.cancelledImageURLs, images.map(\.url), "Expected all image URLs to be requested once the views became visible")
    }
    
    
    // MARK: - Helpers

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = createAndTrackMemoryLeaks(LoaderSpy(), file: file, line: line)
        let sut = createAndTrackMemoryLeaks(FeedViewController(feedLoader: loader, imageLoader: loader), file: file, line: line)
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
    
    class LoaderSpy: FeedLoader, FeedImageDataLoader {
        var loadFeedRequestCallCount: Int { feedRequests.count }

        private(set) var loadedImageURLs: [URL] = []
        private(set) var cancelledImageURLs: [URL] = []
        private(set) var feedRequests = [(FeedLoader.Result) -> Void]()

        // MARK: - Feed Loader

        func load(completion: @escaping (Result<[EssentialFeed.FeedImage], Error>) -> Void) {
            feedRequests.append(completion)
        }
        
        func completeFeedLoading(with images: [FeedImage] = [], at index: Int = 0) {
            feedRequests[index](.success(images))
        }
        
        func completeFeedLoading(with error: Error, at index: Int = 0) {
            feedRequests[index](.failure(error))
        }
        
        // MARK: - Feed Image Data Loader
        
        func loadImageData(from url: URL) {
            loadedImageURLs.append(url)
        }
        
        func cancelImageDataLoad(from url: URL) {
            cancelledImageURLs.append(url)
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
    
    func simulateFeedImageViewVisible(at index: Int) {
        _ = feedImageView(at: index)
    }

    func simulateFeedImageViewNotVisible(at index: Int) {
        let view = feedImageView(at: index)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: index, section: feedImageSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
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
