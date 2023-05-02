import UIKit
import EssentialFeed


// This follows the adapter pattern because it insulates the view controller from the knowledge of the feed loader and the data loader and how to map the feed image to the feed image controller.
public struct FeedUIComposer {
    private init() {}
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        let feedRefreshViewController = FeedRefreshViewController(feedLoader: feedLoader)
        let feedViewController = FeedViewController(feedRefreshViewController: feedRefreshViewController)

        feedRefreshViewController.onRefresh = adaptFeedToCellControllers(forwardingTo: feedViewController, loader: imageLoader)

        return feedViewController
    }
    
    private static func adaptFeedToCellControllers(
        forwardingTo controller: FeedViewController,
        loader: FeedImageDataLoader
    ) -> ([FeedImage]) -> Void {
        { [weak controller] feed in
            controller?.tableModel = feed.map { FeedImageCellController(model: $0, imageLoader: loader) }
        }
    }
}
