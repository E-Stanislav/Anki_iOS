import UIKit
import SnapKit

final class CardStudyViewController: UIViewController {
    private let viewModel: CardStudyViewModel
    private var isShowingFront = true

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var flashcardView: FlashcardView = {
        let view = FlashcardView()
        view.onTap = { [weak self] in
            self?.flipCard()
        }
        return view
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap card to reveal answer"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var buttonStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = AppConstants.Spacing.sm
        sv.isHidden = true
        return sv
    }()

    private lazy var againButton: UIButton = {
        createAnswerButton(title: "Again", color: .errorColor)
    }()

    private lazy var hardButton: UIButton = {
        createAnswerButton(title: "Hard", color: .warningColor)
    }()

    private lazy var goodButton: UIButton = {
        createAnswerButton(title: "Good", color: .primary)
    }()

    private lazy var easyButton: UIButton = {
        createAnswerButton(title: "Easy", color: .secondary)
    }()

    private lazy var completionView: StudyCompletionView = {
        let view = StudyCompletionView()
        view.isHidden = true
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

        view.addSubview(progressLabel)
        view.addSubview(flashcardView)
        view.addSubview(instructionLabel)
        view.addSubview(buttonStackView)
        view.addSubview(completionView)

        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(AppConstants.Spacing.md)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.md)
        }

        flashcardView.snp.makeConstraints { make in
            make.top.equalTo(progressLabel.snp.bottom).offset(AppConstants.Spacing.lg)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.lg)
            make.height.greaterThanOrEqualTo(300)
        }

        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(flashcardView.snp.bottom).offset(AppConstants.Spacing.md)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.md)
        }

        buttonStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.lg)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(AppConstants.Spacing.lg)
            make.height.equalTo(50)
        }

        completionView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.xl)
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

    private func createAnswerButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = color
        button.layer.cornerRadius = AppConstants.CornerRadius.medium
        return button
    }

    private func loadNextCard() {
        if let card = viewModel.nextCard() {
            isShowingFront = true
            flashcardView.configure(front: card.front, back: card.back)
            instructionLabel.text = "Tap card to reveal answer"
            buttonStackView.isHidden = true
            updateProgress()
        } else {
            showCompletion()
        }
    }

    private func flipCard() {
        if isShowingFront {
            flashcardView.showBack()
            instructionLabel.text = "How well did you remember?"
            buttonStackView.isHidden = false
        } else {
            flashcardView.showFront()
            instructionLabel.text = "Tap card to reveal answer"
            buttonStackView.isHidden = true
        }
        isShowingFront.toggle()
    }

    @objc private func againTapped() {
        viewModel.answerCard(quality: 0)
        transitionToNextCard()
    }

    @objc private func hardTapped() {
        viewModel.answerCard(quality: 1)
        transitionToNextCard()
    }

    @objc private func goodTapped() {
        viewModel.answerCard(quality: 2)
        transitionToNextCard()
    }

    @objc private func easyTapped() {
        viewModel.answerCard(quality: 3)
        transitionToNextCard()
    }

    private func transitionToNextCard() {
        UIView.animate(withDuration: AppConstants.Animation.medium, animations: {
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
        instructionLabel.isHidden = true
        buttonStackView.isHidden = true
        completionView.isHidden = false
        completionView.configure(cardsStudied: viewModel.cardsStudied, accuracy: viewModel.accuracy)
    }
}
