import Foundation
import UIKit

final class SettingsController: UIViewController {
    private let buttonExit = UIButton()
    private let autoLoginLabel = UILabel()
    private let autoLoginSwitch = UISwitch()
    private let autoLoginStack = UIStackView()

    private let networkCombineLabel = UILabel()
    private let networkCombineSwitch = UISwitch()
    private let networkCombineStack = UIStackView()
    private let onLogoutRequested: () -> Void

    init(onLogoutRequested: @escaping () -> Void = {}) {
        self.onLogoutRequested = onLogoutRequested
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupAutoLogin()
        setupNetworkCombine()
        setupExit()
        makeConstraints()
        updateAutoLoginState()
        updateNetworkCombineState()
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

    private func setupNetworkCombine() {
        networkCombineLabel.text = "Сеть (Combine для валют)"
        networkCombineLabel.font = .systemFont(ofSize: 18, weight: .medium)
        networkCombineLabel.textColor = .black

        networkCombineSwitch.addTarget(self, action: #selector(handleNetworkCombineChanged), for: .valueChanged)

        networkCombineStack.axis = .horizontal
        networkCombineStack.alignment = .center
        networkCombineStack.distribution = .equalSpacing
        networkCombineStack.addArrangedSubview(networkCombineLabel)
        networkCombineStack.addArrangedSubview(networkCombineSwitch)

        view.addSubview(networkCombineStack)
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
        networkCombineStack.translatesAutoresizingMaskIntoConstraints = false
        buttonExit.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            autoLoginStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            autoLoginStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            autoLoginStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),

            networkCombineStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            networkCombineStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            networkCombineStack.topAnchor.constraint(equalTo: autoLoginStack.bottomAnchor, constant: 24),

            buttonExit.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonExit.topAnchor.constraint(equalTo: networkCombineStack.bottomAnchor, constant: 40),
            buttonExit.widthAnchor.constraint(equalToConstant: 300),
            buttonExit.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func updateAutoLoginState() {
        autoLoginSwitch.isOn = AuthSessionService.shared.isAutoLoginEnabled
    }

    private func updateNetworkCombineState() {
        networkCombineSwitch.isOn = NetworkService.isNetworkWithCombine
    }

    @objc
    private func handleAutoLoginChanged() {
        AuthSessionService.shared.isAutoLoginEnabled = autoLoginSwitch.isOn
    }

    @objc
    private func handleNetworkCombineChanged() {
        NetworkService.isNetworkWithCombine = networkCombineSwitch.isOn
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
        onLogoutRequested()
    }
}
