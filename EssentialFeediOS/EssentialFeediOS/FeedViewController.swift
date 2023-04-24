import UIKit
import Foundation
import EssentialFeed

public final class FeedViewController: UITableViewController {
    var loader: FeedLoader? = nil
    private var tableModel = [FeedImage]()
    
    public init(loader: FeedLoader) {
        self.loader = loader
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
        loader?.load { [weak self] result in
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
        return cell
    }
}
