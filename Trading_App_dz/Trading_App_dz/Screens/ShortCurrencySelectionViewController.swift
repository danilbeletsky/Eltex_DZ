import UIKit

final class ShortCurrencySelectionViewController: UIViewController {
    
    weak var delegate: CurrencySelectionViewControllerDelegate?
    var currentPair: CurrencyPair = CurrencyPair(from: "USD", to: "BTC")
    
    private let titleLabel = UILabel()
    private let pairLabel = UILabel()
    private let allButton = UIButton(type: .system)
    private var collectionView: UICollectionView!
    
    private let currencyObj = CurrencySelectionViewController()
    
    private var popularCurrencies = ["USD", "BTC"]
    private var isEditingFirstCurrency = true
    private var fixedPopularCurrencies: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        makeConstraint()
        updatePairLabel()
        generateFixedPopularCurrencies()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        titleLabel.text = "Популярные валюты"
        titleLabel.font = .boldSystemFont(ofSize: 22)
        
        pairLabel.font = .systemFont(ofSize: 20, weight: .medium)
        pairLabel.textAlignment = .center
        pairLabel.backgroundColor = .secondarySystemBackground
        pairLabel.layer.cornerRadius = 12
        pairLabel.clipsToBounds = true
        pairLabel.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleEditingCurrency))
        pairLabel.addGestureRecognizer(tap)
        
        allButton.setTitle("Все", for: .normal)
        allButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        allButton.addTarget(self, action: #selector(openFullList), for: .touchUpInside)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(MyCell.self, forCellWithReuseIdentifier: MyCell.identifire)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        [titleLabel, pairLabel, allButton, collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    private func makeConstraint() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            pairLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            pairLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pairLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pairLabel.heightAnchor.constraint(equalToConstant: 60),
            
            allButton.topAnchor.constraint(equalTo: pairLabel.bottomAnchor, constant: 16),
            allButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            allButton.heightAnchor.constraint(equalToConstant: 44),
            
            collectionView.topAnchor.constraint(equalTo: allButton.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updatePairLabel() {
        pairLabel.text = isEditingFirstCurrency
            ? "Выбираешь первую: \(currentPair.from) - \(currentPair.to)"
            : "Выбираешь вторую: \(currentPair.from) - \(currentPair.to)"
    }
    
    private func generateFixedPopularCurrencies() {
        // Создаем копию всех доступных валют
        var allCurrencies = currencyObj.items
        
        // Начинаем с текущей пары валют
        var newPopularCurrencies: [String] = []
        
        // Добавляем текущие валюты из пары, если их нет в списке
        if !newPopularCurrencies.contains(currentPair.from) {
            newPopularCurrencies.append(currentPair.from)
        }
        if !newPopularCurrencies.contains(currentPair.to) && currentPair.to != currentPair.from {
            newPopularCurrencies.append(currentPair.to)
        }
        
        for currency in newPopularCurrencies {
            if let index = allCurrencies.firstIndex(of: currency) {
                allCurrencies.remove(at: index)
            }
        }
        
        while newPopularCurrencies.count < 10 && !allCurrencies.isEmpty {
            if let randomCurrency = allCurrencies.randomElement() {
                if !newPopularCurrencies.contains(randomCurrency) {
                    newPopularCurrencies.append(randomCurrency)
                    if let index = allCurrencies.firstIndex(of: randomCurrency) {
                        allCurrencies.remove(at: index)
                    }
                }
            }
        }
        
        fixedPopularCurrencies = newPopularCurrencies
        popularCurrencies = fixedPopularCurrencies
        collectionView.reloadData()
    }
    
    @objc private func toggleEditingCurrency() {
        isEditingFirstCurrency.toggle()
        updatePairLabel()
    }
    
    @objc private func openFullList() {
        guard let delegate = self.delegate else { return }
        
        let fullVC = CurrencySelectionViewController()
        fullVC.delegate = delegate
        fullVC.currentPair = self.currentPair
        
        if let nav = self.presentingViewController?.navigationController {
            self.dismiss(animated: true) {
                nav.pushViewController(fullVC, animated: true)
            }
        } else {
            self.present(fullVC, animated: true)
        }
    }
}

extension ShortCurrencySelectionViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        popularCurrencies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MyCell.identifire,
            for: indexPath
        ) as? MyCell else {
            return UICollectionViewCell()
        }
        
        let currency = popularCurrencies[indexPath.item]
        cell.configure(with: currency, isFavorite: false)
        cell.delegate = nil
        cell.layer.cornerRadius = 12
        
        if currency == currentPair.from || currency == currentPair.to {
            cell.backgroundColor = .systemGreen
        } else {
            cell.backgroundColor = .systemGray
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCurrency = popularCurrencies[indexPath.item]
        
        if isEditingFirstCurrency {
            guard selectedCurrency != currentPair.to else { return }
            currentPair.from = selectedCurrency
        } else {
            guard selectedCurrency != currentPair.from else { return }
            currentPair.to = selectedCurrency
        }
        
        delegate?.currencySelectionViewController(
            CurrencySelectionViewController(),
            didUpdatePair: currentPair
        )
        
        updatePairLabel()
    
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (collectionView.frame.width - 12) / 2, height: 70)
    }
}
