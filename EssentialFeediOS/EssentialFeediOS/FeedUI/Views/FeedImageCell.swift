import UIKit

public final class FeedImageCell: UITableViewCell {
    // finish updating this to match the UIStoryboard setup in this lecture
    // https://academy.essentialdeveloper.com/courses/447455/lectures/11390253
    // starting around 13 minutes
    public let feedImageContainer = UIView()
    public let feedImageView = UIImageView()
    public let locationContainer = UIView()
    public let locationLabel = UILabel()
    public let descriptionLabel = UILabel()
    
    var onRetry: () -> Void = {}
    private(set) public lazy var feedImageRetryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc
    private func retryButtonTapped() {
        onRetry()
    }
}
