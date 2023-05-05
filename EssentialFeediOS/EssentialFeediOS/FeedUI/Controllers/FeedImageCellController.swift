import UIKit
import EssentialFeed


// TODO: - Extract state management into a view model that does not know anything about UIKit. (hint, use generic closures to let the platform pass in the way to take data and turn it into the image it cares about)
public final class FeedImageCellController {
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader?
    
    init(model: FeedImage, imageLoader: FeedImageDataLoader?) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func view() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.locationContainer.isHidden = (model.location == nil)
        cell.locationLabel.text = model.location
        cell.descriptionLabel.text = model.description

        cell.feedImageView.image = nil // ALWAYS set to nil before loading to prevent issues with reusing cells
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageContainer.startShimmering()
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            
            self.task = self.imageLoader?.loadImageData(from: self.model.url) { [weak cell] result in
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
    
    func preload() {
        // Doesn't this rely on the loader to know how to pick up the same task and load the image from cached data?
        self.task = self.imageLoader?.loadImageData(from: self.model.url) { _ in }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}
