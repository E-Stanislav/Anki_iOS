import UIKit
import SnapKit

final class FlashcardView: UIView {
    var onTap: (() -> Void)?
    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?
    var onSwipeUp: (() -> Void)?

    private let cardContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.primary.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 24
        view.layer.shadowOpacity = 0.2
        view.layer.masksToBounds = false
        return view
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.primary.cgColor,
            UIColor.primaryDark.cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.cornerRadius = 24
        return layer
    }()

    private let innerWhiteView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private let sideIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.primary.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()

    private let sideIndicatorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .primary
        label.textAlignment = .center
        return label
    }()

    private let tapHintView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondary.withAlphaComponent(0.1)
        view.layer.cornerRadius = 16
        return view
    }()

    private let tapHintIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "hand.swipe.up.fill")
        iv.tintColor = .secondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let tapHintLabel: UILabel = {
        let label = UILabel()
        label.text = "Swipe up to reveal"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondary
        return label
    }()

    private var frontText = ""
    private var backText = ""
    private var isShowingFront = true

    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = cardContainer.bounds
    }

    private func setupUI() {
        addSubview(cardContainer)
        cardContainer.layer.addSublayer(gradientLayer)
        cardContainer.addSubview(innerWhiteView)
        innerWhiteView.addSubview(sideIndicatorView)
        sideIndicatorView.addSubview(sideIndicatorLabel)
        innerWhiteView.addSubview(contentLabel)
        innerWhiteView.addSubview(tapHintView)
        tapHintView.addSubview(tapHintIcon)
        tapHintView.addSubview(tapHintLabel)

        cardContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        innerWhiteView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }

        sideIndicatorView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }

        sideIndicatorLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12))
        }

        contentLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }

        tapHintView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
        }

        tapHintIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        tapHintLabel.snp.makeConstraints { make in
            make.leading.equalTo(tapHintIcon.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
    }

    @objc private func handleSwipeLeft() {
        guard !isAnimating else { return }
        animateSwipe(direction: .left)
        onSwipeLeft?()
    }

    @objc private func handleSwipeRight() {
        guard !isAnimating else { return }
        animateSwipe(direction: .right)
        onSwipeRight?()
    }

    @objc private func handleSwipeUp() {
        guard !isAnimating else { return }
        animateSwipe(direction: .up)
        onSwipeUp?()
    }

    private enum SwipeDirection {
        case left, right, up
    }

    private func animateSwipe(direction: SwipeDirection) {
        let translation: CGPoint
        switch direction {
        case .left: translation = CGPoint(x: -bounds.width, y: 0)
        case .right: translation = CGPoint(x: bounds.width, y: 0)
        case .up: translation = CGPoint(x: 0, y: -bounds.height)
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.cardContainer.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            self.cardContainer.alpha = 0
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.cardContainer.transform = .identity
                self.cardContainer.alpha = 1
            }
        }
    }

    @objc private func handleTap() {
        guard !isAnimating else { return }
        onTap?()
    }

    func configure(front: String, back: String) {
        frontText = front
        backText = back
        isShowingFront = true
        contentLabel.text = front
        sideIndicatorLabel.text = "QUESTION"
        sideIndicatorView.backgroundColor = UIColor.primary.withAlphaComponent(0.1)
        sideIndicatorLabel.textColor = .primary
        animateHintIn()
    }

    func showBack() {
        guard !isShowingFront, !isAnimating else { return }
        isAnimating = true
        isShowingFront = false

        animateFlip(to: backText, indicator: "ANSWER", color: .secondary)
    }

    func showFront() {
        guard isShowingFront, !isAnimating else { return }
        isAnimating = true
        isShowingFront = true

        animateFlip(to: frontText, indicator: "QUESTION", color: .primary)
    }

    private func animateFlip(to text: String, indicator: String, color: UIColor) {
        let transitionOptions: UIView.AnimationOptions = [
            .transitionFlipFromRight,
            .curveEaseInOut,
            .showHideTransitionViews
        ]

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
            self.cardContainer.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.cardContainer.alpha = 0.8
        } completion: { _ in
            UIView.transition(with: self.innerWhiteView, duration: 0.2, options: transitionOptions) {
                self.contentLabel.text = text
                self.sideIndicatorLabel.text = indicator
                self.sideIndicatorView.backgroundColor = color.withAlphaComponent(0.1)
                self.sideIndicatorLabel.textColor = color
                self.tapHintView.backgroundColor = color.withAlphaComponent(0.1)
                self.tapHintIcon.tintColor = color
                self.tapHintLabel.textColor = color
                self.tapHintLabel.text = "Swipe up to see question"
            }

            UIView.animate(withDuration: 0.15, delay: 0.1, options: .curveEaseOut) {
                self.cardContainer.transform = .identity
                self.cardContainer.alpha = 1.0
            } completion: { _ in
                self.isAnimating = false
            }
        }
    }

    private func animateHintIn() {
        tapHintView.alpha = 0
        tapHintView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(withDuration: 0.3, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.tapHintView.alpha = 1
            self.tapHintView.transform = .identity
        }
    }

    func hideHint() {
        UIView.animate(withDuration: 0.2) {
            self.tapHintView.alpha = 0
        }
    }
}

final class StudyCompletionView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.secondary.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 24
        view.layer.shadowOpacity = 0.2
        return view
    }()

    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondary.withAlphaComponent(0.1)
        view.layer.cornerRadius = 40
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = .secondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Great Job!"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Session Complete"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private let statsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 16
        return sv
    }()

    private let cardsStatView = StatItemView()
    private let accuracyStatView = StatItemView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(statsStackView)

        statsStackView.addArrangedSubview(cardsStatView)
        statsStackView.addArrangedSubview(accuracyStatView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(48)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        statsStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    func configure(cardsStudied: Int, accuracy: Int) {
        cardsStatView.configure(value: "\(cardsStudied)", label: "Cards")
        accuracyStatView.configure(value: "\(accuracy)%", label: "Accuracy")

        if accuracy >= 80 {
            iconImageView.image = UIImage(systemName: "star.fill")
            iconImageView.tintColor = .secondary
            iconContainer.backgroundColor = UIColor.secondary.withAlphaComponent(0.1)
            titleLabel.text = "Excellent!"
        } else if accuracy >= 60 {
            iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
            iconImageView.tintColor = .secondary
            iconContainer.backgroundColor = UIColor.secondary.withAlphaComponent(0.1)
            titleLabel.text = "Good Job!"
        } else {
            iconImageView.image = UIImage(systemName: "arrow.clockwise.circle.fill")
            iconImageView.tintColor = .warningColor
            iconContainer.backgroundColor = UIColor.warningColor.withAlphaComponent(0.1)
            titleLabel.text = "Keep Practicing!"
        }
    }
}

private final class StatItemView: UIView {
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .textSecondary
        label.textAlignment = .center
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
        addSubview(valueLabel)
        addSubview(titleLabel)

        valueLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(value: String, label: String) {
        valueLabel.text = value
        titleLabel.text = label
    }
}
