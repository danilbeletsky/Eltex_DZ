import UIKit

final class P2PExchangeViewController: UIViewController {
<<<<<<< HEAD
    private let pairContainerView = UIView()
    private let pairTitleLabel = UILabel()
    private let fromCurrencyLabel = UILabel()
    private let separatorLabel = UILabel()
    private let toCurrencyLabel = UILabel()

    private let balancesLabel = UILabel()
    private let statusLabel = UILabel()
    private let tableView = UITableView()

    private let viewModel: P2PExchangeViewModel
    private weak var coordinator: P2PCoordinator?
    private var offers: [P2POffer] = []

    init(viewModel: P2PExchangeViewModel, coordinator: P2PCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
=======
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
>>>>>>> parent of a886af4 (delete_dz_14)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
<<<<<<< HEAD
        setupNavigationBar()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    @objc private func openWalletScreen() {
        coordinator?.showWallet(wallet: viewModel.wallet)
    }

    @objc private func openCurrencySelection() {
        coordinator?.showCurrencySelection(
            currentPair: viewModel.state.currentPair,
            apiCurrencies: viewModel.state.apiCurrencies,
            delegate: self
        )
    }

    private func render(state: P2PExchangeViewModel.State) {
        offers = state.offers
        fromCurrencyLabel.text = state.currentPair.from
        toCurrencyLabel.text = state.currentPair.to
        statusLabel.text = state.statusText
        statusLabel.textColor = state.statusIsError ? .systemRed : .systemGreen
        balancesLabel.text = String(
            format: "Баланс %@: %.4f | %@: %.4f",
            state.currentPair.from,
            state.fromBalance,
            state.currentPair.to,
            state.toBalance
        )
        tableView.reloadData()
    }

    private func bindViewModel() {
        viewModel.onStateUpdated = { [weak self] state in
            self?.render(state: state)
        }
        viewModel.onError = { [weak self] error in
            self?.presentErrorAlert(error: error)
        }
        viewModel.onExchangeSuccess = { [weak self] in
            let success = UIAlertController(
                title: "Успех",
                message: "Обмен успешно выполнен.",
                preferredStyle: .alert
            )
            success.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(success, animated: true)
        }
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
            self.viewModel.executeExchange(offer: offer, amount: amount)
        }))
        present(alert, animated: true)
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
        case .timeout:
            iconName = "clock.badge.exclamationmark"
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
        let offer = offers[indexPath.row]
        let sheet = UIAlertController(title: offer.sellerName, message: "Выберите действие", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Обмен", style: .default) { [weak self] _ in
            self?.presentExchangePrompt(for: offer)
        })
        sheet.addAction(UIAlertAction(title: "Информация о продавце", style: .default) { [weak self] _ in
            self?.coordinator?.showSellerInfo(offer: offer)
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: indexPath)
        }
        present(sheet, animated: true)
=======
        updateBalances()
        loadOffers()
>>>>>>> parent of a886af4 (delete_dz_14)
    }
}

private extension P2PExchangeViewController {
    func setupUI() {
        view.backgroundColor = .systemBackground
<<<<<<< HEAD

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
=======
        title = "P2P обмен"

>>>>>>> parent of a886af4 (delete_dz_14)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "wallet.pass"),
            style: .plain,
            target: self,
<<<<<<< HEAD
            action: #selector(openWalletScreen)
        )
=======
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
>>>>>>> parent of a886af4 (delete_dz_14)
    }
}

extension P2PExchangeViewController: CurrencySelectionViewControllerDelegate {
    func currencySelectionViewController(
        _ controller: CurrencySelectionViewController,
        didUpdatePair pair: CurrencyPair
    ) {
<<<<<<< HEAD
        viewModel.selectPair(pair)
=======
        currentPair = pair
        dismiss(animated: true)
        loadOffers()
>>>>>>> parent of a886af4 (delete_dz_14)
    }
}
