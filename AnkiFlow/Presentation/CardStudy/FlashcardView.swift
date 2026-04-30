import UIKit
import SnapKit

final class FlashcardView: UIView {
    var onTap: (() -> Void)?

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = AppConstants.CornerRadius.extraLarge
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 16
        view.layer.shadowOpacity = 0.15
        return view
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let sideIndicator: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private var frontText = ""
    private var backText = ""
    private var isShowingFront = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(contentLabel)
        containerView.addSubview(sideIndicator)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        sideIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.Spacing.md)
            make.centerX.equalToSuperview()
        }

        contentLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.lg)
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() {
        onTap?()
    }

    func configure(front: String, back: String) {
        frontText = front
        backText = back
        isShowingFront = true
        contentLabel.text = front
        sideIndicator.text = "FRONT"
    }

    func showBack() {
        guard !isShowingFront else { return }
        isShowingFront = false

        UIView.transition(with: containerView, duration: AppConstants.Animation.long, options: [.transitionFlipFromRight, .curveEaseInOut]) {
            self.contentLabel.text = self.backText
            self.sideIndicator.text = "BACK"
        }
    }

    func showFront() {
        guard isShowingFront else { return }
        isShowingFront = true

        UIView.transition(with: containerView, duration: AppConstants.Animation.long, options: [.transitionFlipFromLeft, .curveEaseInOut]) {
            self.contentLabel.text = self.frontText
            self.sideIndicator.text = "FRONT"
        }
    }
}

final class StudyCompletionView: UIView {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = .secondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "All Done!"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(statsLabel)

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(AppConstants.Spacing.lg)
            make.leading.trailing.equalToSuperview()
        }

        statsLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.md)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(cardsStudied: Int, accuracy: Int) {
        statsLabel.text = "You studied \(cardsStudied) cards with \(accuracy)% accuracy"
    }
}
