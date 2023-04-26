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

    func test_feedImageViewLoadingIndicator_isVisibleWhenLoadingImage() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: uniqueImageFeed().models)

        let images = [
            sut.simulateFeedImageViewVisible(at: 0),
            sut.simulateFeedImageViewVisible(at: 1),
        ]
                
        XCTAssertTrue(images[0]!.isShowingImageLoadingIndicator, "Expected first loading indicator to display once the first url load was invoked")
        XCTAssertTrue(images[1]!.isShowingImageLoadingIndicator, "Expected all loading indicators to be displayed once the all of the url loads were invoked")
        
        loader.completeImageLoading(at: 0)
        XCTAssertFalse(images[0]!.isShowingImageLoadingIndicator, "Expected first loading indicator to no longer be displayed when the first url load finished")
        XCTAssertTrue(images[1]!.isShowingImageLoadingIndicator, "Expected the second loading indicator to still be displayed after the first view's url finsihed loading")

        loader.completeImageLoadingWithError(at: 1)
        XCTAssertFalse(images[1]!.isShowingImageLoadingIndicator, "Expected no loading indicator on the view if the url load returned an error")
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
    
    func test_feedImageView_rendersImageLoadedFromURL() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: uniqueImageFeed().models)

        let images = [
            sut.simulateFeedImageViewVisible(at: 0),
            sut.simulateFeedImageViewVisible(at: 1),
        ]
        
        let imageData1 = UIImage.make(withColor: .systemPink).pngData()!
        let imageData2 = UIImage.make(withColor: .systemBlue).pngData()!
                
        XCTAssertEqual(images[0]!.renderedImage, .none, "Expected no image for first view while loading first image")
        XCTAssertEqual(images[1]!.renderedImage, .none, "Expected no image for second view while loading second image")
        
        loader.completeImageLoading(with: imageData1, at: 0)
        XCTAssertEqual(images[0]!.renderedImage, imageData1, "Expected image for first view")
        XCTAssertEqual(images[1]!.renderedImage, .none, "Expected no image for second view while loading second image and first image completed loading")
        
        loader.completeImageLoading(with: imageData2, at: 1)
        XCTAssertEqual(images[0]!.renderedImage, imageData1, "Expected image for first view")
        XCTAssertEqual(images[1]!.renderedImage, imageData2, "Expected image for second view")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnURLLoadError() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: uniqueImageFeed().models)

        let images = [
            sut.simulateFeedImageViewVisible(at: 0),
            sut.simulateFeedImageViewVisible(at: 1),
        ]
        
        let imageData1 = UIImage.make(withColor: .systemPink).pngData()!
                
        XCTAssertFalse(images[0]!.isShowingRetryAction, "Expected image download retry button for first view")
        XCTAssertFalse(images[1]!.isShowingRetryAction, "Expected image download retry button for second view")
        
        loader.completeImageLoading(with: imageData1, at: 0)
        XCTAssertFalse(images[0]!.isShowingRetryAction, "Expected no image download retry button for first view")
        XCTAssertFalse(images[1]!.isShowingRetryAction, "Expected no image download retry button for second view while loading second image and first image completed loading")
        
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertTrue(images[1]!.isShowingRetryAction, "Expected to see the image download retry button when there was an error loading the data")
        XCTAssertFalse(images[0]!.isShowingRetryAction, "Expected no image download retry button for second view when loading is complete")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnInvalidImageData() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: uniqueImageFeed().models)

        let images = [
            sut.simulateFeedImageViewVisible(at: 0),
            sut.simulateFeedImageViewVisible(at: 1),
        ]
        
        let imageData1 = UIImage.make(withColor: .systemPink).pngData()!
        let imageData2 = "some invalid image data".data(using: .utf8)!
                
        XCTAssertFalse(images[0]!.isShowingRetryAction, "Expected image download retry button for first view")
        XCTAssertFalse(images[1]!.isShowingRetryAction, "Expected image download retry button for second view")
        
        loader.completeImageLoading(with: imageData1, at: 0)
        XCTAssertFalse(images[0]!.isShowingRetryAction, "Expected no image download retry button for first view")
        XCTAssertFalse(images[1]!.isShowingRetryAction, "Expected no image download retry button for second view while loading second image and first image completed loading")
        
        loader.completeImageLoading(with: imageData2, at: 1)
        XCTAssertTrue(images[1]!.isShowingRetryAction, "Expected to see the image download retry button when there was an error loading the data")
        XCTAssertFalse(images[0]!.isShowingRetryAction, "Expected no image download retry button for second view when loading is complete")
    }
    
    func test_feedImageViewRetryButton_triggersReloadWhenPressed() {
        let image0 = makeImage(description: "0", location: nil, url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(description: "1", location: nil, url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])

        let view0 = sut.simulateFeedImageViewVisible(at: 0)!
        let view1 = sut.simulateFeedImageViewVisible(at: 1)!
        
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expect 2 initial url requests")
        
        loader.completeImageLoadingWithError(at: 0)
        loader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url], "Expect the same 2 url requests before retry (no more have ocurred")
        
        view0.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url, image0.url], "Expect the same 2 url requests before retry (no more have ocurred")

        view1.simulateRetryAction()
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url, image0.url, image1.url], "Expect the same 2 url requests before retry (no more have ocurred")
    }
    
    func test_feedImageView_preloadsImageURLWhenNearVisible() {
        let image0 = makeImage(description: "0", location: nil, url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(description: "1", location: nil, url: URL(string: "http://url-1.com")!)
        
        let (sut, loader) = makeSUT()
        
        sut.loadViewIfNeeded()
        loader.completeFeedLoading(with: [image0, image1])

        sut.simulateFeedImageNearViewVisible(at: 0)
        
        XCTAssertEqual(loader.loadedImageURLs, [image0.url])
        
        sut.simulateFeedImageNearViewVisible(at: 1)
        XCTAssertEqual(loader.loadedImageURLs, [image0.url, image1.url])
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

        private(set) var cancelledImageURLs: [URL] = []
        private(set) var feedRequests = [(FeedLoader.Result) -> Void]()
        private(set) var imageRequests = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()
        var loadedImageURLs: [URL] {
            imageRequests.map(\.url)
        }

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
        
        func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
            imageRequests[index].completion(.success(imageData))
        }
        
        func completeImageLoadingWithError(_ error: Error = anyNSError(), at index: Int = 0) {
            imageRequests[index].completion(.failure(error))
        }
        
        // MARK: - Feed Image Data Loader
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
            imageRequests.append((url, completion))
            return TaskSpy { [weak self] in self?.cancelledImageURLs.append(url) }
        }
        
        private struct TaskSpy: FeedImageDataLoaderTask {
            let cancelCallback: () -> Void

            func cancel() {
                 cancelCallback()
            }
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
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        feedImageView(at: index) as? FeedImageCell
    }
    
    func simulateFeedImageNearViewVisible(at index: Int) {
        let ds = tableView.prefetchDataSource
        let index = IndexPath(row: index, section: feedImageSection)
        ds?.tableView(tableView, prefetchRowsAt: [index])
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

extension UIControl {
    func simulate(action: UIControl.Event) {
        allTargets.forEach({ target in
            actions(forTarget: target, forControlEvent: action)?.forEach({
                (target as NSObject).perform(Selector($0))
            })
        })
    }
}

extension UIRefreshControl {
    func simulatePullToRefresh() {
        simulate(action: .valueChanged)
    }
}

extension UIButton {
    func simulateTap() {
        simulate(action: .touchUpInside)
    }
}

extension FeedImageCell {
    var isShowingImageLoadingIndicator: Bool {
        feedImageContainer.isShimmering
    }

    var isShowingLocation: Bool {
        !locationContainer.isHidden
    }
    
    var locationText: String? {
        locationLabel.text
    }
    
    var descriptionText: String? {
        descriptionLabel.text
    }
    
    var renderedImage: Data? {
        feedImageView.image?.pngData()
    }

    var isShowingRetryAction: Bool {
        !feedImageRetryButton.isHidden
    }
    
    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
    }
}

extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: rect.size, format: format).image {
            color.setFill()
            $0.fill(rect)
        }
    }
}
