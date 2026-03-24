import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Components
    private let runButton = UIButton()
    private let stackRun = UIStackView()
    private let stackOnline = UIStackView()
    private let labelOnlineTrading = UILabel()
    private let swicherInlineTrading = UISwitch()
    private let tableView = UITableView()
    
    // MARK: - Data
    private var trades: [Trade] = []
    private var greetingText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showEmptyState()
    }
    
    // MARK: - Actions
    @objc private func run() {
        var bot = Bot()
        let newName = bot.makeName()
        bot.name = newName
        
        greetingText = bot.sendGreeting()
        
        let money = Money(balance: 20000)
        let newTrades = money.startTrading()
        trades = newTrades
        
        tableView.reloadData()
        
        if !trades.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    // MARK: - Private Methods
    private func showEmptyState() {
        trades = []
        greetingText = ""
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TextChatMessageCell.identifier, for: indexPath) as? TextChatMessageCell else {
            return UITableViewCell()
        }
        
        if indexPath.section == 0 {
            let textCell = UITableViewCell(style: .default, reuseIdentifier: nil)
            textCell.textLabel?.text = greetingText
            textCell.textLabel?.numberOfLines = 0
            textCell.textLabel?.font = .systemFont(ofSize: 16)
            textCell.textLabel?.textAlignment = .center
            textCell.backgroundColor = .lightGray.withAlphaComponent(0.3)
            return textCell
        } else {
            let trade = trades[indexPath.row]
            cell.configure(with: trade)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        } else {
            let trade = trades[indexPath.row]
            return trade.type == .ignore ? 70 : 110
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
private extension ViewController {
    
    func setupUI() {
        setupViews()
        setupTableView()
        addSubviews()
        makeConstraints()
        setupButton()
        setupLabelOnlineTrading()
    }
    
    func setupViews() {
        view.backgroundColor = .white
        
        runButton.translatesAutoresizingMaskIntoConstraints = false
        stackRun.translatesAutoresizingMaskIntoConstraints = false
        stackOnline.translatesAutoresizingMaskIntoConstraints = false
        labelOnlineTrading.translatesAutoresizingMaskIntoConstraints = false
        swicherInlineTrading.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        stackRun.axis = .vertical
        stackRun.backgroundColor = .gray
        stackRun.layer.cornerRadius = 14
        
        stackOnline.axis = .horizontal
        stackOnline.distribution = .fill
        stackOnline.alignment = .center
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
        stackRun.addSubview(runButton)
        stackRun.addSubview(stackOnline)
        stackOnline.addSubview(labelOnlineTrading)
        stackOnline.addSubview(swicherInlineTrading)
        view.addSubview(tableView)
    }
    
    func makeConstraints() {
        NSLayoutConstraint.activate([
            //MARK: Stack Run
            stackRun.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackRun.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackRun.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stackRun.heightAnchor.constraint(equalToConstant: 200),
            
            //MARK: Run Button
            runButton.topAnchor.constraint(equalTo: stackRun.topAnchor, constant: 126),
            runButton.leadingAnchor.constraint(equalTo: stackRun.leadingAnchor, constant: 20),
            runButton.trailingAnchor.constraint(equalTo: stackRun.trailingAnchor, constant: -20),
            runButton.bottomAnchor.constraint(equalTo: stackRun.bottomAnchor, constant: -26),
            
            //MARK: Stack Online
            stackOnline.topAnchor.constraint(equalTo: stackRun.topAnchor, constant: 16),
            stackOnline.leadingAnchor.constraint(equalTo: stackRun.leadingAnchor, constant: 6),
            stackOnline.trailingAnchor.constraint(equalTo: stackRun.trailingAnchor, constant: -6),
            stackOnline.bottomAnchor.constraint(equalTo: stackRun.bottomAnchor, constant: -96),
            
            //MARK: Label Online Trading
            labelOnlineTrading.leadingAnchor.constraint(equalTo: stackOnline.leadingAnchor, constant: 8),
            labelOnlineTrading.topAnchor.constraint(equalTo: stackOnline.topAnchor, constant: 18),
            
            //MARK: Switch
            swicherInlineTrading.trailingAnchor.constraint(equalTo: stackOnline.trailingAnchor, constant: -8),
            swicherInlineTrading.topAnchor.constraint(equalTo: stackOnline.topAnchor, constant: 18),
            
            //MARK: Table View
            tableView.topAnchor.constraint(equalTo: stackRun.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func setupButton() {
        runButton.setTitle("RUN", for: .normal)
        runButton.setTitleColor(.black, for: .normal)
        runButton.backgroundColor = .green
        runButton.layer.cornerRadius = 12
        runButton.addTarget(self, action: #selector(run), for: .touchUpInside)
    }
    
    func setupLabelOnlineTrading() {
        labelOnlineTrading.text = "Online Trading"
        labelOnlineTrading.textColor = .black
        labelOnlineTrading.font = .systemFont(ofSize: 20, weight: .bold)
    }
}
