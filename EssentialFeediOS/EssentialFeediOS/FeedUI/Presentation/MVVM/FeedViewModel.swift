import EssentialFeed

// This version is for MVVM commented out for the MVP version we used
//final class FeedViewModel {
//    typealias Observer<T> = (T) -> Void
//    let feedLoader: FeedLoader
//
//    init(feedLoader: FeedLoader) {
//        self.feedLoader = feedLoader
//    }
//
//    var onLoadingStateChange: Observer<Bool>?
//    var onFeedLoad: Observer<[FeedImage]>?
//
//    func loadFeed() {
//        onLoadingStateChange?(true)
//        feedLoader.load { [weak self] result in
//            switch result {
//            case .success(let images):
//                self?.onFeedLoad?(images)
//            case .failure(let error):
//                print(error)
//                // TODO: Fix this ^^ -- do more than print the error
//            }
//            self?.onLoadingStateChange?(false)
//        }
//    }
//}
