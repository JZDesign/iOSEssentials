import UIKit

public final class FeedRefreshViewController: NSObject, FeedLoadingView {
    
    // MVP
    let presenter: FeedPresenter
    private(set) lazy var view: UIRefreshControl = loadView()

    init(presenter: FeedPresenter) {
        self.presenter = presenter
    }
    
    // MVVM
    // let viewModel: FeedViewModel
    // private(set) lazy var view: UIRefreshControl = binded(UIRefreshControl())
    // init(viewModel: FeedViewModel) {
    //     self.viewModel = viewModel
    // }

    @objc func refresh() {
        // viewModel.loadFeed()
        presenter.loadFeed()
    }
    
    // MARK: - Feed Loading View
    
    public func display(isLoading: Bool) {
        if isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }

    // MARK: - Helpers
    // MVP
    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
    
    // MVVM
    //    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
    //        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
    //        viewModel.onLoadingStateChange = { [weak view] isLoading in
    //            if isLoading {
    //                view?.beginRefreshing()
    //            } else {
    //                view?.endRefreshing()
    //            }
    //        }
    //        return view
    //    }
}
