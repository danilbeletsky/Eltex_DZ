import UIKit

final class P2PExchangeViewController: UIViewController {
    private let wallet: Wallet
    private let networkService: NetworkService

    private var currentPair = CurrencyPair(from: "USD", to: "BTC")
    private var offers: [P2POffer] = []
    private var apiCurrencies: [String] = []

    private let pairButton = UIButton(type: .system)
    private let balanceLabel = UILabel()
    private let statusLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loader = UIActivityIndicatorView(style: .medium)

    init(wallet: Wallet, networkService: NetworkService = NetworkService()) {
        self.wallet = wallet
        self.networkService = networkService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateBalances()
        loadOffers()
    }
}

private extension P2PExchangeViewController {
    func setupUI() {
        view.backgroundColor = .systemBackground
        title = "P2P обмен"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "wallet.pass"),
            style: .plain,
            target: self,
            action: #selector(openWallet)
        )

        pairButton.translatesAutoresizingMaskIntoConstraints = false
        pairButton.setTitleColor(.label, for: .normal)
        pairButton.backgroundColor = .secondarySystemBackground
        pairButton.layer.cornerRadius = 10
        pairButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        pairButton.addTarget(self, action: #selector(openPairSelection), for: .touchUpInside)

        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.numberOfLines = 0
        balanceLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        balanceLabel.backgroundColor = .secondarySystemBackground
        balanceLabel.layer.cornerRadius = 10
        balanceLabel.clipsToBounds = true

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(P2POfferCell.self, forCellReuseIdentifier: P2POfferCell.reuseId)

        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.hidesWhenStopped = true

        [pairButton, balanceLabel, statusLabel, tableView, loader].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            pairButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            pairButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pairButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pairButton.heightAnchor.constraint(equalToConstant: 52),

            balanceLabel.topAnchor.constraint(equalTo: pairButton.bottomAnchor, constant: 12),
            balanceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            balanceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loader.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }

    func updateHeader() {
        pairButton.setTitle("Пара: \(currentPair.from) -> \(currentPair.to)", for: .normal)
        updateBalances()
    }

    func updateBalances() {
        let fromBalance = wallet.balance(for: currentPair.from)
        let toBalance = wallet.balance(for: currentPair.to)
        balanceLabel.text = String(
            format: "Баланс %@: %.2f\nБаланс %@: %.2f",
            currentPair.from,
            fromBalance,
            currentPair.to,
            toBalance
        )
    }

    func loadOffers() {
        updateHeader()
        loader.startAnimating()
        statusLabel.text = "Загрузка предложений..."

        networkService.fetchRates(baseCurrency: currentPair.from) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loader.stopAnimating()

                switch result {
                case .success(let rates):
                    let currencies = Array(rates.keys) + [self.currentPair.from]
                    self.apiCurrencies = Array(Set(currencies)).sorted()
                    if rates[self.currentPair.to] == nil, let first = rates.keys.sorted().first {
                        self.currentPair.to = first
                    }
                    self.offers = self.networkService.makeOffers(for: self.currentPair, rates: rates)
                    self.statusLabel.text = "Найдено предложений: \(self.offers.count)"
                    self.updateHeader()
                    self.tableView.reloadData()

                case .failure(let error):
                    self.offers = []
                    self.statusLabel.text = error.userMessage
                    self.tableView.reloadData()
                    self.showMessage(title: "Ошибка", message: error.userMessage)
                }
            }
        }
    }

    @objc func openWallet() {
        let walletVC = WalletViewController(wallet: wallet)
        let nav = UINavigationController(rootViewController: walletVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    @objc func openPairSelection() {
        let vc = ShortCurrencySelectionViewController()
        vc.currentPair = currentPair
        vc.delegate = self
        vc.apiCurrencies = apiCurrencies
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }

    func askAmountAndExchange(with offer: P2POffer) {
        let alert = UIAlertController(
            title: offer.sellerName,
            message: "Введите сумму в \(offer.pair.from)",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Сумма"
            textField.keyboardType = .decimalPad
        }

        let execute = UIAlertAction(title: "Выполнить", style: .default) { [weak self] _ in
            guard let self else { return }
            guard
                let text = alert.textFields?.first?.text,
                let amount = Double(text),
                amount > 0
            else {
                self.showMessage(title: "Ошибка", message: "Введите корректную сумму")
                return
            }

            self.networkService.performExchange(offer: offer, amount: amount, wallet: self.wallet) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.updateBalances()
                        self.showMessage(title: "Успех", message: "Обмен выполнен")
                    case .failure(let error):
                        self.showMessage(title: "Ошибка", message: error.userMessage)
                    }
                }
            }
        }

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(execute)
        present(alert, animated: true)
    }

    func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension P2PExchangeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        offers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: P2POfferCell.reuseId,
            for: indexPath
        ) as? P2POfferCell else {
            return UITableViewCell()
        }
        cell.configure(with: offers[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        askAmountAndExchange(with: offers[indexPath.row])
    }
}

extension P2PExchangeViewController: CurrencySelectionViewControllerDelegate {
    func currencySelectionViewController(
        _ controller: CurrencySelectionViewController,
        didUpdatePair pair: CurrencyPair
    ) {
        currentPair = pair
        dismiss(animated: true)
        loadOffers()
    }
}
