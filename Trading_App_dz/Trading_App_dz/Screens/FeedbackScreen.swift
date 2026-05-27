import SwiftUI

struct FeedbackScreen: View {
    var onSubmitted: (() -> Void)?

    @State private var name = ""
    @State private var message = ""
    @State private var isAgreed = false
    @State private var showAgreement = false
    @State private var showSuccessAlert = false

    var body: some View {
        ZStack {
            Form {
                Section("Ваше имя") {
                    TextField("Имя автора", text: $name)
                }

                Section("Обращение") {
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Текст обращения")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $message)
                            .frame(minHeight: 150)
                    }
                }

                Section {
                    agreementRow
                }
            }

            if showAgreement {
                agreementOverlay
            }
        }
        .navigationTitle("Обратная связь")
        .safeAreaInset(edge: .bottom) {
            Button("Отправить") {
                submitFeedback()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .disabled(!isAgreed)
        }
        .alert("Обращение отправлено", isPresented: $showSuccessAlert) {
            Button("OK") {
                onSubmitted?()
            }
        } message: {
            Text("Спасибо, \(name). Мы свяжемся с вами в ближайшее время.")
        }
    }

    private var agreementRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                isAgreed.toggle()
            } label: {
                Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isAgreed ? .blue : .gray)
                    .font(.system(size: 22))
            }
            .buttonStyle(.plain)

            HStack(spacing: 0) {
                Text("Я согласен на ")
                    .foregroundStyle(.primary)
                Button("обработку данных") {
                    showAgreement = true
                }
                .foregroundStyle(.blue)
                .fontWeight(.medium)
            }
            .font(.body)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var agreementOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    showAgreement = false
                }

            VStack(spacing: 0) {
                HStack {
                    Text("Соглашение об обработке персональных данных")
                        .font(.headline)
                    Spacer()
                    Button {
                        showAgreement = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Divider()

                ScrollView {
                    Text(Self.agreementText)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(24)
            .shadow(radius: 12)
        }
    }

    private func submitFeedback() {
        guard isAgreed else { return }
        showSuccessAlert = true
    }

    private static let agreementText = """
    Настоящим вы подтверждаете согласие на обработку персональных данных, указанных в форме обратной связи.

    1. Оператор обрабатывает имя автора и текст обращения исключительно для ответа на запрос пользователя.
    2. Данные не передаются третьим лицам без законных оснований.
    3. Пользователь вправе отозвать согласие, направив запрос через форму обратной связи.
    4. Срок хранения данных определяется внутренними правилами сервиса и не превышает срок, необходимый для обработки обращения.
    5. При отправке формы пользователь подтверждает достоверность предоставленной информации.

    Дополнительные положения могут быть уточнены в актуальной редакции политики конфиденциальности приложения.
    """
}
