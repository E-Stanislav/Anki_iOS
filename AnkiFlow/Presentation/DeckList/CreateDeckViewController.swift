import UIKit
import SnapKit

protocol CreateDeckDelegate: AnyObject {
    func didCreateDeck(_ deck: Deck)
}

final class CreateDeckViewController: UIViewController {
    weak var delegate: CreateDeckDelegate?

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private lazy var contentView = UIView()

    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Create New Deck"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        return label
    }()

    private lazy var deckNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Deck Name"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var deckNameTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 17)
        tf.textColor = .label
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        tf.placeholder = "My Vocabulary"
        tf.delegate = self
        return tf
    }()

    private lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose Icon"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var emojiStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fillEqually
        return sv
    }()

    private let emojis = ["📚", "🎓", "📖", "🧠", "💡", "🔤", "🌍", "📝", "🎯", "⚡", "🎨", "🎵"]
    private var selectedEmoji = "📚"

    private lazy var cardsLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Cards (Optional)"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var cardsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var frontLabel: UILabel = {
        let label = UILabel()
        label.text = "Front"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .textSecondary
        return label
    }()

    private lazy var frontTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 15)
        tf.textColor = .label
        tf.backgroundColor = .tertiarySystemBackground
        tf.layer.cornerRadius = 8
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.placeholder = "Question or term"
        return tf
    }()

    private lazy var backLabel: UILabel = {
        let label = UILabel()
        label.text = "Back"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .textSecondary
        return label
    }()

    private lazy var backTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 15)
        tf.textColor = .label
        tf.backgroundColor = .tertiarySystemBackground
        tf.layer.cornerRadius = 8
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.placeholder = "Answer or definition"
        return tf
    }()

    private lazy var addCardButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Add Card"
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 6
        config.baseBackgroundColor = .primary
        config.baseForegroundColor = .primary
        config.cornerStyle = .medium

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(addCardTapped), for: .touchUpInside)
        return button
    }()

    private lazy var addedCardsLabel: UILabel = {
        let label = UILabel()
        label.text = "Added cards: 0"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .textSecondary
        return label
    }()

    private lazy var createButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Create Deck"
        config.image = UIImage(systemName: "checkmark.circle.fill")
        config.imagePadding = 8
        config.baseBackgroundColor = .primary
        config.baseForegroundColor = .white
        config.cornerStyle = .large

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return button
    }()

    private var addedCards: [(front: String, back: String)] = []
    private var deckRepository = DeckRepository.shared
    private var cardRepository = CardRepository.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        setupKeyboard()
        setupEmojis()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerLabel)
        contentView.addSubview(deckNameLabel)
        contentView.addSubview(deckNameTextField)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(emojiStackView)
        contentView.addSubview(cardsLabel)
        contentView.addSubview(cardsContainerView)
        contentView.addSubview(createButton)

        cardsContainerView.addSubview(frontLabel)
        cardsContainerView.addSubview(frontTextField)
        cardsContainerView.addSubview(backLabel)
        cardsContainerView.addSubview(backTextField)
        cardsContainerView.addSubview(addCardButton)
        cardsContainerView.addSubview(addedCardsLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        deckNameLabel.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        deckNameTextField.snp.makeConstraints { make in
            make.top.equalTo(deckNameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(50)
        }

        emojiLabel.snp.makeConstraints { make in
            make.top.equalTo(deckNameTextField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        emojiStackView.snp.makeConstraints { make in
            make.top.equalTo(emojiLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }

        cardsLabel.snp.makeConstraints { make in
            make.top.equalTo(emojiStackView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        cardsContainerView.snp.makeConstraints { make in
            make.top.equalTo(cardsLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        frontLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        frontTextField.snp.makeConstraints { make in
            make.top.equalTo(frontLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }

        backLabel.snp.makeConstraints { make in
            make.top.equalTo(frontTextField.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
        }

        backTextField.snp.makeConstraints { make in
            make.top.equalTo(backLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }

        addCardButton.snp.makeConstraints { make in
            make.top.equalTo(backTextField.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }

        addedCardsLabel.snp.makeConstraints { make in
            make.centerY.equalTo(addCardButton)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }

        createButton.snp.makeConstraints { make in
            make.top.equalTo(cardsContainerView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(56)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    private func setupNavigation() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    private func setupKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupEmojis() {
        for emoji in emojis {
            let button = UIButton(type: .system)
            button.setTitle(emoji, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 24)
            button.backgroundColor = emoji == selectedEmoji ? UIColor.primary.withAlphaComponent(0.2) : .clear
            button.layer.cornerRadius = 8
            button.addTarget(self, action: #selector(emojiTapped(_:)), for: .touchUpInside)
            emojiStackView.addArrangedSubview(button)
        }
    }

    @objc private func emojiTapped(_ sender: UIButton) {
        guard let emoji = sender.title(for: .normal) else { return }
        selectedEmoji = emoji

        for case let button as UIButton in emojiStackView.arrangedSubviews {
            button.backgroundColor = button.title(for: .normal) == emoji ? UIColor.primary.withAlphaComponent(0.2) : .clear
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func addCardTapped() {
        let front = frontTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let back = backTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !front.isEmpty, !back.isEmpty else {
            showError("Please enter both front and back text")
            return
        }

        addedCards.append((front: front, back: back))
        addedCardsLabel.text = "Added cards: \(addedCards.count)"
        frontTextField.text = ""
        backTextField.text = ""
        frontTextField.becomeFirstResponder()
    }

    @objc private func createTapped() {
        let name = deckNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !name.isEmpty else {
            showError("Please enter a deck name")
            return
        }

        let deck = Deck(name: name)
        guard deckRepository.insertDeck(deck) else {
            showError("Failed to create deck")
            return
        }

        for cardData in addedCards {
            let card = Card(deckId: deck.id, front: cardData.front, back: cardData.back)
            _ = cardRepository.insertCard(card)
        }

        delegate?.didCreateDeck(deck)
        dismiss(animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension CreateDeckViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == deckNameTextField {
            frontTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
