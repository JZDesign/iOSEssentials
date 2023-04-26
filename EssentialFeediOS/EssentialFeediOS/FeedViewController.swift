import UIKit
import Foundation
import EssentialFeed

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) -> FeedImageDataLoaderTask
}

public final class FeedViewController: UITableViewController {
    private var feedLoader: FeedLoader? = nil
    private var imageLoader: FeedImageDataLoader? = nil
    private var tableModel = [FeedImage]()
    private var tasks = [IndexPath: FeedImageDataLoaderTask]()
    
    public init(feedLoader: FeedLoader, imageLoader: FeedImageDataLoader) {
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupRefreshControl()
        load()
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        feedLoader?.load { [weak self] result in
            switch result {
            case .success(let images):
                self?.tableModel = images
            case .failure(let error):
                print(error)
                // TODO: Fix this ^^
            }
            self?.tableView.reloadData()
            self?.refreshControl?.endRefreshing()
        }
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
        tasks[indexPath] = imageLoader?.loadImageData(from: model.url) // TODO: Actually display image…
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let model = tableModel[indexPath.row]
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}
