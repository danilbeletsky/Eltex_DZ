import Combine
import Foundation
import UIKit

final class AuthViewController: UIViewController {
    private let header = UILabel()
    private let loginTextField = UITextField()
    private let passwordTextField = UITextField()
    private let actionButton = UIButton()
    private let modeSegmentedControl = UISegmentedControl(items: ["Вход", "Регистрация"])
    private let containerStack = UIStackView()

    private var cancellables = Set<AnyCancellable>()
    private let onAuthorized: () -> Void

    init(onAuthorized: @escaping () -> Void = {}) {
        self.onAuthorized = onAuthorized
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum AuthMode {
        case signIn
        case signUp
    }

    private var currentMode: AuthMode {
        modeSegmentedControl.selectedSegmentIndex == 0 ? .signIn : .signUp
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        makeConstraints()
        bindValidation()
        updateActionButtonTitle()
        modeSegmentedControl.addTarget(self, action: #selector(modeSegmentChanged), for: .valueChanged)
    }

    private func bindValidation() {
        let loginPublisher = loginTextField.textPublisher
        let passwordPublisher = passwordTextField.textPublisher

        Publishers.CombineLatest(loginPublisher, passwordPublisher)
            .map { login, password in
                let trimmed = login.trimmingCharacters(in: .whitespacesAndNewlines)
                return AuthViewController.isFormValid(login: trimmed, password: password)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isValid in
                guard let self else { return }
                self.actionButton.isEnabled = isValid
                self.actionButton.alpha = isValid ? 1 : 0.45
            }
            .store(in: &cancellables)
    }

    /// Те же правила, что в `handleForwardTap`: логин не пустой, пароль не пустой и не короче 4 символов.
    private static func isFormValid(login: String, password: String) -> Bool {
        !login.isEmpty && !password.isEmpty && password.count >= 4
    }

    @objc
    private func modeSegmentChanged() {
        updateActionButtonTitle()
    }

    private func updateActionButtonTitle() {
        let title: String
        switch currentMode {
        case .signIn:
            title = "Войти"
        case .signUp:
            title = "Зарегистрироваться"
        }
        actionButton.setTitle(title, for: .normal)
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupHeader()
        setupContainerStack()
        setupLogin()
        setupPassword()
        setupActionButton()
        setupSegment()
    }

    private func makeConstraints() {
        header.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        loginTextField.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        modeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),

            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            loginTextField.heightAnchor.constraint(equalToConstant: 48),
            passwordTextField.heightAnchor.constraint(equalToConstant: 48),
            actionButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }

    private func setupHeader() {
        header.text = "Авторизация"
        header.textColor = .black
        header.font = UIFont.systemFont(ofSize: 24)
        header.textAlignment = .center
        header.numberOfLines = 0
        
        view.addSubview(header)
    }

    private func setupLogin() {
        loginTextField.placeholder = "Логин"
        loginTextField.borderStyle = .none
        loginTextField.layer.cornerRadius = 12
        loginTextField.layer.borderWidth = 1
        loginTextField.layer.borderColor = UIColor.systemGray4.cgColor
        loginTextField.backgroundColor = .white
        loginTextField.font = .systemFont(ofSize: 16)
        loginTextField.autocorrectionType = .no
        loginTextField.autocapitalizationType = .none
        loginTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        loginTextField.leftViewMode = .always

        containerStack.addArrangedSubview(loginTextField)
    }

    private func setupContainerStack() {
        containerStack.axis = .vertical
        containerStack.spacing = 16
        view.addSubview(containerStack)
    }

    private func setupPassword() {
        passwordTextField.placeholder = "Пароль"
        passwordTextField.borderStyle = .none
        passwordTextField.layer.cornerRadius = 12
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.systemGray4.cgColor
        passwordTextField.backgroundColor = .white
        passwordTextField.font = .systemFont(ofSize: 16)
        passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        passwordTextField.leftViewMode = .always
        passwordTextField.isSecureTextEntry = true

        containerStack.addArrangedSubview(passwordTextField)
    }

    private func setupActionButton() {
        actionButton.isEnabled = false
        actionButton.alpha = 0.45
        actionButton.layer.cornerRadius = 16
        actionButton.backgroundColor = .systemBlue
        actionButton.addTarget(self, action: #selector(handleForwardTap), for: .touchUpInside)

        containerStack.addArrangedSubview(actionButton)
    }

    private func setupSegment() {
        modeSegmentedControl.selectedSegmentIndex = 0
        containerStack.addArrangedSubview(modeSegmentedControl)
    }

    @objc
    func handleForwardTap() {
        guard actionButton.isEnabled else { return }
        guard let login = loginTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordTextField.text else {
            showAlert(message: "Заполните все поля")
            return
        }

        guard isInputValid(login: login, password: password) else {
            showAlert(message: "Логин не должен быть пустым, пароль минимум 4 символа")
            return
        }

        switch currentMode {
        case .signIn:
            if AuthSessionService.shared.validateCredentials(login: login, password: password) {
                AuthSessionService.shared.isLoggedIn = true
                onAuthorized()
            } else {
                // По ТЗ достаточно не пускать пользователя при неверных данных.
                return
            }
        case .signUp:
            let success = AuthSessionService.shared.saveUser(login: login, password: password)
            if success {
                AuthSessionService.shared.isLoggedIn = true
                onAuthorized()
            } else {
                showAlert(message: "Не удалось сохранить пользователя")
            }
        }
    }

    private func isInputValid(login: String, password: String) -> Bool {
        Self.isFormValid(login: login, password: password)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

private extension UITextField {
    var textPublisher: AnyPublisher<String, Never> {
        Publishers.Merge(
            Just(text ?? ""),
            NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: self)
                .compactMap { ($0.object as? UITextField)?.text }
        )
        .eraseToAnyPublisher()
    }
}
