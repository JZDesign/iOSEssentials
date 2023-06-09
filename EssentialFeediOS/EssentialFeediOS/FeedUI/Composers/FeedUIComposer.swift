import UIKit
import EssentialFeed


// This follows the adapter pattern because it insulates the view controller from the knowledge of the feed loader and the data loader and how to map the feed image to the feed image controller.
public struct FeedUIComposer {
    private init() {}
    public static func feedComposedWith(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) -> FeedViewController {
        
        let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: MainQueueDispatchDecorator(decoratee: feedLoader))
        
        let storyBoard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let feedViewController = storyBoard.instantiateInitialViewController() as! FeedViewController
        feedViewController.feedRefreshViewController!.loadFeed = presentationAdapter.loadFeed

        let presenter = FeedPresenter(
            view: FeedViewAdapter(controller: feedViewController, imageLoader: MainQueueDispatchDecorator(decoratee: imageLoader)),
            loadingView: WeakReferenceVirtualProxy(object:  feedViewController.feedRefreshViewController!)
        )
        presentationAdapter.presenter = presenter

        return feedViewController
    }
    
}

private final class MainQueueDispatchDecorator<Decoratee> {
    private let decoratee: Decoratee
    
    init(decoratee: Decoratee) {
        self.decoratee = decoratee
    }
    
    func dispatch(completion: @escaping () -> Void) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.async {
                completion()
            }
        }
        completion()
    }
}

extension MainQueueDispatchDecorator: FeedImageDataLoader where Decoratee == FeedImageDataLoader {
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
        return decoratee.loadImageData(from: url) { [weak self] result in
            self?.dispatch(completion: {
                completion(result)
            })
        }
    }
}

extension MainQueueDispatchDecorator: FeedLoader where Decoratee == FeedLoader {
    func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {
        decoratee.load { [weak self] result in
            self?.dispatch { completion(result) }
        }
    }
}

// MVP
private final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private var imageLoader: FeedImageDataLoader?
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }

    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { FeedImageCellController(model: $0, imageLoader: imageLoader) }
    }
}

private final class WeakReferenceVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(object: T) {
        self.object = object
    }
    
}

extension WeakReferenceVirtualProxy: FeedLoadingView where T: FeedLoadingView {
    func display(_ viewModel: FeedLoadingViewModel) {
        object?.display(viewModel)
    }
}

// note we could use a delegate and pass the adpter around instead of the function reference
private final class FeedLoaderPresentationAdapter {
    private let feedLoader: FeedLoader
    var presenter: FeedPresenter?
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
    func loadFeed() {
        presenter?.didStartLoadingFeed()

        feedLoader.load { [weak self] result in
            switch result {
            case .success(let feed):
                self?.presenter?.didFinishLoadingFeed(with: feed)
            case .failure(let error):
                self?.presenter?.didFinishLoadingFeed(with: error)
            }
        }
    }
}
