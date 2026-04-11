import UIKit

final class TextChatMessageCell: UITableViewCell {
    
    static let identifier = "TextChatMessageCell"
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let mainInfoLabel = UILabel()
    private let additionalInfoLabel = UILabel()
    private let stackView = UIStackView()
    
    private var currentTrade: Trade?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with trade: Trade) {
        self.currentTrade = trade
        updateUI()
    }
    
    // MARK: - Private Methods
    private func updateUI() {
        guard let trade = currentTrade else { return }
        
        mainInfoLabel.text = trade.mainInfo
        
        if let additionalInfo = trade.additionalInfo {
            additionalInfoLabel.text = additionalInfo
            additionalInfoLabel.isHidden = false
        } else {
            additionalInfoLabel.text = nil
            additionalInfoLabel.isHidden = true
        }
        
        containerView.backgroundColor = trade.type.color.withAlphaComponent(0.3)
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        
        mainInfoLabel.font = .systemFont(ofSize: 16, weight: .medium)
        mainInfoLabel.numberOfLines = 0
        mainInfoLabel.textColor = .black
        
        additionalInfoLabel.font = .systemFont(ofSize: 14)
        additionalInfoLabel.numberOfLines = 0
        additionalInfoLabel.textColor = .darkGray
        additionalInfoLabel.isHidden = true
        
        stackView.addArrangedSubview(mainInfoLabel)
        stackView.addArrangedSubview(additionalInfoLabel)
        
        containerView.addSubview(stackView)
        contentView.addSubview(containerView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
}
