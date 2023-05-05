import UIKit

public final class FeedRefreshViewController: NSObject, FeedLoadingView {
    let loadFeed: () -> Void
    private(set) lazy var view: UIRefreshControl = loadView()

    init(loadFeed: @escaping () -> Void) {
        self.loadFeed = loadFeed
    }
    
    @objc func refresh() {
        loadFeed()
    }
    
    // MARK: - Feed Loading View
    
    public func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }

    // MARK: - Helpers
    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
