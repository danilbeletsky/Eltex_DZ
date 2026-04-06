import UIKit

final class CurrencySelectionViewController: UIViewController {
    
    // MARK: UI Elements
    private let viewHeader = UIView()
    private let selectedCurrenciesLabelFirst = UILabel()
    private let selectedCurrenciesLabelSecond = UILabel()
    private let rateLabel = UILabel()
    private let amountTextField = UITextField()
    private let resultLabel = UILabel()
    private let timerLabel = UILabel()
    
    private let favoriteFilterView = FavoriteFilterView()
    private let filterSegmentedControl = UISegmentedControl(items: ["Все", "Фиат", "Крипта"])
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "В избранное ничего не добавлено"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Data
    private let items = ["USD", "BTS", "EUR", "RUB", "GBP", "JPY", "CNY", "BTC", "ETH", "USDT", "AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", "BTN", "BWP", "BYN", "BZD", "CAD", "CDF", "CHF", "CLP", "CNH", "COP", "CRC", "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "FJD", "FKP", "FOK", "GEL", "GGP", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS", "IMP", "INR", "IQD", "IRR", "ISK", "JEP", "JMD", "JOD", "KES", "KGS", "KHR", "KID", "KMF", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRU", "MUR", "MVR", "MWK", "MXN", "MYR", "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", "PYG", "QAR", "RON", "RSD", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLE", "SLL", "SOS", "SRD", "SSP", "STN", "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "UYU", "UZS", "VES", "VND", "VUV", "WST", "XAF", "XCD", "XDR", "XOF", "XPF", "YER", "ZAR", "ZMW", "ZWL"]
    
    private let fiatCurrencies: Set<String> = ["USD", "EUR", "RUB", "GBP", "JPY", "CNY", "AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", "BTN", "BWP", "BYN", "BZD", "CAD", "CDF", "CHF", "CLP", "CNH", "COP", "CRC", "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "FJD", "FKP", "FOK", "GEL", "GGP", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS", "IMP", "INR", "IQD", "IRR", "ISK", "JEP", "JMD", "JOD", "KES", "KGS", "KHR", "KID", "KMF", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRU", "MUR", "MVR", "MWK", "MXN", "MYR", "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", "PYG", "QAR", "RON", "RSD", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLE", "SLL", "SOS", "SRD", "SSP", "STN", "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "UYU", "UZS", "VES", "VND", "VUV", "WST", "XAF", "XCD", "XDR", "XOF", "XPF", "YER", "ZAR", "ZMW", "ZWL"]
    private let cryptoCurrencies: Set<String> = ["BTC", "ETH", "USDT", "BTS"]
    
    private var favoritesCurrencies: Set<String> = []
    private var labelCurrenciesHeaderChois: [UILabel] = []
    private var isEditingFirstCurrency = true
    private var currentRate: Double = 0.0
    private var timer: Timer?
    private var timeRemaining: Int = 5
    private var collectionView: UICollectionView!
    private var filteredItems: [String] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFavorites()
        filteredItems = items
        setupUI()
        startTimer()
        updateRate()
    }
    
    // MARK: - Setup
    func setupUI() {
        setupHeader()
        setupFavoriteFilter()
        setupCollectionView()
        setuorateLabel()
        setupFilter()
        setupConversionUI()
        addSubviews()
        makeConstraints()
        setupTextField()
    }
    
    func setupFavoriteFilter() {
        favoriteFilterView.delegate = self
    }
    
    func setupFilter() {
        filterSegmentedControl.selectedSegmentIndex = 0
        filterSegmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
    }
    // MARK: Setuup Conversion
    func setupConversionUI() {
        amountTextField.placeholder = "Введите сумму"
        amountTextField.borderStyle = .roundedRect
        amountTextField.keyboardType = .decimalPad
        amountTextField.backgroundColor = .white
        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        
        //Result
        resultLabel.text = "Результат: 0"
        resultLabel.textAlignment = .center
        resultLabel.backgroundColor = .white
        resultLabel.layer.cornerRadius = 8
        resultLabel.clipsToBounds = true
        resultLabel.font = .systemFont(ofSize: 14)
        
        //Timer
        timerLabel.text = "Обновление: 5с"
        timerLabel.textAlignment = .center
        timerLabel.backgroundColor = .white
        timerLabel.layer.cornerRadius = 8
        timerLabel.clipsToBounds = true
        timerLabel.font = .systemFont(ofSize: 12)
    }
    
    // MARK: TextField
    func setupTextField() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), doneButton]
        amountTextField.inputAccessoryView = toolbar
    }
    
    // MARK: Header
    func setupHeader() {
        viewHeader.backgroundColor = .lightGray
        
        let fromLabel = UILabel()
        let toLabel = UILabel()
        
        selectedCurrenciesLabelFirst.text = "Выберите"
        selectedCurrenciesLabelFirst.textAlignment = .center
        selectedCurrenciesLabelFirst.font = .systemFont(ofSize: 18, weight: .medium)
        selectedCurrenciesLabelFirst.numberOfLines = 0
        selectedCurrenciesLabelFirst.backgroundColor = .white
        selectedCurrenciesLabelFirst.layer.cornerRadius = 8
        selectedCurrenciesLabelFirst.clipsToBounds = true
        selectedCurrenciesLabelFirst.isUserInteractionEnabled = true
        selectedCurrenciesLabelFirst.tag = 0
        
        selectedCurrenciesLabelSecond.text = "Выберите"
        selectedCurrenciesLabelSecond.textAlignment = .center
        selectedCurrenciesLabelSecond.font = .systemFont(ofSize: 18, weight: .medium)
        selectedCurrenciesLabelSecond.numberOfLines = 0
        selectedCurrenciesLabelSecond.backgroundColor = .white
        selectedCurrenciesLabelSecond.layer.cornerRadius = 8
        selectedCurrenciesLabelSecond.clipsToBounds = true
        selectedCurrenciesLabelSecond.isUserInteractionEnabled = true
        selectedCurrenciesLabelSecond.tag = 1
        
        let tapFirst = UITapGestureRecognizer(target: self, action: #selector(currencyLabelTapped(_:)))
        selectedCurrenciesLabelFirst.addGestureRecognizer(tapFirst)
        
        let tapSecond = UITapGestureRecognizer(target: self, action: #selector(currencyLabelTapped(_:)))
        selectedCurrenciesLabelSecond.addGestureRecognizer(tapSecond)
        
        fromLabel.text = "Из какой:"
        fromLabel.textAlignment = .left
        fromLabel.font = .systemFont(ofSize: 16)
        fromLabel.numberOfLines = 0
        fromLabel.textColor = .black
        
        toLabel.text = "В какую:"
        toLabel.textAlignment = .left
        toLabel.font = .systemFont(ofSize: 16)
        toLabel.numberOfLines = 0
        toLabel.textColor = .black
        
        labelCurrenciesHeaderChois = [fromLabel, toLabel]
        updateActiveCurrencyHighlight()
    }
    
    func setuorateLabel() {
        rateLabel.text = "Курс - "
        rateLabel.textColor = .black
        rateLabel.textAlignment = .center
        rateLabel.font = .systemFont(ofSize: 14, weight: .medium)
        rateLabel.backgroundColor = .white
        rateLabel.layer.cornerRadius = 8
        rateLabel.clipsToBounds = true
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .darkGray
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MyCell.self, forCellWithReuseIdentifier: MyCell.identifire)
    }
    
    // MARK: Layout
    func addSubviews() {
        view.addSubview(viewHeader)
        view.addSubview(favoriteFilterView)
        view.addSubview(filterSegmentedControl)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        
        viewHeader.addSubview(labelCurrenciesHeaderChois[0])
        viewHeader.addSubview(selectedCurrenciesLabelFirst)
        viewHeader.addSubview(labelCurrenciesHeaderChois[1])
        viewHeader.addSubview(selectedCurrenciesLabelSecond)
        viewHeader.addSubview(rateLabel)
        viewHeader.addSubview(amountTextField)
        viewHeader.addSubview(resultLabel)
        viewHeader.addSubview(timerLabel)
    }
    
    //MARK: Constraints
    func makeConstraints() {
        viewHeader.translatesAutoresizingMaskIntoConstraints = false
        favoriteFilterView.translatesAutoresizingMaskIntoConstraints = false
        filterSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        selectedCurrenciesLabelFirst.translatesAutoresizingMaskIntoConstraints = false
        selectedCurrenciesLabelSecond.translatesAutoresizingMaskIntoConstraints = false
        labelCurrenciesHeaderChois[0].translatesAutoresizingMaskIntoConstraints = false
        labelCurrenciesHeaderChois[1].translatesAutoresizingMaskIntoConstraints = false
        rateLabel.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Header
            viewHeader.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            viewHeader.heightAnchor.constraint(equalToConstant: 180),
            viewHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Favorite Filter View
            favoriteFilterView.topAnchor.constraint(equalTo: viewHeader.bottomAnchor, constant: 10),
            favoriteFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            favoriteFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            favoriteFilterView.heightAnchor.constraint(equalToConstant: 50),
            
            // Type Filter
            filterSegmentedControl.topAnchor.constraint(equalTo: favoriteFilterView.bottomAnchor, constant: 10),
            filterSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Collection
            collectionView.topAnchor.constraint(equalTo: filterSegmentedControl.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -15),
            
            // Header Labels
            labelCurrenciesHeaderChois[0].leadingAnchor.constraint(equalTo: viewHeader.leadingAnchor, constant: 16),
            labelCurrenciesHeaderChois[0].topAnchor.constraint(equalTo: viewHeader.topAnchor, constant: 15),
            labelCurrenciesHeaderChois[0].widthAnchor.constraint(equalToConstant: 70),
            
            //Currencies First
            selectedCurrenciesLabelFirst.leadingAnchor.constraint(equalTo: labelCurrenciesHeaderChois[0].trailingAnchor, constant: 12),
            selectedCurrenciesLabelFirst.centerYAnchor.constraint(equalTo: labelCurrenciesHeaderChois[0].centerYAnchor),
            selectedCurrenciesLabelFirst.widthAnchor.constraint(equalToConstant: 100),
            selectedCurrenciesLabelFirst.heightAnchor.constraint(equalToConstant: 40),
            // //Currencies Chois second
            labelCurrenciesHeaderChois[1].leadingAnchor.constraint(equalTo: viewHeader.leadingAnchor, constant: 16),
            labelCurrenciesHeaderChois[1].topAnchor.constraint(equalTo: labelCurrenciesHeaderChois[0].bottomAnchor, constant: 12),
            labelCurrenciesHeaderChois[1].widthAnchor.constraint(equalToConstant: 70),
            
            //Currencies Chois Second
            selectedCurrenciesLabelSecond.leadingAnchor.constraint(equalTo: labelCurrenciesHeaderChois[1].trailingAnchor, constant: 12),
            selectedCurrenciesLabelSecond.centerYAnchor.constraint(equalTo: labelCurrenciesHeaderChois[1].centerYAnchor),
            selectedCurrenciesLabelSecond.widthAnchor.constraint(equalToConstant: 100),
            selectedCurrenciesLabelSecond.heightAnchor.constraint(equalToConstant: 40),
            
            // Rate
            rateLabel.trailingAnchor.constraint(equalTo: viewHeader.trailingAnchor, constant: -16),
            rateLabel.centerYAnchor.constraint(equalTo: selectedCurrenciesLabelFirst.centerYAnchor),
            rateLabel.widthAnchor.constraint(equalToConstant: 220),
            rateLabel.heightAnchor.constraint(equalToConstant: 40),
            
            // TextField
            amountTextField.leadingAnchor.constraint(equalTo: viewHeader.leadingAnchor, constant: 16),
            amountTextField.topAnchor.constraint(equalTo: selectedCurrenciesLabelSecond.bottomAnchor, constant: 8),
            amountTextField.widthAnchor.constraint(equalToConstant: 120),
            amountTextField.heightAnchor.constraint(equalToConstant: 35),
            
            // Result
            resultLabel.leadingAnchor.constraint(equalTo: amountTextField.trailingAnchor, constant: 12),
            resultLabel.centerYAnchor.constraint(equalTo: amountTextField.centerYAnchor),
            resultLabel.widthAnchor.constraint(equalToConstant: 220),
            resultLabel.heightAnchor.constraint(equalToConstant: 35),
            
            //Timer
            timerLabel.trailingAnchor.constraint(equalTo: viewHeader.trailingAnchor, constant: -16),
            timerLabel.bottomAnchor.constraint(equalTo: viewHeader.bottomAnchor, constant: -8),
            timerLabel.widthAnchor.constraint(equalToConstant: 120),
            timerLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // Not Foud Favorite
            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -20)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: 120, height: 100)
        }
    }
    
    // MARK: Actions
    @objc func doneButtonTapped() {
        amountTextField.resignFirstResponder()
    }
    
    @objc func filterChanged() {
        updateFilteredItems()
        collectionView.reloadData()
        updateEmptyState()
    }
    
    @objc func currencyLabelTapped(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else { return }
        
        if label.tag == 0 {
            isEditingFirstCurrency = true
        } else {
            isEditingFirstCurrency = false
        }
        
        updateActiveCurrencyHighlight()
    }
    
    @objc func amountChanged() {
        guard let amountText = amountTextField.text,
              let amount = Double(amountText) else {
            resultLabel.text = "Результат: 0"
            return
        }
        
        let result = amount * currentRate
        resultLabel.text = String(
            format: "Результат: %.6f %@",
            result,
            selectedCurrenciesLabelSecond.text ?? "")
    }
    
    //MARK: Timer
    @objc func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            timerLabel.text = String(format: "Обновление: %dс", timeRemaining)
        } else {
            timeRemaining = 5
            updateRate()
            timerLabel.text = "Обновление: 5с"
        }
    }
    
    // MARK: - Methods
    func updateActiveCurrencyHighlight() {
        if isEditingFirstCurrency {
            selectedCurrenciesLabelFirst.layer.borderWidth = 2
            selectedCurrenciesLabelFirst.layer.borderColor = UIColor.systemBlue.cgColor
            selectedCurrenciesLabelFirst.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            
            selectedCurrenciesLabelSecond.layer.borderWidth = 0
            selectedCurrenciesLabelSecond.backgroundColor = .white
        } else {
            selectedCurrenciesLabelSecond.layer.borderWidth = 2
            selectedCurrenciesLabelSecond.layer.borderColor = UIColor.systemBlue.cgColor
            selectedCurrenciesLabelSecond.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            
            selectedCurrenciesLabelFirst.layer.borderWidth = 0
            selectedCurrenciesLabelFirst.backgroundColor = .white
        }
    }
    
    func updateRate() {
        guard selectedCurrenciesLabelFirst.text != "Выберите",
              selectedCurrenciesLabelSecond.text != "Выберите" else {
            return
        }
        
        currentRate = Double.random(in: 0.001...1000)
        rateLabel.text = String(
            format: "Курс: 1 %@ = %.4f %@",
            selectedCurrenciesLabelFirst.text ?? "",
            currentRate,
            selectedCurrenciesLabelSecond.text ?? "")
        amountChanged()
    }
    
    // MARK: Filters
    func updateFilteredItems() {
        let typeIndex = filterSegmentedControl.selectedSegmentIndex
        var typeFiltered: [String]
        
        switch typeIndex {
        case 1:
            typeFiltered = items.filter { fiatCurrencies.contains($0) }
        case 2:
            typeFiltered = items.filter { cryptoCurrencies.contains($0) }
        default:
            typeFiltered = items
        }
        
        if favoriteFilterView.isFilterEnabled {
            filteredItems = typeFiltered.filter { favoritesCurrencies.contains($0) }
        } else {
            filteredItems = typeFiltered
        }
    }
    
    func updateEmptyState() {
        if favoriteFilterView.isFilterEnabled && filteredItems.isEmpty {
            emptyStateLabel.isHidden = false
            collectionView.isHidden = true
        } else {
            emptyStateLabel.isHidden = true
            collectionView.isHidden = false
        }
    }
    
    // MARK: Start Timer
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    // MARK: Alert
    func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Хорошо", style: .default))
        present(alert, animated: true)
    }
    
    func saveFavorites() {
        UserDefaults.standard.set(Array(favoritesCurrencies), forKey: "favoriteCurrencies")
    }
    
    func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.array(forKey: "favoriteCurrencies") as? [String] {
            favoritesCurrencies = Set(savedFavorites)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - UICollectionViewDataSource
extension CurrencySelectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MyCell.identifire,
            for: indexPath) as? MyCell else { return UICollectionViewCell() }
        
        let currency = filteredItems[indexPath.item]
        
        cell.configure(with: currency, isFavorite: favoritesCurrencies.contains(currency))
        cell.delegate = self
        
        if currency == selectedCurrenciesLabelFirst.text || currency == selectedCurrenciesLabelSecond.text {
            cell.backgroundColor = .green
        } else {
            cell.backgroundColor = .lightGray
        }
        
        if (isEditingFirstCurrency && currency == selectedCurrenciesLabelFirst.text) ||
            (!isEditingFirstCurrency && currency == selectedCurrenciesLabelSecond.text) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1.0
        }
        
        cell.layer.cornerRadius = 12
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension CurrencySelectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCurrency = filteredItems[indexPath.row]
        
        if isEditingFirstCurrency {
            if selectedCurrency != selectedCurrenciesLabelSecond.text {
                selectedCurrenciesLabelFirst.text = selectedCurrency
                updateRate()
            } else {
                showAlert(message: "Нельзя выбрать одинаковые валюты")
                return
            }
        } else {
            if selectedCurrency != selectedCurrenciesLabelFirst.text {
                selectedCurrenciesLabelSecond.text = selectedCurrency
                updateRate()
            } else {
                showAlert(message: "Нельзя выбрать одинаковые валюты")
                return
            }
        }
        collectionView.reloadData()
    }
}

// MARK: - MyCellDelegate
extension CurrencySelectionViewController: MyCellDelegate {
    func didTapFavoriteButton(in cell: MyCell, for currency: String) {
        if favoritesCurrencies.contains(currency) {
            favoritesCurrencies.remove(currency)
        } else {
            favoritesCurrencies.insert(currency)
        }
        
        saveFavorites()
        updateFilteredItems()
        collectionView.reloadData()
        updateEmptyState()
    }
}

// MARK: - FavoriteFilterViewDelegate
extension CurrencySelectionViewController: FavoriteFilterViewDelegate {
    func favoriteFilterDidChange(isEnabled: Bool) {
        updateFilteredItems()
        collectionView.reloadData()
        updateEmptyState()
    }
}
