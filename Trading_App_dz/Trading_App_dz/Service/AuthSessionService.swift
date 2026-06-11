import Foundation

final class AuthSessionService {
    static let shared = AuthSessionService()

    private let defaults = UserDefaults.standard
    private let loginKey = "auth.saved.login"
    private let passwordKey = "auth.saved.password"
    private let isAutoLoginEnabledKey = "auth.autoLogin.enabled"
    private let isLoggedInKey = "auth.session.loggedIn"

    private init() {}

    var isAutoLoginEnabled: Bool {
        get { defaults.bool(forKey: isAutoLoginEnabledKey) }
        set { defaults.set(newValue, forKey: isAutoLoginEnabledKey) }
    }

    var isLoggedIn: Bool {
        get { defaults.bool(forKey: isLoggedInKey) }
        set { defaults.set(newValue, forKey: isLoggedInKey) }
    }

    func saveUser(login: String, password: String) -> Bool {
        AppLogger.auth("Регистрация пользователя", level: .info, metadata: ["loginLength": "\(login.count)"])
        clearSavedUser()
        let loginSaved = KeychainService.shared.save(key: loginKey, value: login)
        let passwordSaved = KeychainService.shared.save(key: passwordKey, value: password)
        let success = loginSaved && passwordSaved
        AppLogger.auth(
            success ? "Пользователь успешно сохранён" : "Не удалось сохранить учётные данные",
            level: success ? .info : .error,
            metadata: ["loginSaved": "\(loginSaved)", "passwordSaved": "\(passwordSaved)"]
        )
        return success
    }

    func validateCredentials(login: String, password: String) -> Bool {
        guard let savedLogin = KeychainService.shared.get(key: loginKey),
              let savedPassword = KeychainService.shared.get(key: passwordKey) else {
            AppLogger.auth(
                "Вход отклонён: учётные данные не найдены в Keychain",
                level: .warning,
                metadata: ["loginLength": "\(login.count)"]
            )
            return false
        }

        let isValid = savedLogin == login && savedPassword == password
        AppLogger.auth(
            isValid ? "Учётные данные подтверждены" : "Вход отклонён: неверный логин или пароль",
            level: isValid ? .info : .warning,
            metadata: ["loginLength": "\(login.count)"]
        )
        return isValid
    }

    func canAutoLogin() -> Bool {
        return isAutoLoginEnabled && isLoggedIn
    }

    func logout() {
        AppLogger.auth("Выход из сессии", level: .info)
        isLoggedIn = false
    }

    private func clearSavedUser() {
        _ = KeychainService.shared.delete(key: loginKey)
        _ = KeychainService.shared.delete(key: passwordKey)
    }
}
