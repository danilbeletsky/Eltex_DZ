import UIKit

final class WalletViewController: UIViewController {
    private let wallet: Wallet
    private let textView = UITextView()

    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderWalletState()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Кошелек"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeSelf)
        )

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 12

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func renderWalletState() {
        let balances = wallet.snapshot().sorted { $0.key < $1.key }
        let credits = wallet.creditSnapshot()

        var lines: [String] = ["Текущие балансы:\n"]
        for (currency, amount) in balances {
            let debt = credits[currency, default: 0]
            if debt > 0 {
                lines.append("\(currency): \(String(format: "%.2f", amount)) (credit: \(String(format: "%.2f", debt)))")
            } else {
                lines.append("\(currency): \(String(format: "%.2f", amount))")
            }
        }

        textView.text = lines.joined(separator: "\n")
    }

    @objc private func closeSelf() {
        dismiss(animated: true)
    }
}
