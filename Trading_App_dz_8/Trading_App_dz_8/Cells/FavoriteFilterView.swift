import UIKit

protocol FavoriteFilterViewDelegate: AnyObject {
    func favoriteFilterDidChange(isEnabled: Bool)
}

final class FavoriteFilterView: UIView {
    weak var delegate: FavoriteFilterViewDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Показать избранное"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let filterSwitch: UISwitch = {
        let switcher = UISwitch()
        switcher.translatesAutoresizingMaskIntoConstraints = false
        return switcher
    }()
    
    var isFilterEnabled: Bool {
        return filterSwitch.isOn
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 8
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        addSubview(filterSwitch)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            filterSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            filterSwitch.centerYAnchor.constraint(equalTo: centerYAnchor),
            filterSwitch.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
        filterSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }
    
    @objc private func switchChanged() {
        delegate?.favoriteFilterDidChange(isEnabled: filterSwitch.isOn)
    }
    
    func setEnabled(_ isEnabled: Bool) {
        filterSwitch.isOn = isEnabled
    }
}
