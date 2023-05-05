import UIKit
import EssentialFeed


// This follows the adapter pattern because it insulates the view controller from the knowledge of the feed loader and the data loader and how to map the feed image to the feed image controller.
public struct FeedUIComposer {
    private init() {}
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        
        let presenter = FeedPresenter()
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader, presenter: presenter)
        
        let feedRefreshViewController = FeedRefreshViewController(loadFeed: presentationAdapter.loadFeed)
        let feedViewController = FeedViewController(feedRefreshViewController: feedRefreshViewController)

        presenter.loadingView = WeakReferenceVirtualProxy(object:  feedRefreshViewController)
        presenter.view = FeedViewAdapter(controller: feedViewController, imageLoader: imageLoader)

        return feedViewController
    }
    
}

// MVP
private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private var imageLoader: FeedImageDataLoader?
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }

    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { FeedImageCellController(model: $0, imageLoader: imageLoader) }
    }
}

private final class WeakReferenceVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(object: T) {
        self.object = object
    }
    
}

extension WeakReferenceVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}


private final class FeedLoaderPresentationAdapter {
    private let feedLoader: FeedLoader
    private let presenter: FeedPresenter
    
    init(feedLoader: FeedLoader, presenter: FeedPresenter) {
        self.feedLoader = feedLoader
        self.presenter = presenter
    }
    
    func loadFeed() {
        presenter.didStartLoadingFeed()

        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.presenter.didFinishLoadingFeed(with: feed)
            case .failure(let error):
                self?.presenter.didFinishLoadingFeed(with: error)
            }
        }
    }
}
