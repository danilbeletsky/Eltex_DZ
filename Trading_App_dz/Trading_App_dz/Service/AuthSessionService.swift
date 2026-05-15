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
        clearSavedUser()
        let loginSaved = KeychainService.shared.save(key: loginKey, value: login)
        let passwordSaved = KeychainService.shared.save(key: passwordKey, value: password)
        return loginSaved && passwordSaved
    }

    func validateCredentials(login: String, password: String) -> Bool {
        guard let savedLogin = KeychainService.shared.get(key: loginKey),
              let savedPassword = KeychainService.shared.get(key: passwordKey) else {
            return false
        }

        return savedLogin == login && savedPassword == password
    }

    func canAutoLogin() -> Bool {
        return isAutoLoginEnabled && isLoggedIn
    }

    func logout() {
        isLoggedIn = false
    }

    private func clearSavedUser() {
        _ = KeychainService.shared.delete(key: loginKey)
        _ = KeychainService.shared.delete(key: passwordKey)
    }
}
