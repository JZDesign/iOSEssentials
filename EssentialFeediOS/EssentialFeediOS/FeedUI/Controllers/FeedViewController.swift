import UIKit
import Foundation
import EssentialFeed

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var feedRefreshViewController: FeedRefreshViewController? = nil
    private var imageLoader: FeedImageDataLoader? = nil

    private var tableModel = [FeedImage]() {
        didSet {
            tableView.reloadData()
        }
    }

    private var tasks = [IndexPath: FeedImageDataLoaderTask]()
    
    public init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.feedRefreshViewController = FeedRefreshViewController(feedLoader: feedLoader)
        self.imageLoader = imageLoader
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.prefetchDataSource = self
        setupRefreshControl()
    }
    
    private func setupRefreshControl() {
        refreshControl = feedRefreshViewController?.view
        feedRefreshViewController?.onRefresh = { [weak self] feed in
            self?.tableModel = feed
        }
        feedRefreshViewController?.refresh()
    }
    
    // MARK: - Table View
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = tableModel[indexPath.row]
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = (model.location == nil)
        cell.locationLabel.text = model.location
        cell.descriptionLabel.text = model.description

        cell.feedImageView.image = nil // ALWAYS set to nil before loading to prevent issues with reusing cells
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainer.startShimmering()
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            
            self.tasks[indexPath] = self.imageLoader?.loadImageData(from: model.url) { [weak cell] result in
                guard let cell = cell else { return }
                switch result {
                case let .success(data):
                    guard let image = UIImage(data: data) else {
                        fallthrough
                    }
                    cell.feedImageView.image = image
                case .failure:
                    cell.feedImageRetryButton.isHidden = false
                }
                cell.feedImageContainer.stopShimmering()
            }
        }
        cell.onRetry = loadImage
        loadImage()
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
    
    // MARK: - UITableViewDataSourcePrefetching
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { index in
            let model = tableModel[index.row]
            tasks[index] = imageLoader?.loadImageData(from: model.url, completion: { _ in }) // This assumes that the loader will be able to pick up where it left off… right?
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { index in
            tasks[index]?.cancel()
            tasks[index] = nil
        }
    }
}
