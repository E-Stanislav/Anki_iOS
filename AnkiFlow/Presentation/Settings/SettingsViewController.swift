import UIKit
import SnapKit

final class SettingsViewController: UIViewController {
    private let viewModel = SettingsViewModel()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.register(SettingsStepperCell.self, forCellReuseIdentifier: SettingsStepperCell.identifier)
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupNavigationBar() {
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Study Settings"
        case 1: return "About"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsStepperCell.identifier, for: indexPath) as? SettingsStepperCell else {
                return UITableViewCell()
            }
            if indexPath.row == 0 {
                cell.configure(title: "New Cards/Day", value: viewModel.newCardsPerDay, min: 1, max: 100)
                cell.onValueChanged = { [weak self] value in
                    self?.viewModel.setNewCardsPerDay(Int(value))
                }
            } else {
                cell.configure(title: "Max Reviews/Day", value: viewModel.maxReviewsPerDay, min: 10, max: 500)
                cell.onValueChanged = { [weak self] value in
                    self?.viewModel.setMaxReviewsPerDay(Int(value))
                }
            }
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = "Version"
            cell.detailTextLabel?.text = "1.0.0"
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell

        default:
            return UITableViewCell()
        }
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

final class SettingsStepperCell: UITableViewCell {
    static let identifier = "SettingsStepperCell"

    var onValueChanged: ((Double) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .textSecondary
        return label
    }()

    private lazy var stepper: UIStepper = {
        let s = UIStepper()
        s.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        return s
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(stepper)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Spacing.md)
            make.centerY.equalToSuperview()
        }

        stepper.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-AppConstants.Spacing.md)
            make.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(stepper.snp.leading).offset(-AppConstants.Spacing.sm)
            make.centerY.equalToSuperview()
        }
    }

    func configure(title: String, value: Int, min: Int, max: Int) {
        titleLabel.text = title
        valueLabel.text = "\(value)"
        stepper.value = Double(value)
        stepper.minimumValue = Double(min)
        stepper.maximumValue = Double(max)
    }

    @objc private func stepperChanged() {
        let value = Int(stepper.value)
        valueLabel.text = "\(value)"
        onValueChanged?(stepper.value)
    }
}
