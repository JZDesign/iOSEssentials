import UIKit
import EssentialFeed

public final class FeedRefreshViewController: NSObject {
    let viewModel: FeedViewModel
    var onRefresh: ([FeedImage]) -> Void = { _ in }
    
    private(set) lazy var view: UIRefreshControl = binded(UIRefreshControl())
    
    init(feedLoader: FeedLoader) {
        self.viewModel = FeedViewModel(feedLoader: feedLoader)
    }

    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    // MARK: - Helpers
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        viewModel.onChange = { [weak self] vm in
            if vm.isLoading {
                view.beginRefreshing()
            } else {
                view.endRefreshing()
            }
            
            if let feed = vm.feed {
                self?.onRefresh(feed)
            }
        }
        return view
    }
}
