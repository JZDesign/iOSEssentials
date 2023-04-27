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

    private var cellController = [IndexPath: FeedImageCellController]()
    
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
        cellController(forRowAt: indexPath).view()
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        removeCellController(at: indexPath)
    }
    
    // MARK: - UITableViewDataSourcePrefetching
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { index in
            cellController(forRowAt: index).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { index in
            removeCellController(at: index)
        }
    }
    
    // MARK: - Helpers
    
    func removeCellController(at indexPath: IndexPath) {
        cellController[indexPath]?.cancel()
        cellController[indexPath] = nil
    }
    
    func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        let controller = FeedImageCellController(model: tableModel[indexPath.row], imageLoader: imageLoader)
        cellController[indexPath] = controller
        return controller
    }
}
