import UIKit
import EssentialFeed


// This follows the adapter pattern because it insulates the view controller from the knowledge of the feed loader and the data loader and how to map the feed image to the feed image controller.
public struct FeedUIComposer {
    private init() {}
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        //        let viewModel = FeedViewModel(feedLoader: feedLoader)
        
        let presenter = FeedPresenter(feedLoader: feedLoader)
        let feedRefreshViewController = FeedRefreshViewController(presenter: presenter)
        let feedViewController = FeedViewController(feedRefreshViewController: feedRefreshViewController)

        presenter.loadingView = feedRefreshViewController
        presenter.view = FeedViewAdapter(controller: feedViewController, imageLoader: imageLoader)
        //        viewModel.onFeedLoad = adaptFeedToCellControllers(forwardingTo: feedViewController, loader: imageLoader)

        return feedViewController
    }
    
    // MVVM
    //    private static func adaptFeedToCellControllers(
    //        forwardingTo controller: FeedViewController,
    //        loader: FeedImageDataLoader
    //    ) -> ([FeedImage]) -> Void {
    //        { [weak controller] feed in
    //            controller?.tableModel = feed.map { FeedImageCellController(model: $0, imageLoader: loader) }
    //        }
    //    }
}

// MVP
private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private var imageLoader: FeedImageDataLoader?
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }

    func display(feed: [EssentialFeed.FeedImage]) {
        controller?.tableModel = feed.map { FeedImageCellController(model: $0, imageLoader: imageLoader) }
    }
    
}
