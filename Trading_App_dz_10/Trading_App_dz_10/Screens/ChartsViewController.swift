import Foundation
import UIKit

final class ChartsViewController: UIViewController {
    private var collectionView: UICollectionView!

    private let candleDetailsView = UIView()
    private let recommendationView = UIView()
    private let recommendationLabel = UILabel()

    private let openLabel = UILabel()
    private let closeLabel = UILabel()
    private let highLabel = UILabel()
    private let lowLabel = UILabel()

    private var candles: [CandleData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        configureViews()
        layoutViews()
        generateCandles()
        collectionView.reloadData()

        if let firstCandle = candles.first {
            showDetails(for: firstCandle)
        }
    }

    private func configureViews() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .secondarySystemBackground
        collectionView.layer.cornerRadius = 12
        collectionView.register(CandleCell.self, forCellWithReuseIdentifier: CandleCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self

        [openLabel, closeLabel, highLabel, lowLabel].forEach {
            $0.font = .systemFont(ofSize: 16, weight: .medium)
            $0.textColor = .label
        }

        candleDetailsView.backgroundColor = .secondarySystemBackground
        candleDetailsView.layer.cornerRadius = 12

        recommendationView.backgroundColor = .secondarySystemBackground
        recommendationView.layer.cornerRadius = 12

        recommendationLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        recommendationLabel.textColor = .label
        recommendationLabel.text = "Рекомендации: —"
        recommendationLabel.numberOfLines = 0
    }

    private func layoutViews() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        candleDetailsView.translatesAutoresizingMaskIntoConstraints = false
        recommendationView.translatesAutoresizingMaskIntoConstraints = false
        recommendationLabel.translatesAutoresizingMaskIntoConstraints = false

        openLabel.translatesAutoresizingMaskIntoConstraints = false
        closeLabel.translatesAutoresizingMaskIntoConstraints = false
        highLabel.translatesAutoresizingMaskIntoConstraints = false
        lowLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(collectionView)
        view.addSubview(candleDetailsView)
        view.addSubview(recommendationView)

        candleDetailsView.addSubview(openLabel)
        candleDetailsView.addSubview(closeLabel)
        candleDetailsView.addSubview(highLabel)
        candleDetailsView.addSubview(lowLabel)
        recommendationView.addSubview(recommendationLabel)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 260),

            candleDetailsView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            candleDetailsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            candleDetailsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            candleDetailsView.heightAnchor.constraint(equalToConstant: 140),

            openLabel.topAnchor.constraint(equalTo: candleDetailsView.topAnchor, constant: 14),
            openLabel.leadingAnchor.constraint(equalTo: candleDetailsView.leadingAnchor, constant: 16),
            openLabel.trailingAnchor.constraint(equalTo: candleDetailsView.trailingAnchor, constant: -16),

            closeLabel.topAnchor.constraint(equalTo: openLabel.bottomAnchor, constant: 8),
            closeLabel.leadingAnchor.constraint(equalTo: openLabel.leadingAnchor),
            closeLabel.trailingAnchor.constraint(equalTo: openLabel.trailingAnchor),

            highLabel.topAnchor.constraint(equalTo: closeLabel.bottomAnchor, constant: 8),
            highLabel.leadingAnchor.constraint(equalTo: openLabel.leadingAnchor),
            highLabel.trailingAnchor.constraint(equalTo: openLabel.trailingAnchor),

            lowLabel.topAnchor.constraint(equalTo: highLabel.bottomAnchor, constant: 8),
            lowLabel.leadingAnchor.constraint(equalTo: openLabel.leadingAnchor),
            lowLabel.trailingAnchor.constraint(equalTo: openLabel.trailingAnchor),

            recommendationView.topAnchor.constraint(equalTo: candleDetailsView.bottomAnchor, constant: 16),
            recommendationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            recommendationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            recommendationView.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),

            recommendationLabel.topAnchor.constraint(equalTo: recommendationView.topAnchor, constant: 14),
            recommendationLabel.bottomAnchor.constraint(equalTo: recommendationView.bottomAnchor, constant: -14),
            recommendationLabel.leadingAnchor.constraint(equalTo: recommendationView.leadingAnchor, constant: 16),
            recommendationLabel.trailingAnchor.constraint(equalTo: recommendationView.trailingAnchor, constant: -16)
        ])
    }

    private func generateCandles() {
        var candlesToBuild: [CandleData] = []
        
        for _ in 0..<28 {
            let open = Double.random(in: 80...120)
            let close = open + Double.random(in: -15...15)
            let high = max(open, close) + Double.random(in: 2...9)
            let low = min(open, close) - Double.random(in: 2...9)

            candlesToBuild.append(
                CandleData(
                    open: open,
                    close: close,
                    high: high,
                    low: low
                )
            )
        }

        candles = candlesToBuild
    }
    
    private func showDetails(for candle: CandleData) {
        openLabel.text = String(format: "Открытие: %.2f", candle.open)
        closeLabel.text = String(format: "Закрытие: %.2f", candle.close)
        highLabel.text = String(format: "Максимум: %.2f", candle.high)
        lowLabel.text = String(format: "Минимум: %.2f", candle.low)
    }

    private func showRecommendation(for candle: CandleData) {
        let recommendation: String

        if candle.close > candle.open {
            recommendation = "покупать"
        } else if candle.close < candle.open {
            recommendation = "продавать"
        } else {
            recommendation = "ждать"
        }

        recommendationLabel.text = "Рекомендации: \(recommendation)"
    }
}

