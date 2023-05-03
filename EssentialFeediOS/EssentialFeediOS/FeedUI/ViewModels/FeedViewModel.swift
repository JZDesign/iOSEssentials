import EssentialFeed

final class FeedViewModel {
    let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    var onChange: ((FeedViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?

    var isLoading : Bool = false {
        didSet { onChange?(self) }
    }
    
    func loadFeed() {
        isLoading = true
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let images):
                self?.onFeedLoad?(images)
            case .failure(let error):
                print(error)
                // TODO: Fix this ^^ -- do more than print the error
            }
            self?.isLoading = false
        }
    }
}
