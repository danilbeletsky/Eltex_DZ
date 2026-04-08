import UIKit

class ViewController: UIViewController {
    
    private let runButton = UIButton()
    private let stackRun = UIStackView()
    private let stackOnline = UIStackView()
    private let labelOnlineTrading = UILabel()
    private let swicherInlineTrading = UISwitch()
    private let stackChat = UIStackView()
    private let outputTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

private extension ViewController {
    func setupUI() {
        runButton.translatesAutoresizingMaskIntoConstraints = false
        stackRun.translatesAutoresizingMaskIntoConstraints = false
        stackOnline.translatesAutoresizingMaskIntoConstraints = false
        labelOnlineTrading.translatesAutoresizingMaskIntoConstraints = false
        swicherInlineTrading.translatesAutoresizingMaskIntoConstraints = false
        stackChat.translatesAutoresizingMaskIntoConstraints = false
        outputTextView.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = .white
        
        setupStackChatLog()
        setupStackRun()
        setupStackOnline()
        setupButton()
        setupLabelOnlineTrading()
        addSubviews()
        makeConstraints()
        setupOutput()
    }
    
    func addSubviews() {
        view.addSubview(stackRun)
        stackRun.addSubview(runButton)
        stackRun.addSubview(stackOnline)
        stackOnline.addSubview(labelOnlineTrading)
        stackOnline.addSubview(swicherInlineTrading)
        view.addSubview(stackChat)
        stackChat.addSubview(outputTextView)
    }
    
    func makeConstraints() {
        NSLayoutConstraint.activate([
            // Button Run
            NSLayoutConstraint(item: runButton, attribute: .leading, relatedBy: .equal, toItem: stackRun, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: runButton, attribute: .trailing, relatedBy: .equal, toItem: stackRun, attribute: .trailing, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: runButton, attribute: .top, relatedBy: .equal, toItem: stackRun, attribute: .top, multiplier: 1, constant: 126),
            NSLayoutConstraint(item: runButton, attribute: .bottom, relatedBy: .equal, toItem: stackRun, attribute: .bottom, multiplier: 1, constant: -26),
            
            // Stack Button
            NSLayoutConstraint(item: stackRun, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: stackRun, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -16),
            NSLayoutConstraint(item: stackRun, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: stackRun, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200),
            
            // Stack Online Trading
            NSLayoutConstraint(item: stackOnline, attribute: .leading, relatedBy: .equal, toItem: stackRun, attribute: .leading, multiplier: 1, constant: 6),
            NSLayoutConstraint(item: stackOnline, attribute: .trailing, relatedBy: .equal, toItem: stackRun, attribute: .trailing, multiplier: 1, constant: -6),
            NSLayoutConstraint(item: stackOnline, attribute: .top, relatedBy: .equal, toItem: stackRun, attribute: .top, multiplier: 1, constant: 16),
            NSLayoutConstraint(item: stackOnline, attribute: .bottom, relatedBy: .equal, toItem: stackRun, attribute: .bottom, multiplier: 1, constant: -96),
            
            // Label Online Trading
            NSLayoutConstraint(item: labelOnlineTrading, attribute: .leading, relatedBy: .equal, toItem: stackOnline, attribute: .leading, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: labelOnlineTrading, attribute: .top, relatedBy: .equal, toItem: stackOnline, attribute: .top, multiplier: 1, constant: 18),
            
            // Swicher Online Trading
            NSLayoutConstraint(item: swicherInlineTrading, attribute: .trailing, relatedBy: .equal, toItem: stackOnline, attribute: .trailing, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: swicherInlineTrading, attribute: .top, relatedBy: .equal, toItem: stackOnline, attribute: .top, multiplier: 1, constant: 18),
            
            // Stack Chat
            NSLayoutConstraint(item: stackChat, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 20),
            NSLayoutConstraint(item: stackChat, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: -20),
            NSLayoutConstraint(item: stackChat, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 250),
            NSLayoutConstraint(item: stackChat, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: -6),
            
            // Text Chat
            NSLayoutConstraint(item: outputTextView, attribute: .leading, relatedBy: .equal, toItem: stackChat, attribute: .leading, multiplier: 1, constant: 6),
            NSLayoutConstraint(item: outputTextView, attribute: .trailing, relatedBy: .equal, toItem: stackChat, attribute: .trailing, multiplier: 1, constant: -6),
            NSLayoutConstraint(item: outputTextView, attribute: .top, relatedBy: .equal, toItem: stackChat, attribute: .top, multiplier: 1, constant: 6),
            NSLayoutConstraint(item: outputTextView, attribute: .bottom, relatedBy: .equal, toItem: stackChat, attribute: .bottom, multiplier: 1, constant: -6),
        ])
    }
    
    func setupStackRun(){
        stackRun.axis = .vertical
        stackRun.backgroundColor = .gray
        stackRun.layer.cornerRadius = 14
    }
    
    func setupStackOnline() {
        stackOnline.axis = .horizontal
        stackOnline.distribution = .fill
        stackOnline.alignment = .center
    }
    
    func setupStackChatLog() {
        stackChat.axis = .vertical
        stackChat.backgroundColor = .gray
        stackChat.layer.cornerRadius = 14
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
    
    func setupOutput() {
        outputTextView.backgroundColor = .clear
        outputTextView.font = UIFont.systemFont(ofSize: 16)
        outputTextView.isEditable = false
        outputTextView.isScrollEnabled = true
        outputTextView.text = "Нет данных!"
        outputTextView.textAlignment = .center
        outputTextView.textContainerInset = .init(top: 240, left: 50, bottom: 50, right: 50)
    }
    
    @objc func run(){
        outputTextView.text = ""
        outputTextView.textAlignment = .left
        outputTextView.textContainerInset = .zero
        
        var bot = Bot()
        let newName = bot.makeName()
        bot.name = newName
        
        let greetingText = bot.sendGreeting()
        appendText(greetingText)
        
        let money = Money(balance: 20000)
        let tradingLogs = money.startTrading()
        
        for log in tradingLogs {
            appendText(log)
        }
    }
    
    private func appendText(_ text: String) {
        outputTextView.text += text + "\n"
        let range = NSRange(location: outputTextView.text.count - 1, length: 0)
        outputTextView.scrollRangeToVisible(range)
    }
}

