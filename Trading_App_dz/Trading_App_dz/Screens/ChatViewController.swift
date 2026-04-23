import UIKit

final class ChatViewController: UIViewController {
    
    // MARK: - UI Components
    private let runButton = UIButton()
    private let chartCandlesButton = UIButton()
    private let chartGrafButton = UIButton()
    private let stackRun = UIStackView()
    private let tableView = UITableView()
    
    private let pairContainerView = UIView()
    private let pairTitleLabel = UILabel()
    private let fromCurrencyLabel = UILabel()
    private let separatorLabel = UILabel()
    private let toCurrencyLabel = UILabel()
    
    private var currentPair = CurrencyPair(from: "USD", to: "BTC")
    private let defaultPair = CurrencyPair(from: "USD", to: "BTC")
    
    // MARK: - Data
    private var trades: [Trade] = []
    private var greetingText: String = ""
    private let wallet: Wallet
    
    private let allCurrencies = [
        "USD", "BTC", "ETH", "EUR", "RUB", "USDT", "GBP", "JPY", "CNY", "AED"
    ]

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
        setupNavigationBar()
        setupSwipeToOpenChart()
        updatePairUI()
        showEmptyState()
    }
    
    // MARK: - Actions
    @objc private func run() {
        runButton.isEnabled = false
        runButton.alpha = 0.6
        greetingText = "Запускаю ботов в параллельных потоках..."
        tableView.reloadData()

        let bots = makeBots()
        BotRunner.run(bots: bots, wallet: wallet) { [weak self] generatedTrades in
            DispatchQueue.main.async {
                guard let self else { return }
                self.trades = generatedTrades
                self.greetingText = "Выполнено: \(bots.count) ботов, \(TradingConfig.workDays) дней."
                self.tableView.reloadData()
                self.runButton.isEnabled = true
                self.runButton.alpha = 1.0

                if !self.trades.isEmpty {
                    self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
            }
        }
    }
    
    @objc private func resetTradingScreen() {
        currentPair = defaultPair
        updatePairUI()
        showEmptyState()
    }
    
    @objc private func randomizePair() {
        guard allCurrencies.count >= 2 else { return }
        
        let from = allCurrencies.randomElement() ?? "USD"
        var to = allCurrencies.randomElement() ?? "BTC"
        
        while from == to {
            to = allCurrencies.randomElement() ?? "BTC"
        }
        
        currentPair = CurrencyPair(from: from, to: to)
        updatePairUI()
        showEmptyState()
    }

    @objc private func openChartsScreenCandles() {
        let chartsViewController = ChartsViewController()
        chartsViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chartsViewController, animated: true)
    }
    
    @objc private func openChartsScreenGraf() {
        let chartsGrafViewController = ChartsGrafViewController()
        chartsGrafViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chartsGrafViewController, animated: true)
    }

    @objc private func openWalletScreen() {
        let walletVC = WalletViewController(wallet: wallet)
        let nav = UINavigationController(rootViewController: walletVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
    
    // MARK: - Private Methods
    private func showEmptyState() {
        trades = []
        greetingText = ""
        tableView.reloadData()
    }

    private func makeBots() -> [TradingBot] {
        let selectedPairBots: [TradingBot] = [
            TradingBot(name: "Bot\(currentPair.from)\(currentPair.to)Alpha", pair: currentPair),
            TradingBot(name: "Bot\(currentPair.from)\(currentPair.to)Delta", pair: currentPair),
            TradingBot(name: "Bot\(currentPair.from)\(currentPair.to)Sigma", pair: currentPair)
        ]

        let supportPair = CurrencyPair(from: "RUB", to: "ETH")
        let supportPairBots: [TradingBot] = [
            TradingBot(name: "BotRUBETHCore", pair: supportPair),
            TradingBot(name: "BotRUBETHFlow", pair: supportPair)
        ]

        return selectedPairBots + supportPairBots
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return greetingText.isEmpty ? 0 : 1
        case 1:
            return trades.isEmpty ? 0 : trades.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let textCell = UITableViewCell(style: .default, reuseIdentifier: nil)
            textCell.textLabel?.text = greetingText
            textCell.textLabel?.numberOfLines = 0
            textCell.textLabel?.font = .systemFont(ofSize: 16)
            textCell.textLabel?.textAlignment = .center
            textCell.backgroundColor = .lightGray.withAlphaComponent(0.3)
            return textCell
        } else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TextChatMessageCell.identifier,
                for: indexPath
            ) as? TextChatMessageCell else {
                return UITableViewCell()
            }
            
            let trade = trades[indexPath.row]
            cell.configure(with: trade)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension ChatViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        } else {
            let trade = trades[indexPath.row]
            return trade.additionalInfo == nil ? 70 : 110
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return greetingText.isEmpty ? nil : "Приветствие"
        case 1:
            return trades.isEmpty ? nil : "История сделок"
        default:
            return nil
        }
    }
}

