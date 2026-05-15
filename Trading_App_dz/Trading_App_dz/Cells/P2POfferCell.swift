import UIKit

final class P2POfferCell: UITableViewCell {
    static let reuseId = "P2POfferCell"

    private let sellerLabel = UILabel()
    private let rateLabel = UILabel()
    private let reserveLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with offer: P2POffer) {
        sellerLabel.text = offer.sellerName
        rateLabel.text = String(
            format: "Курс: 1 %@ = %.6f %@",
            offer.pair.from,
            offer.rate,
            offer.pair.to
        )
        reserveLabel.text = String(
            format: "Резерв: %.2f %@",
            offer.reserve,
            offer.pair.to
        )
    }
}

private extension P2POfferCell {
    func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        contentView.addSubview(card)

        [sellerLabel, rateLabel, reserveLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }

        sellerLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        rateLabel.font = .systemFont(ofSize: 15, weight: .regular)
        reserveLabel.font = .systemFont(ofSize: 14, weight: .regular)
        reserveLabel.textColor = .secondaryLabel

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            sellerLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            sellerLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            sellerLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            rateLabel.topAnchor.constraint(equalTo: sellerLabel.bottomAnchor, constant: 8),
            rateLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            rateLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),

            reserveLabel.topAnchor.constraint(equalTo: rateLabel.bottomAnchor, constant: 8),
            reserveLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            reserveLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            reserveLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
    }
}
