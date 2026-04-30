import Foundation
import UIKit

final class SettingsController: UIViewController {
    private let buttonExit = UIButton()
    private let autoLoginLabel = UILabel()
    private let autoLoginSwitch = UISwitch()
    private let autoLoginStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupAutoLogin()
        setupExit()
        makeConstraints()
        updateAutoLoginState()
    }

    private func setupAutoLogin() {
        autoLoginLabel.text = "Автовход"
        autoLoginLabel.font = .systemFont(ofSize: 18, weight: .medium)
        autoLoginLabel.textColor = .black

        autoLoginSwitch.addTarget(self, action: #selector(handleAutoLoginChanged), for: .valueChanged)

        autoLoginStack.axis = .horizontal
        autoLoginStack.alignment = .center
        autoLoginStack.distribution = .equalSpacing
        autoLoginStack.addArrangedSubview(autoLoginLabel)
        autoLoginStack.addArrangedSubview(autoLoginSwitch)

        view.addSubview(autoLoginStack)
    }

    private func setupExit() {
        buttonExit.setTitle("Выйти", for: .normal)
        buttonExit.setTitleColor(UIColor.white, for: .normal)
        buttonExit.backgroundColor = .red
        buttonExit.layer.cornerRadius = 16
        buttonExit.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        buttonExit.addTarget(self, action: #selector(handleTapExit), for: .touchUpInside)

        view.addSubview(buttonExit)
    }

    private func makeConstraints() {
        autoLoginStack.translatesAutoresizingMaskIntoConstraints = false
        buttonExit.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            autoLoginStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            autoLoginStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            autoLoginStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),

            buttonExit.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonExit.topAnchor.constraint(equalTo: autoLoginStack.bottomAnchor, constant: 40),
            buttonExit.widthAnchor.constraint(equalToConstant: 300),
            buttonExit.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func updateAutoLoginState() {
        autoLoginSwitch.isOn = AuthSessionService.shared.isAutoLoginEnabled
    }

    @objc
    private func handleAutoLoginChanged() {
        AuthSessionService.shared.isAutoLoginEnabled = autoLoginSwitch.isOn
    }

    @objc
    private func handleTapExit() {
        let alert = UIAlertController(
            title: "Подтверждение",
            message: "Вы действительно хотите выйти?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            self?.switchToRegistrationApp()
        })

        present(alert, animated: true)
    }

    private func switchToRegistrationApp() {
        AuthSessionService.shared.logout()
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchToRegistrationApp()
        }
    }
}
