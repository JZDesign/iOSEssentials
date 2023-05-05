import UIKit

public final class FeedRefreshViewController: NSObject, FeedLoadingView {
    let presenter: FeedPresenter
    private(set) lazy var view: UIRefreshControl = loadView()

    init(presenter: FeedPresenter) {
        self.presenter = presenter
    }
    
    @objc func refresh() {
        presenter.loadFeed()
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
