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
    var view: FeedView?
    var loadingView: FeedLoadingView?
    
    func didStartLoadingFeed() {
        loadingView?.display(FeedLoadingViewModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with error: Error) {
        loadingView?.display(FeedLoadingViewModel(isLoading: false))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        loadingView?.display(FeedLoadingViewModel(isLoading: false))
        view?.display(FeedViewModel(feed: feed))
    }
}


