import UIKit

final class P2PExchangeViewController: UIViewController {
    private let pairContainerView = UIView()
    private let pairTitleLabel = UILabel()
    private let fromCurrencyLabel = UILabel()
    private let separatorLabel = UILabel()
    private let toCurrencyLabel = UILabel()

    private let balancesLabel = UILabel()
    private let statusLabel = UILabel()
    private let tableView = UITableView()

    private var currentPair = CurrencyPair(from: "USD", to: "BTC")
    private let networkService = NetworkService()
    private let wallet = Wallet(
        initialBalances: [
            "USD": 20_000,
            "BTC": 1.4,
            "EUR": 12_000,
            "USDT": 30_000,
            "ETH": 22
        ]
    )
    private var offers: [P2POffer] = []
    private var apiCurrencies: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        updatePairUI()
        updateBalances()
        loadApiCurrencies()
        loadOffers()
    }

    @objc private func openWalletScreen() {
        let walletVC = WalletViewController(wallet: wallet)
        let nav = UINavigationController(rootViewController: walletVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    @objc private func openCurrencySelection() {
        let vc = CurrencySelectionViewController()
        vc.delegate = self
        vc.currentPair = currentPair
        vc.apiCurrencies = apiCurrencies
        navigationController?.pushViewController(vc, animated: true)
    }

    private func loadApiCurrencies() {
        networkService.loadCurrencies { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                if case .success(let currencies) = result {
                    self.apiCurrencies = currencies
                }
            }
        }
    }

    private func loadOffers() {
        statusLabel.textColor = .secondaryLabel
        statusLabel.text = "Загрузка предложений..."

        networkService.loadOffers(for: currentPair) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let offers):
                    self.offers = offers
                    self.statusLabel.textColor = .systemGreen
                    self.statusLabel.text = "Найдено продавцов: \(offers.count)"
                case .failure(let error):
                    self.offers = []
                    self.statusLabel.textColor = .systemRed
                    self.statusLabel.text = error.userMessage
                    self.presentErrorAlert(error: error)
                }
                self.tableView.reloadData()
            }
        }
    }

    private func updatePairUI() {
        fromCurrencyLabel.text = currentPair.from
        toCurrencyLabel.text = currentPair.to
    }

    private func updateBalances() {
        let fromBalance = wallet.balance(for: currentPair.from)
        let toBalance = wallet.balance(for: currentPair.to)
        balancesLabel.text = String(
            format: "Баланс %@: %.4f | %@: %.4f",
            currentPair.from,
            fromBalance,
            currentPair.to,
            toBalance
        )
    }

    private func presentExchangePrompt(for offer: P2POffer) {
        let alert = UIAlertController(
            title: "Обмен через \(offer.sellerName)",
            message: String(format: "Курс: 1 %@ = %.6f %@", offer.pair.from, offer.rate, offer.pair.to),
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Введите сумму в \(offer.pair.from)"
            textField.keyboardType = .decimalPad
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выполнить", style: .default, handler: { [weak self, weak alert] _ in
            guard let self,
                  let rawAmount = alert?.textFields?.first?.text,
                  let amount = Double(rawAmount),
                  amount > 0 else {
                return
            }
            self.executeExchange(offer: offer, amount: amount)
        }))
        present(alert, animated: true)
    }

    private func executeExchange(offer: P2POffer, amount: Double) {
        networkService.performExchange(offer: offer, amount: amount, wallet: wallet) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.updateBalances()
                    self.loadOffers()
                    let success = UIAlertController(
                        title: "Успех",
                        message: "Обмен успешно выполнен.",
                        preferredStyle: .alert
                    )
                    success.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(success, animated: true)
                case .failure(let error):
                    self.presentErrorAlert(error: error)
                }
            }
        }
    }

    private func presentErrorAlert(error: NetworkServiceError) {
        let alert = UIAlertController(
            title: "Операция не удалась",
            message: error.userMessage,
            preferredStyle: .alert
        )
        let iconName: String
        switch error {
        case .noInternet:
            iconName = "wifi.slash"
        case .parsing:
            iconName = "exclamationmark.triangle"
        case .forbiddenSection:
            iconName = "lock.shield"
        case .server, .unknown:
            iconName = "xmark.circle"
        }
        alert.setValue(UIImage(systemName: iconName), forKey: "image")
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension P2PExchangeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        offers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "P2PCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "P2PCell")
        let offer = offers[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.textLabel?.text = "\(offer.sellerName) | \(offer.pair.from)/\(offer.pair.to)"
        cell.detailTextLabel?.text = String(
            format: "Курс: %.6f | Резерв: %.2f %@",
            offer.rate,
            offer.reserve,
            offer.pair.to
        )
        return cell
    }
}

