import EssentialFeed

public protocol FeedLoadingView {
    func display(isLoading: Bool)
}

public protocol FeedView {
    func display(feed: [FeedImage])
}

final class FeedPresenter {
    typealias Observer<T> = (T) -> Void
    let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var view: FeedView?
    var loadingView: FeedLoadingView?
    
    func loadFeed() {
        loadingView?.display(isLoading: true)
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let images):
                self?.view?.display(feed: images)
            case .failure(let error):
                print(error)
                // TODO: Fix this ^^ -- do more than print the error
            }
            self?.loadingView?.display(isLoading: false)
        }
    }
}
