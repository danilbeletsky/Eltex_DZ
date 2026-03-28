import UIKit

final class ViewController: UIViewController {

    let containerView = UIView()
    let filterStack = UIStackView()
    let onlineSwitch = UISwitch()
    let runButton = UIButton(type: .system)
    let outputTextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupContainer()
        setupFilter()
        setupButton()
        setupOutput()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutUI()
    }
    
    func setupContainer() {
        containerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        view.addSubview(containerView)
    }
    
    func setupFilter() {
        filterStack.axis = .horizontal
        filterStack.spacing = 10
        filterStack.distribution = .equalSpacing
        
        let label = UILabel()
        label.text = "Онлайн торговля"
        
        filterStack.addArrangedSubview(label)
        filterStack.addArrangedSubview(onlineSwitch)
        
        containerView.addSubview(filterStack)
    }
    
    
    func setupButton() {
        runButton.setTitle("RUN", for: .normal)
        runButton.backgroundColor = .systemGreen
        runButton.setTitleColor(.black, for: .normal)
        runButton.layer.cornerRadius = 12
        
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        
        containerView.addSubview(runButton)
    }
    
    func setupOutput() {
        outputTextView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        outputTextView.font = UIFont.systemFont(ofSize: 16)
        outputTextView.isEditable = false
        
        view.addSubview(outputTextView)
    }
    
    func layoutUI() {
        let safe = view.safeAreaInsets
        
        containerView.frame = CGRect(
            x: 20,
            y: safe.top + 20,
            width: view.frame.width - 40,
            height: view.frame.height * 0.25
        )
        
        filterStack.frame = CGRect(
            x: 10,
            y: 20,
            width: containerView.frame.width - 20,
            height: 40
        )
        
        runButton.frame = CGRect(
            x: 20,
            y: 100,
            width: containerView.frame.width - 40,
            height: 50
        )
        
        outputTextView.frame = CGRect(
            x: 20,
            y: containerView.frame.maxY + 20,
            width: view.frame.width - 40,
            height: view.frame.height - containerView.frame.maxY - 40
        )
    }
    
    @objc func runTapped() {
        outputTextView.text = ""
        
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
