import UIKit
import EssentialFeed

public final class FeedRefreshViewController: NSObject {
    let feedLoader: FeedLoader
    var onRefresh: ([FeedImage]) -> Void = { _ in }
    
    private(set) lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    @objc func refresh() {
        view.beginRefreshing()
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let images):
                self?.onRefresh(images)
            case .failure(let error):
                print(error)
                // TODO: Fix this ^^
            }
            self?.view.endRefreshing()
        }
    }
}
