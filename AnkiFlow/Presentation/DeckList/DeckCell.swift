import UIKit
import SnapKit

final class DeckCell: UICollectionViewCell {
    static let identifier = "DeckCell"

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = AppConstants.CornerRadius.large
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32)
        label.textAlignment = .center
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let cardCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .textSecondary
        return label
    }()

    private let dueBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .warningColor
        view.layer.cornerRadius = 10
        return view
    }()

    private let dueBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.trackTintColor = .systemGray5
        pv.progressTintColor = .primary
        pv.layer.cornerRadius = 2
        pv.clipsToBounds = true
        return pv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(nameLabel)
        containerView.addSubview(cardCountLabel)
        containerView.addSubview(dueBadge)
        containerView.addSubview(progressView)
        dueBadge.addSubview(dueBadgeLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(AppConstants.Spacing.md)
            make.width.height.equalTo(40)
        }

        dueBadge.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(AppConstants.Spacing.md)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(20)
        }

        dueBadgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(AppConstants.Spacing.sm)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.md)
        }

        cardCountLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(AppConstants.Spacing.xs)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.md)
        }

        progressView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(AppConstants.Spacing.md)
            make.height.equalTo(4)
        }
    }

    func configure(deck: Deck, cardCount: Int, dueCount: Int) {
        nameLabel.text = deck.name
        cardCountLabel.text = "\(cardCount) cards"

        let emoji = ["📚", "🎓", "📖", "🧠", "💡", "🔤", "🌍", "📝"].randomElement() ?? "📚"
        iconLabel.text = emoji

        if dueCount > 0 {
            dueBadge.isHidden = false
            dueBadgeLabel.text = "\(dueCount)"
        } else {
            dueBadge.isHidden = true
        }

        let progress = cardCount > 0 ? Float(cardCount - dueCount) / Float(cardCount) : 0
        progressView.progress = progress
    }
}
