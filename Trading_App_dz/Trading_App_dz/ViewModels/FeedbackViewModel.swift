import Foundation
import Combine

final class FeedbackViewModel: ObservableObject {
    enum Field: Hashable {
        case name
        case message
    }

    private enum Constants {
        static let minFieldLength = 3
        static let maxNameLength = 30
        static let maxMessageLength = 150
    }

    var onSubmitted: (() -> Void)?

    @Published var name = ""
    @Published var message = ""
    @Published var selectedThemes: [String] = []
    @Published var isAgreed = false
    @Published var showAgreement = false
    @Published var showSuccessAlert = false
    @Published private(set) var focusedField: Field?
    @Published private(set) var nameHasBeenBlurred = false
    @Published private(set) var messageHasBeenBlurred = false
    @Published private(set) var didAttemptSubmit = false

    let agreementText = """
    Настоящим вы подтверждаете согласие на обработку персональных данных, указанных в форме обратной связи.

    1. Оператор обрабатывает имя автора и текст обращения исключительно для ответа на запрос пользователя.
    2. Данные не передаются третьим лицам без законных оснований.
    3. Пользователь вправе отозвать согласие, направив запрос через форму обратной связи.
    4. Срок хранения данных определяется внутренними правилами сервиса и не превышает срок, необходимый для обработки обращения.
    5. При отправке формы пользователь подтверждает достоверность предоставленной информации.

    Дополнительные положения могут быть уточнены в актуальной редакции политики конфиденциальности приложения.
    """

    init(onSubmitted: (() -> Void)? = nil) {
        self.onSubmitted = onSubmitted
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nameValidationError: String? {
        if trimmedName.isEmpty || trimmedName.count < Constants.minFieldLength {
            return "Поле имя должно содержать не менее 3-х символов"
        }
        if trimmedName.count > Constants.maxNameLength {
            return "Поле имя должно содержать не более 30 символов"
        }
        return nil
    }

    var messageValidationError: String? {
        if trimmedMessage.isEmpty {
            return "Текст обращения не должен быть пустым"
        }
        if trimmedMessage.count < Constants.minFieldLength {
            return "Текст обращения должен содержать не менее 3-х символов"
        }
        if trimmedMessage.count > Constants.maxMessageLength {
            return "Текст обращения должен содержать не более 150 символов"
        }
        return nil
    }

    var agreementError: String? {
        isAgreed ? nil : "Необходимо согласие на обработку данных"
    }

    var canSubmit: Bool {
        nameValidationError == nil && messageValidationError == nil && isAgreed
    }

    var displayedNameError: String? {
        guard focusedField != .name else { return nil }
        guard nameHasBeenBlurred else { return nil }
        return nameValidationError
    }

    var displayedMessageError: String? {
        guard focusedField != .message else { return nil }
        guard messageHasBeenBlurred else { return nil }
        return messageValidationError
    }

    var displayedAgreementError: String? {
        didAttemptSubmit ? agreementError : nil
    }

    func setFocusedField(_ field: Field?) {
        let previous = focusedField
        focusedField = field

        if previous == .name {
            nameHasBeenBlurred = true
        }
        if previous == .message {
            messageHasBeenBlurred = true
        }
    }

    func submitFeedback() {
        didAttemptSubmit = true
        nameHasBeenBlurred = true
        messageHasBeenBlurred = true
        focusedField = nil
        guard canSubmit else { return }
        showSuccessAlert = true
    }

    func handleSuccessAlertDismissed() {
        showSuccessAlert = false
        onSubmitted?()
    }
}
