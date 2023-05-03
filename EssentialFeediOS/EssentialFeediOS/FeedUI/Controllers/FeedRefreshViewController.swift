import UIKit

public final class FeedRefreshViewController: NSObject {
    let viewModel: FeedViewModel
    
    private(set) lazy var view: UIRefreshControl = binded(UIRefreshControl())
    
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }

    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    // MARK: - Helpers
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        viewModel.onChange = { vm in
            if vm.isLoading {
                view.beginRefreshing()
            } else {
                view.endRefreshing()
            }
        }
        return view
    }
}
