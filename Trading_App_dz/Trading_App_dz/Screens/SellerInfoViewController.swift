import UIKit

final class SellerInfoViewController: UIViewController {
    private let viewModel: SellerInfoViewModel
    private let subtitleLabel = UILabel()
    private let detailsLabel = UILabel()

    init(viewModel: SellerInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Продавец"
        view.backgroundColor = .systemBackground

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.text = viewModel.title

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.text = viewModel.subtitle

        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        detailsLabel.numberOfLines = 0
        detailsLabel.text = viewModel.details

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12

        view.addSubview(nameLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(container)
        container.addSubview(detailsLabel)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            container.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            detailsLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            detailsLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            detailsLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            detailsLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
    }
}
