import UIKit

final class MyCell: UICollectionViewCell {
    static let identifire = "MyCell"
    
    private let label: UILabel = {
       let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 16)
        return label
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
    
    func makeConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with text: String) {
        label.text = text
    }
    
    func addSubviews() {
        contentView.addSubview(label)
    }
    
}
