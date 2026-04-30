import UIKit
import SnapKit

protocol NewCardDelegate: AnyObject {
    func didCreateCard(_ card: Card)
}

final class NewCardViewController: UIViewController {
    weak var delegate: NewCardDelegate?

    private let deck: Deck

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private lazy var contentView = UIView()

    private lazy var frontLabel: UILabel = {
        let label = UILabel()
        label.text = "Front (Question)"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var frontTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 17)
        tv.textColor = .label
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        tv.delegate = self
        return tv
    }()

    private lazy var backLabel: UILabel = {
        let label = UILabel()
        label.text = "Back (Answer)"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var backTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 17)
        tv.textColor = .label
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        tv.delegate = self
        return tv
    }()

    private lazy var tagsLabel: UILabel = {
        let label = UILabel()
        label.text = "Tags (optional)"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var tagsTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 17)
        tf.textColor = .label
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        tf.placeholder = "e.g., vocabulary, chapter1"
        return tf
    }()

    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Save Card"
        config.image = UIImage(systemName: "checkmark.circle.fill")
        config.imagePadding = 8
        config.baseBackgroundColor = .primary
        config.baseForegroundColor = .white
        config.cornerStyle = .large

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()

    private lazy var addAnotherButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Save & Add Another"
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 8
        config.baseBackgroundColor = .primary
        config.baseForegroundColor = .primary
        config.cornerStyle = .large

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(addAnotherTapped), for: .touchUpInside)
        return button
    }()

    init(deck: Deck) {
        self.deck = deck
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        setupKeyboard()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(frontLabel)
        contentView.addSubview(frontTextView)
        contentView.addSubview(backLabel)
        contentView.addSubview(backTextView)
        contentView.addSubview(tagsLabel)
        contentView.addSubview(tagsTextField)
        contentView.addSubview(saveButton)
        contentView.addSubview(addAnotherButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        frontLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        frontTextView.snp.makeConstraints { make in
            make.top.equalTo(frontLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(120)
        }

        backLabel.snp.makeConstraints { make in
            make.top.equalTo(frontTextView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        backTextView.snp.makeConstraints { make in
            make.top.equalTo(backLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(120)
        }

        tagsLabel.snp.makeConstraints { make in
            make.top.equalTo(backTextView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        tagsTextField.snp.makeConstraints { make in
            make.top.equalTo(tagsLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(50)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(tagsTextField.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(56)
        }

        addAnotherButton.snp.makeConstraints { make in
            make.top.equalTo(saveButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(56)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    private func setupNavigation() {
        title = "New Card"
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let card = createCard() else {
            showError("Please enter both front and back text")
            return
        }
        delegate?.didCreateCard(card)
        dismiss(animated: true)
    }

    @objc private func addAnotherTapped() {
        guard let card = createCard() else {
            showError("Please enter both front and back text")
            return
        }
        delegate?.didCreateCard(card)
        clearForm()
        showSuccess("Card added!")
    }

    private func createCard() -> Card? {
        let front = frontTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let back = backTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !front.isEmpty, !back.isEmpty else { return nil }

        return Card(
            deckId: deck.id,
            front: front,
            back: back,
            tags: tagsTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )
    }

    private func clearForm() {
        frontTextView.text = ""
        backTextView.text = ""
        tagsTextField.text = ""
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension NewCardViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        animateBorder(textView, color: .primary)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        animateBorder(textView, color: .clear)
    }

    private func animateBorder(_ textView: UITextView, color: UIColor) {
        UIView.animate(withDuration: 0.2) {
            textView.layer.borderColor = color.cgColor
            textView.layer.borderWidth = color == .clear ? 0 : 2
        }
    }
}
