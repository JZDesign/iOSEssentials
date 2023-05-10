import UIKit

public final class FeedRefreshViewController: NSObject, FeedLoadingView {
    var loadFeed: () -> Void = {}
    @IBOutlet var view: UIRefreshControl?

    public override init() {}
    
    @IBAction func refresh() {
        loadFeed()
    }
    
    // MARK: - Feed Loading View
    
    public func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view?.beginRefreshing()
        } else {
            view?.endRefreshing()
        }
    }

    // MARK: - Helpers
//    private func loadView() -> UIRefreshControl {
//        let view = UIRefreshControl()
//        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
//        return view
//    }
}
