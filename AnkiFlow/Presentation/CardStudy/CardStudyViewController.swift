import UIKit
import SnapKit

final class CardStudyViewController: UIViewController {
    private let viewModel: CardStudyViewModel
    private var isShowingFront = true

    private lazy var progressContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .primary
        label.textAlignment = .center
        return label
    }()

    private lazy var flashcardView: FlashcardView = {
        let view = FlashcardView()
        view.onTap = { [weak self] in
            self?.flipCard()
        }
        view.onSwipeUp = { [weak self] in
            self?.flipCard()
        }
        return view
    }()

    private lazy var buttonStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 12
        sv.alpha = 0
        sv.transform = CGAffineTransform(translationX: 0, y: 20)
        return sv
    }()

    private lazy var againButton = createAnswerButton(title: "Again", color: .errorColor, icon: "xmark")
    private lazy var hardButton = createAnswerButton(title: "Hard", color: .warningColor, icon: "minus")
    private lazy var goodButton = createAnswerButton(title: "Good", color: .primary, icon: "checkmark")
    private lazy var easyButton = createAnswerButton(title: "Easy", color: .secondary, icon: "checkmark.circle")

    private lazy var completionView: StudyCompletionView = {
        let view = StudyCompletionView()
        view.isHidden = true
        view.alpha = 0
        return view
    }()

    init(deck: Deck) {
        self.viewModel = CardStudyViewModel(deck: deck)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupButtons()
        loadNextCard()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = viewModel.deckName
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(progressContainer)
        progressContainer.addSubview(progressLabel)
        view.addSubview(flashcardView)
        view.addSubview(buttonStackView)
        view.addSubview(completionView)

        progressContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
        }

        progressLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
        }

        flashcardView.snp.makeConstraints { make in
            make.top.equalTo(progressContainer.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.greaterThanOrEqualTo(340)
        }

        buttonStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.height.equalTo(56)
        }

        completionView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
    }

    private func setupButtons() {
        buttonStackView.addArrangedSubview(againButton)
        buttonStackView.addArrangedSubview(hardButton)
        buttonStackView.addArrangedSubview(goodButton)
        buttonStackView.addArrangedSubview(easyButton)

        againButton.addTarget(self, action: #selector(againTapped), for: .touchUpInside)
        hardButton.addTarget(self, action: #selector(hardTapped), for: .touchUpInside)
        goodButton.addTarget(self, action: #selector(goodTapped), for: .touchUpInside)
        easyButton.addTarget(self, action: #selector(easyTapped), for: .touchUpInside)
    }

    private func createAnswerButton(title: String, color: UIColor, icon: String) -> UIButton {
        let button = UIButton(type: .system)

        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 6
        config.imagePlacement = .leading
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.cornerStyle = .large

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold)
        ]
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer(attributes))

        button.configuration = config
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.3

        return button
    }

    private func loadNextCard() {
        if let card = viewModel.nextCard() {
            isShowingFront = true
            flashcardView.configure(front: card.front, back: card.back)
            buttonStackView.isHidden = true
            buttonStackView.alpha = 0
            buttonStackView.transform = CGAffineTransform(translationX: 0, y: 20)
            updateProgress()
        } else {
            showCompletion()
        }
    }

    private func flipCard() {
        if isShowingFront {
            flashcardView.showBack()
            showAnswerButtons()
        } else {
            flashcardView.showFront()
            hideAnswerButtons()
        }
        isShowingFront.toggle()
    }

    private func showAnswerButtons() {
        buttonStackView.isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.buttonStackView.alpha = 1
            self.buttonStackView.transform = .identity
        }
    }

    private func hideAnswerButtons() {
        UIView.animate(withDuration: 0.2) {
            self.buttonStackView.alpha = 0
            self.buttonStackView.transform = CGAffineTransform(translationX: 0, y: 20)
        } completion: { _ in
            self.buttonStackView.isHidden = true
        }
    }

    @objc private func againTapped() {
        animateButton(againButton)
        viewModel.answerCard(quality: 0)
        transitionToNextCard()
    }

    @objc private func hardTapped() {
        animateButton(hardButton)
        viewModel.answerCard(quality: 1)
        transitionToNextCard()
    }

    @objc private func goodTapped() {
        animateButton(goodButton)
        viewModel.answerCard(quality: 2)
        transitionToNextCard()
    }

    @objc private func easyTapped() {
        animateButton(easyButton)
        viewModel.answerCard(quality: 3)
        transitionToNextCard()
    }

    private func animateButton(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }

    private func transitionToNextCard() {
        hideAnswerButtons()

        UIView.animate(withDuration: 0.3, animations: {
            self.flashcardView.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
            self.flashcardView.alpha = 0
        }) { _ in
            self.flashcardView.transform = .identity
            self.flashcardView.alpha = 1
            self.loadNextCard()
        }
    }

    private func updateProgress() {
        progressLabel.text = viewModel.progressText
    }

    private func showCompletion() {
        flashcardView.isHidden = true
        buttonStackView.isHidden = true
        completionView.isHidden = false

        completionView.configure(cardsStudied: viewModel.cardsStudied, accuracy: viewModel.accuracy)

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.completionView.alpha = 1
            self.completionView.transform = .identity
        }
    }
}
