import EssentialFeed

final class FeedViewModel {
    let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }

    private var state = State.pending {
        didSet { onChange?(self) }
    }
    
    var onChange: ((FeedViewModel) -> Void)?
    var onFeedLoad: (([FeedImage]) -> Void)?
    
    var isLoading : Bool {
        state == .loading
    }
    
    var feed: [FeedImage]? {
        switch state {
        case .loaded(let images):
            return images
        default:
            return nil
        }
    }
    
    func loadFeed() {
        state = .loading
        feedLoader.load { [weak self] result in
            switch result {
            case .success(let images):
                self?.state = .loaded(images)
                self?.onFeedLoad?(images)
            case .failure(let error):
                self?.state = .failed
                print(error)
                // TODO: Fix this ^^
            }
        }
    }
    
    private enum State: Equatable {
        case pending, loading, loaded([FeedImage]), failed
    }
}