extension P2PExchangeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentExchangePrompt(for: offers[indexPath.row])
    }
}

private extension P2PExchangeViewController {
    func setupUI() {
        view.backgroundColor = .systemBackground

        pairContainerView.translatesAutoresizingMaskIntoConstraints = false
        pairTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        fromCurrencyLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorLabel.translatesAutoresizingMaskIntoConstraints = false
        toCurrencyLabel.translatesAutoresizingMaskIntoConstraints = false
        balancesLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        pairContainerView.backgroundColor = .secondarySystemBackground
        pairContainerView.layer.cornerRadius = 12
        pairContainerView.layer.borderWidth = 1
        pairContainerView.layer.borderColor = UIColor.separator.cgColor
        pairContainerView.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(openCurrencySelection))
        pairContainerView.addGestureRecognizer(tap)

        pairTitleLabel.text = "Активная пара (нажмите для изменения)"
        pairTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        pairTitleLabel.textColor = .secondaryLabel

        fromCurrencyLabel.font = .systemFont(ofSize: 24, weight: .bold)
        toCurrencyLabel.font = .systemFont(ofSize: 24, weight: .bold)
        separatorLabel.text = "-"
        separatorLabel.font = .systemFont(ofSize: 24, weight: .bold)

        balancesLabel.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        balancesLabel.textColor = .label
        balancesLabel.numberOfLines = 2

        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textAlignment = .left

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.backgroundColor = .systemBackground

        view.addSubview(pairContainerView)
        view.addSubview(balancesLabel)
        view.addSubview(statusLabel)
        view.addSubview(tableView)

        pairContainerView.addSubview(pairTitleLabel)
        pairContainerView.addSubview(fromCurrencyLabel)
        pairContainerView.addSubview(separatorLabel)
        pairContainerView.addSubview(toCurrencyLabel)

        NSLayoutConstraint.activate([
            pairContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            pairContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pairContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pairContainerView.heightAnchor.constraint(equalToConstant: 80),

            balancesLabel.topAnchor.constraint(equalTo: pairContainerView.bottomAnchor, constant: 10),
            balancesLabel.leadingAnchor.constraint(equalTo: pairContainerView.leadingAnchor),
            balancesLabel.trailingAnchor.constraint(equalTo: pairContainerView.trailingAnchor),

            statusLabel.topAnchor.constraint(equalTo: balancesLabel.bottomAnchor, constant: 6),
            statusLabel.leadingAnchor.constraint(equalTo: pairContainerView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: pairContainerView.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            pairTitleLabel.topAnchor.constraint(equalTo: pairContainerView.topAnchor, constant: 8),
            pairTitleLabel.leadingAnchor.constraint(equalTo: pairContainerView.leadingAnchor, constant: 12),

            fromCurrencyLabel.leadingAnchor.constraint(equalTo: pairContainerView.leadingAnchor, constant: 12),
            fromCurrencyLabel.bottomAnchor.constraint(equalTo: pairContainerView.bottomAnchor, constant: -10),

            separatorLabel.leadingAnchor.constraint(equalTo: fromCurrencyLabel.trailingAnchor, constant: 8),
            separatorLabel.centerYAnchor.constraint(equalTo: fromCurrencyLabel.centerYAnchor),

            toCurrencyLabel.leadingAnchor.constraint(equalTo: separatorLabel.trailingAnchor, constant: 8),
            toCurrencyLabel.centerYAnchor.constraint(equalTo: fromCurrencyLabel.centerYAnchor),
        ])
    }

    func setupNavigationBar() {
        navigationItem.title = "P2P Обмен"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "wallet.pass"),
            style: .plain,
            target: self,
            action: #selector(openWalletScreen)
        )
    }
}

extension P2PExchangeViewController: CurrencySelectionViewControllerDelegate {
    func currencySelectionViewController(
        _ controller: CurrencySelectionViewController,
        didUpdatePair pair: CurrencyPair
    ) {
        currentPair = pair
        updatePairUI()
        updateBalances()
        loadOffers()
    }
}
