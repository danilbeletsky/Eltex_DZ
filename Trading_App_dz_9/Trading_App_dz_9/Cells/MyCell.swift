import UIKit

protocol MyCellDelegate: AnyObject {
    func didTapFavoriteButton(in cell: MyCell, for currency: String)
}

final class MyCell: UICollectionViewCell {
    // MARK: - UI Elements
    static let identifire = "MyCell"
    
    weak var delegate: MyCellDelegate?
    private var currentCurrency: String = ""
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }()
    
    private lazy var favoriteButton: UIButton = {
        let button = UIButton()
        
        let emptyStar = UIImage(systemName: "star")
        let filledStar = UIImage(systemName: "star.fill")
        
        button.setImage(emptyStar, for: .normal)
        button.setImage(filledStar, for: .selected)
        button.tintColor = .systemYellow
        button.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        contentView.layer.cornerRadius = 16
        
        addSubviews()
        makeConstraints()
    }
    // MARK: Constraint
    func makeConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 30),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with text: String, isFavorite: Bool = false) {
        label.text = text
        currentCurrency = text
        favoriteButton.isSelected = isFavorite
    }
    
    func addSubviews() {
        contentView.addSubview(label)
        contentView.addSubview(favoriteButton)
    }
    
    @objc private func favoriteTapped() {
        favoriteButton.isSelected.toggle()
        delegate?.didTapFavoriteButton(in: self, for: currentCurrency)
    }
}
