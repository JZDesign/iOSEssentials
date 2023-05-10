import UIKit
import Foundation
import EssentialFeed

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    var feedRefreshViewController: FeedRefreshViewController? = nil

    internal var tableModel = [FeedImageCellController]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    internal init(feedRefreshViewController: FeedRefreshViewController) {
        self.feedRefreshViewController = feedRefreshViewController
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.prefetchDataSource = self
        setupRefreshControl()
    }
    
    private func setupRefreshControl() {
        refreshControl = feedRefreshViewController?.view
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
        cancelLoads(at: indexPath)
    }
    
    // MARK: - UITableViewDataSourcePrefetching
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { index in
            cellController(forRowAt: index).preload()
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { index in
            cancelLoads(at: index)
        }
    }
    
    // MARK: - Helpers
    
    func cancelLoads(at indexPath: IndexPath) {
        tableModel[indexPath.row].cancel()
    }
    
    func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        tableModel[indexPath.row]
    }
}
