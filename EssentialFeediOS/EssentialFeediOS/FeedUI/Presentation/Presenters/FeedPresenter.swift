import EssentialFeed

public struct FeedLoadingViewModel {
    let isLoading: Bool

    public init(isLoading: Bool) {
        self.isLoading = isLoading
    }
}

public struct FeedViewModel {
    let feed: [FeedImage]

    public init(feed: [FeedImage]) {
        self.feed = feed
    }
}


public protocol FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel)
}

public protocol FeedView {
    func display(_ viewModel: FeedViewModel)
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
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let images):
                self?.view?.display(FeedViewModel(feed: images))
            case .failure(let error):
                print(error)
                // TODO: Fix this ^^ -- do more than print the error
            }
            self?.loadingView?.display(FeedLoadingViewModel(isLoading: false))
        }
    }
}
