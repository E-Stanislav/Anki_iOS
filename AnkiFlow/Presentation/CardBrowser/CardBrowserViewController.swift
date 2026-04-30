import UIKit
import SnapKit

final class CardBrowserViewController: UIViewController {
    private let viewModel: CardBrowserViewModel
    private let deck: Deck

    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search cards..."
        sb.searchBarStyle = .minimal
        sb.delegate = self
        return sb
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.register(CardBrowserCell.self, forCellReuseIdentifier: CardBrowserCell.identifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 80
        tv.separatorInset = UIEdgeInsets(top: 0, left: AppConstants.Spacing.md, bottom: 0, right: 0)
        return tv
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No cards found"
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    init(deck: Deck) {
        self.deck = deck
        self.viewModel = CardBrowserViewModel(deck: deck)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        updateEmptyState()
    }

    private func setupNavigationBar() {
        title = deck.name
        navigationItem.largeTitleDisplayMode = .never
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !viewModel.cards.isEmpty
        tableView.isHidden = viewModel.cards.isEmpty
    }
}

extension CardBrowserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CardBrowserCell.identifier, for: indexPath) as? CardBrowserCell else {
            return UITableViewCell()
        }
        let card = viewModel.cards[indexPath.row]
        cell.configure(front: card.front, back: card.back)
        return cell
    }
}

extension CardBrowserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let card = viewModel.cards[indexPath.row]
        showCardDetail(card)
    }

    private func showCardDetail(_ card: Card) {
        let alert = UIAlertController(title: "Front", message: card.front, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Show Back", style: .default) { [weak self] _ in
            let backAlert = UIAlertController(title: "Back", message: card.back, preferredStyle: .alert)
            backAlert.addAction(UIAlertAction(title: "Close", style: .cancel))
            self?.present(backAlert, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let card = viewModel.cards[indexPath.row]

        let suspendAction = UIContextualAction(style: .normal, title: "Suspend") { [weak self] _, _, completion in
            self?.viewModel.toggleSuspension(cardId: card.id)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        suspendAction.backgroundColor = .warningColor

        return UISwipeActionsConfiguration(actions: [suspendAction])
    }
}

extension CardBrowserViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(query: searchText)
        tableView.reloadData()
        updateEmptyState()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
