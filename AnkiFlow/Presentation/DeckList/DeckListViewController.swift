import UIKit
import SnapKit

final class DeckListViewController: UIViewController {
    private let viewModel = DeckListViewModel()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = AppConstants.Spacing.md
        layout.minimumInteritemSpacing = AppConstants.Spacing.md
        layout.sectionInset = UIEdgeInsets(
            top: AppConstants.Spacing.md,
            left: AppConstants.Spacing.md,
            bottom: AppConstants.Spacing.md + 80,
            right: AppConstants.Spacing.md
        )

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(DeckCell.self, forCellWithReuseIdentifier: DeckCell.identifier)
        cv.refreshControl = refreshControl
        return cv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return rc
    }()

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.configure(
            icon: UIImage(systemName: "rectangle.stack.badge.plus"),
            title: "No Decks Yet",
            message: "Import an Anki deck to get started"
        )
        view.isHidden = true
        return view
    }()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .primary
        button.layer.cornerRadius = AppConstants.CornerRadius.circular
        button.layer.shadowColor = UIColor.primary.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.3
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadDecks()
        collectionView.reloadData()
        updateEmptyState()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(addButton)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.xl)
        }

        addButton.snp.makeConstraints { make in
            make.width.height.equalTo(56)
            make.trailing.equalToSuperview().inset(AppConstants.Spacing.lg)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(AppConstants.Spacing.lg)
        }
    }

    private func setupNavigationBar() {
        title = "Decks"
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApkgFile(_:)),
            name: .didReceiveApkgFile,
            object: nil
        )
    }

    @objc private func refreshData() {
        viewModel.loadDecks()
        collectionView.reloadData()
        refreshControl.endRefreshing()
        updateEmptyState()
    }

    @objc private func addButtonTapped() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    @objc private func handleApkgFile(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }
        importDeck(from: url)
    }

    private func importDeck(from url: URL) {
        let progressAlert = UIAlertController(title: "Importing...", message: "Please wait", preferredStyle: .alert)
        present(progressAlert, animated: true)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let useCase = ImportDeckUseCase()
            do {
                let deck = try useCase.execute(url: url) { progress in
                    DispatchQueue.main.async {
                        progressAlert.message = "Importing... \(Int(progress * 100))%"
                    }
                }

                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self?.viewModel.loadDecks()
                        self?.collectionView.reloadData()
                        self?.updateEmptyState()
                        self?.showSuccessAlert(deckName: deck.name)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    progressAlert.dismiss(animated: true) {
                        self?.showErrorAlert(message: "Failed to import deck. Please make sure the file is a valid Anki package.")
                    }
                }
            }
        }
    }

    private func showSuccessAlert(deckName: String) {
        let alert = UIAlertController(
            title: "Import Successful",
            message: "\"\(deckName)\" has been imported.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Import Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateEmptyState() {
        emptyStateView.isHidden = !viewModel.decks.isEmpty
        collectionView.isHidden = viewModel.decks.isEmpty
    }
}

extension DeckListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.decks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DeckCell.identifier, for: indexPath) as? DeckCell else {
            return UICollectionViewCell()
        }
        let deck = viewModel.decks[indexPath.item]
        let cardCount = viewModel.getCardCount(for: deck)
        let dueCount = viewModel.getDueCount(for: deck)
        cell.configure(deck: deck, cardCount: cardCount, dueCount: dueCount)
        return cell
    }
}

extension DeckListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let deck = viewModel.decks[indexPath.item]
        let dueCount = viewModel.getDueCount(for: deck)

        if dueCount > 0 {
            let studyVC = CardStudyViewController(deck: deck)
            navigationController?.pushViewController(studyVC, animated: true)
        } else {
            let browserVC = CardBrowserViewController(deck: deck)
            navigationController?.pushViewController(browserVC, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let deck = viewModel.decks[indexPath.item]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let browseAction = UIAction(title: "Browse Cards", image: UIImage(systemName: "list.bullet")) { [weak self] _ in
                let browserVC = CardBrowserViewController(deck: deck)
                self?.navigationController?.pushViewController(browserVC, animated: true)
            }

            let studyAction = UIAction(title: "Study Now", image: UIImage(systemName: "play.fill")) { [weak self] _ in
                let studyVC = CardStudyViewController(deck: deck)
                self?.navigationController?.pushViewController(studyVC, animated: true)
            }

            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.confirmDelete(deck: deck)
            }

            return UIMenu(children: [browseAction, studyAction, deleteAction])
        }
    }

    private func confirmDelete(deck: Deck) {
        let alert = UIAlertController(
            title: "Delete Deck",
            message: "Are you sure you want to delete \"\(deck.name)\"? This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteDeck(deck)
            self?.collectionView.reloadData()
            self?.updateEmptyState()
        })
        present(alert, animated: true)
    }
}

extension DeckListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = AppConstants.Spacing.md * 3
        let width = (collectionView.bounds.width - padding) / 2
        return CGSize(width: width, height: 160)
    }
}

extension DeckListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let tempDir = FileManager.default.temporaryDirectory
        let destURL = tempDir.appendingPathComponent(url.lastPathComponent)

        try? FileManager.default.removeItem(at: destURL)
        try? FileManager.default.copyItem(at: url, to: destURL)

        importDeck(from: destURL)
    }
}

final class EmptyStateView: UIView {
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .textSecondary
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
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
        addSubview(messageLabel)

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(64)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(AppConstants.Spacing.md)
            make.leading.trailing.equalToSuperview()
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.sm)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func configure(icon: UIImage?, title: String, message: String) {
        iconImageView.image = icon
        titleLabel.text = title
        messageLabel.text = message
    }
}
