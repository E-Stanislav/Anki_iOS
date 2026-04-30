import UIKit
import SnapKit

final class CardBrowserCell: UITableViewCell {
    static let identifier = "CardBrowserCell"

    private let frontLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let backLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .textSecondary
        label.numberOfLines = 1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(frontLabel)
        contentView.addSubview(backLabel)

        frontLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppConstants.Spacing.sm)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.md)
        }

        backLabel.snp.makeConstraints { make in
            make.top.equalTo(frontLabel.snp.bottom).offset(AppConstants.Spacing.xs)
            make.leading.trailing.equalToSuperview().inset(AppConstants.Spacing.md)
            make.bottom.equalToSuperview().offset(-AppConstants.Spacing.sm)
        }
    }

    func configure(front: String, back: String) {
        frontLabel.text = front
        backLabel.text = back
    }
}