// MARK: - UI Setup
private extension ChatViewController {
    
    func setupUI() {
        setupViews()
        setupTableView()
        setupPairView()
        addSubviews()
        makeConstraints()
        setupButton()
    }
    
    func setupViews() {
        view.backgroundColor = .white
        
        runButton.translatesAutoresizingMaskIntoConstraints = false
        chartCandlesButton.translatesAutoresizingMaskIntoConstraints = false
        chartGrafButton.translatesAutoresizingMaskIntoConstraints = false
        stackRun.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        stackRun.axis = .vertical
        stackRun.backgroundColor = .gray
        stackRun.layer.cornerRadius = 14
    }
    
    func setupNavigationBar() {
        navigationItem.title = "Торговля"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(resetTradingScreen)
        )
        
        let randomButton = UIBarButtonItem(
            image: UIImage(systemName: "shuffle"),
            style: .plain,
            target: self,
            action: #selector(randomizePair)
        )

        let walletButton = UIBarButtonItem(
            image: UIImage(systemName: "wallet.pass"),
            style: .plain,
            target: self,
            action: #selector(openWalletScreen)
        )

        let chartButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            style: .plain,
            target: self,
            action: #selector(openChartsScreenCandles)
        )
        navigationItem.rightBarButtonItems = [walletButton, randomButton, chartButtonItem]
    }
    
    private func setupPairView() {
        pairContainerView.translatesAutoresizingMaskIntoConstraints = false
        pairTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        fromCurrencyLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorLabel.translatesAutoresizingMaskIntoConstraints = false
        toCurrencyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        pairContainerView.backgroundColor = .white
        pairContainerView.layer.cornerRadius = 12
        pairContainerView.layer.borderWidth = 1
        pairContainerView.layer.borderColor = UIColor.lightGray.cgColor
        pairContainerView.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(openCurrencySelection))
        pairContainerView.addGestureRecognizer(tap)
        
        pairTitleLabel.text = "Текущая пара"
        pairTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        pairTitleLabel.textColor = .darkGray
        
        fromCurrencyLabel.font = .systemFont(ofSize: 24, weight: .bold)
        separatorLabel.text = "-"
        separatorLabel.font = .systemFont(ofSize: 24, weight: .bold)
        toCurrencyLabel.font = .systemFont(ofSize: 24, weight: .bold)
    }
    
    func setupTableView() {
        tableView.register(TextChatMessageCell.self, forCellReuseIdentifier: TextChatMessageCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.showsVerticalScrollIndicator = true
    }
    
    func addSubviews() {
        view.addSubview(stackRun)
        view.addSubview(tableView)
        
        stackRun.addSubview(runButton)
        stackRun.addSubview(pairContainerView)
        stackRun.addSubview(chartCandlesButton)
        stackRun.addSubview(chartGrafButton)
        
        pairContainerView.addSubview(pairTitleLabel)
        pairContainerView.addSubview(fromCurrencyLabel)
        pairContainerView.addSubview(separatorLabel)
        pairContainerView.addSubview(toCurrencyLabel)
    }
    
    func makeConstraints() {
        NSLayoutConstraint.activate([
            stackRun.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackRun.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackRun.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackRun.heightAnchor.constraint(equalToConstant: 350),
            
            runButton.topAnchor.constraint(equalTo: stackRun.topAnchor, constant: 12),
            runButton.leadingAnchor.constraint(equalTo: stackRun.leadingAnchor, constant: 20),
            runButton.trailingAnchor.constraint(equalTo: stackRun.trailingAnchor, constant: -20),
            runButton.heightAnchor.constraint(equalToConstant: 50),
            
            tableView.topAnchor.constraint(equalTo: stackRun.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            pairContainerView.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 30),
            pairContainerView.leadingAnchor.constraint(equalTo: stackRun.leadingAnchor, constant: 16),
            pairContainerView.trailingAnchor.constraint(equalTo: stackRun.trailingAnchor, constant: -16),
            pairContainerView.heightAnchor.constraint(equalToConstant: 80),

            chartCandlesButton.topAnchor.constraint(equalTo: pairContainerView.bottomAnchor, constant: 20),
            chartCandlesButton.leadingAnchor.constraint(equalTo: stackRun.leadingAnchor, constant: 20),
            chartCandlesButton.trailingAnchor.constraint(equalTo: stackRun.trailingAnchor, constant: -20),
            chartCandlesButton.heightAnchor.constraint(equalToConstant: 50),
            
            chartGrafButton.topAnchor.constraint(equalTo: chartCandlesButton.bottomAnchor, constant: 20),
            chartGrafButton.leadingAnchor.constraint(equalTo: stackRun.leadingAnchor, constant: 20),
            chartGrafButton.trailingAnchor.constraint(equalTo: stackRun.trailingAnchor, constant: -20),
            chartGrafButton.heightAnchor.constraint(equalToConstant: 50),

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
    
    func setupButton() {
        runButton.setTitle("RUN", for: .normal)
        runButton.setTitleColor(.black, for: .normal)
        runButton.backgroundColor = .green
        runButton.layer.cornerRadius = 12
        runButton.addTarget(self, action: #selector(run), for: .touchUpInside)

        chartCandlesButton.setTitle("Свечи", for: .normal)
        chartCandlesButton.setTitleColor(.white, for: .normal)
        chartCandlesButton.backgroundColor = .systemBlue
        chartCandlesButton.layer.cornerRadius = 12
        chartCandlesButton.addTarget(self, action: #selector(openChartsScreenCandles), for: .touchUpInside)
        
        chartGrafButton.setTitle("График", for: .normal)
        chartGrafButton.setTitleColor(.white, for: .normal)
        chartGrafButton.backgroundColor = .systemBlue
        chartGrafButton.layer.cornerRadius = 12
        chartGrafButton.addTarget(self, action: #selector(openChartsScreenGraf), for: .touchUpInside)
    }
    
    func updatePairUI() {
        fromCurrencyLabel.text = currentPair.from
        toCurrencyLabel.text = currentPair.to
    }
    
    @objc func openCurrencySelection() {
        let vc = ShortCurrencySelectionViewController()
        vc.delegate = self
        vc.currentPair = currentPair
        vc.modalPresentationStyle = .pageSheet
        
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    func setupSwipeToOpenChart() {
        [view, stackRun, tableView].forEach { targetView in
            let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(openChartsScreenCandles))
            swipeUpGesture.direction = .up
            swipeUpGesture.cancelsTouchesInView = false
            targetView.addGestureRecognizer(swipeUpGesture)
        }
    }
    
    func setupSwipeToOpenChartGraf() {
        [view, stackRun, tableView].forEach { targetView in
            let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(openChartsScreenGraf))
            swipeUpGesture.direction = .up
            swipeUpGesture.cancelsTouchesInView = false
            targetView.addGestureRecognizer(swipeUpGesture)
        }
    }
}

extension ChatViewController: CurrencySelectionViewControllerDelegate {
    func currencySelectionViewController(
        _ controller: CurrencySelectionViewController,
        didUpdatePair pair: CurrencyPair
    ) {
        currentPair = pair
        updatePairUI()
        showEmptyState()
    }
}