private struct CandleData {
    let open: Double
    let close: Double
    let high: Double
    let low: Double

    var isGrowing: Bool {
        close >= open
    }
}

private final class CandleView: UIView {
    private let bodyView = UIView()
    private let tailView = UIView()

    private var bodyTopConstraint: NSLayoutConstraint?
    private var bodyHeightConstraint: NSLayoutConstraint?
    private var tailTopConstraint: NSLayoutConstraint?
    private var tailBottomConstraint: NSLayoutConstraint?

    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(tailView)
        addSubview(bodyView)

        bodyView.translatesAutoresizingMaskIntoConstraints = false
        tailView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.layer.cornerRadius = 6
        tailView.layer.cornerRadius = 1.5

        bodyTopConstraint = bodyView.topAnchor.constraint(equalTo: topAnchor, constant: 50)
        bodyHeightConstraint = bodyView.heightAnchor.constraint(equalToConstant: 70)
        tailTopConstraint = tailView.topAnchor.constraint(equalTo: topAnchor, constant: 30)
        tailBottomConstraint = tailView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30)

        NSLayoutConstraint.activate([
            bodyView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bodyView.widthAnchor.constraint(equalToConstant: 30),
            bodyTopConstraint,
            bodyHeightConstraint,

            tailView.centerXAnchor.constraint(equalTo: centerXAnchor),
            tailView.widthAnchor.constraint(equalToConstant: 3),
            tailTopConstraint,
            tailBottomConstraint
        ].compactMap { $0 })

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPress)
    }

    func configure(with candle: CandleData) {
        let color: UIColor = candle.isGrowing ? .systemGreen : .systemRed
        bodyView.backgroundColor = color
        tailView.backgroundColor = color

        let bodyHeight = CGFloat.random(in: 40...110)
        let tailExtraTop = CGFloat.random(in: 8...40)
        let tailExtraBottom = CGFloat.random(in: 8...40)
        let bodyTop = CGFloat.random(in: 45...95)

        bodyTopConstraint?.constant = bodyTop
        bodyHeightConstraint?.constant = bodyHeight
        tailTopConstraint?.constant = max(8, bodyTop - tailExtraTop)
        tailBottomConstraint?.constant = -max(8, 220 - (bodyTop + bodyHeight) + tailExtraBottom)
    }

    @objc private func handleTap() {
        onTap?()
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            onLongPress?()
        }
    }
}

private final class CandleCell: UICollectionViewCell {
    static let identifier = "CandleCell"
    private let candleView = CandleView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(candleView)
        candleView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            candleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            candleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            candleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            candleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(
        candle: CandleData,
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) {
        candleView.configure(with: candle)
        candleView.onTap = onTap
        candleView.onLongPress = onLongPress
    }
}

extension ChartsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        candles.count
    }

    func collectionView( _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CandleCell.identifier,
            for: indexPath
        ) as? CandleCell else {
            return UICollectionViewCell()
        }

        let candle = candles[indexPath.item]
        cell.configure(
            candle: candle,
            onTap: { [weak self] in
                self?.showDetails(for: candle)
            },
            onLongPress: { [weak self] in
                self?.showRecommendation(for: candle)
            }
        )
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 42, height: 220)
    }
}
