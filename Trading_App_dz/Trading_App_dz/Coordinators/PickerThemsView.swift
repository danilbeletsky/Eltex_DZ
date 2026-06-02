import UIKit
import SwiftUI

protocol PickerThemsViewDelegate: AnyObject {
    func directionsPickerView(_ view: PickerThemsView, didChangeSelected themes: [String])
}

struct UIKitPickerThemsView: UIViewRepresentable {
    let thems: [String]
    @Binding var selectedThemes: [String]

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedThemes: $selectedThemes)
    }

    func makeUIView(context: Context) -> PickerThemsView {
        let view = PickerThemsView(thems: thems)
        view.delegate = context.coordinator
        view.applySelection(selectedThemes)
        return view
    }

    func updateUIView(_ uiView: PickerThemsView, context: Context) {
        uiView.applySelection(selectedThemes)
    }

    final class Coordinator: NSObject, PickerThemsViewDelegate {
        @Binding var selectedThemes: [String]

        init(selectedThemes: Binding<[String]>) {
            _selectedThemes = selectedThemes
        }

        func directionsPickerView(_ view: PickerThemsView, didChangeSelected themes: [String]) {
            selectedThemes = themes
        }
    }
}

final class PickerThemsView: UIView {
    private let stackView = UIStackView()
    private let thems: [String]
    weak var delegate: PickerThemsViewDelegate?

    private(set) var selectedThemes = Set<String>()

    init(thems: [String]) {
        self.thems = thems
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    private func setupUI() {
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubviews()
        makeConstraints()
        makeButton()
    }
}

private extension PickerThemsView {
    func addSubviews() {
        addSubview(stackView)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    func makeButton() {
        for theme in thems {
            let button = UIButton(type: .system)
            button.setTitle(theme, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.backgroundColor = .systemGray6
            button.layer.cornerRadius = 10
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.2).cgColor
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            button.accessibilityIdentifier = theme
            button.addTarget(self, action: #selector(themeTapped(_:)), for: .touchUpInside)

            stackView.addArrangedSubview(button)
        }
    }

    @objc
    func themeTapped(_ sender: UIButton) {
        guard let theme = sender.accessibilityIdentifier else { return }

        if selectedThemes.contains(theme) {
            selectedThemes.remove(theme)
        } else {
            selectedThemes.insert(theme)
        }

        updateButtonsState()

        let orderedSelectedThemes = thems.filter { selectedThemes.contains($0) }
        delegate?.directionsPickerView(self, didChangeSelected: orderedSelectedThemes)
    }

    func applySelection(_ themes: [String]) {
        selectedThemes = Set(themes)
        updateButtonsState()
    }

    func updateButtonsState() {
        for case let button as UIButton in stackView.arrangedSubviews {
            guard let theme = button.accessibilityIdentifier else { continue }
            let isSelected = selectedThemes.contains(theme)

            button.backgroundColor = isSelected ? .systemBlue : .systemGray6
            button.setTitleColor(isSelected ? .white : .systemBlue, for: .normal)
        }
    }
}
