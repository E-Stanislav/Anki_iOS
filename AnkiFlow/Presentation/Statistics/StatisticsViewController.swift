import UIKit
import SnapKit

final class StatisticsViewController: UIViewController {
    private let viewModel = StatisticsViewModel()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private lazy var contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = AppConstants.Spacing.lg
        return sv
    }()

    private lazy var todayCard: StatCard = {
        let card = StatCard()
        card.configure(title: "Today", value: "0", icon: UIImage(systemName: "calendar"), color: .primary)
        return card
    }()

    private lazy var streakCard: StatCard = {
        let card = StatCard()
        card.configure(title: "Current Streak", value: "0 days", icon: UIImage(systemName: "flame.fill"), color: .warningColor)
        return card
    }()

    private lazy var retentionCard: StatCard = {
        let card = StatCard()
        card.configure(title: "Retention Rate", value: "0%", icon: UIImage(systemName: "brain.head.profile"), color: .secondary)
        return card
    }()

    private lazy var totalCardsCard: StatCard = {
        let card = StatCard()
        card.configure(title: "Total Cards", value: "0", icon: UIImage(systemName: "rectangle.stack.fill"), color: .primary)
        return card
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshStats()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(AppConstants.Spacing.md)
            make.width.equalTo(scrollView).offset(-AppConstants.Spacing.md * 2)
        }

        let topRow = UIStackView(arrangedSubviews: [todayCard, streakCard])
        topRow.axis = .horizontal
        topRow.spacing = AppConstants.Spacing.md
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView(arrangedSubviews: [retentionCard, totalCardsCard])
        bottomRow.axis = .horizontal
        bottomRow.spacing = AppConstants.Spacing.md
        bottomRow.distribution = .fillEqually

        contentStack.addArrangedSubview(topRow)
        contentStack.addArrangedSubview(bottomRow)
    }

    private func setupNavigationBar() {
        title = "Statistics"
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    private func refreshStats() {
        viewModel.loadStats()
        todayCard.configure(title: "Today", value: "\(viewModel.todayStudied)", icon: UIImage(systemName: "calendar"), color: .primary)
        streakCard.configure(title: "Current Streak", value: "\(viewModel.currentStreak) days", icon: UIImage(systemName: "flame.fill"), color: .warningColor)
        retentionCard.configure(title: "Retention Rate", value: "\(viewModel.retentionRate)%", icon: UIImage(systemName: "brain.head.profile"), color: .secondary)
        totalCardsCard.configure(title: "Total Cards", value: "\(viewModel.totalCards)", icon: UIImage(systemName: "rectangle.stack.fill"), color: .primary)
    }
}

final class StatCard: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = AppConstants.CornerRadius.large
        return view
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .textSecondary
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
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
        addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(AppConstants.Spacing.md)
            make.width.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(AppConstants.Spacing.sm)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.md)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.xs)
            make.leading.trailing.bottom.equalToSuperview().inset(AppConstants.Spacing.md)
        }
    }

    func configure(title: String, value: String, icon: UIImage?, color: UIColor) {
        titleLabel.text = title
        valueLabel.text = value
        iconView.image = icon
        iconView.tintColor = color
    }
}
