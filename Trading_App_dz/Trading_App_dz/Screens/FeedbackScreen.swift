import SwiftUI

struct FeedbackScreen: View {
    @StateObject private var viewModel: FeedbackViewModel
    @FocusState private var focusedField: FeedbackViewModel.Field?

    init(onSubmitted: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: FeedbackViewModel(onSubmitted: onSubmitted))
    }

    var body: some View {
        ZStack {
            Form {
                Section("Ваше имя") {
                    TextField("Имя автора", text: $viewModel.name)
                        .focused($focusedField, equals: .name)
                    if let error = viewModel.displayedNameError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Обращение") {
                    ZStack(alignment: .topLeading) {
                        if viewModel.message.isEmpty {
                            Text("Текст обращения")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $viewModel.message)
                            .frame(minHeight: 150)
                            .focused($focusedField, equals: .message)
                    }
                    if let error = viewModel.displayedMessageError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    agreementRow
                    if let error = viewModel.displayedAgreementError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            if viewModel.showAgreement {
                agreementOverlay
            }
        }
        .navigationTitle("Обратная связь")
        .onChange(of: focusedField) { _, newValue in
            viewModel.setFocusedField(newValue)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    focusedField = nil
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Отправить") {
                focusedField = nil
                viewModel.submitFeedback()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .opacity(viewModel.canSubmit ? 1 : 0.45)
        }
        .alert("Обращение отправлено", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                viewModel.handleSuccessAlertDismissed()
            }
        } message: {
            Text("Спасибо, \(viewModel.trimmedName). Мы свяжемся с вами в ближайшее время.")
        }
    }

    private var agreementRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                viewModel.isAgreed.toggle()
            } label: {
                Image(systemName: viewModel.isAgreed ? "checkmark.square.fill" : "square")
                    .foregroundStyle(viewModel.isAgreed ? .blue : .gray)
                    .font(.system(size: 22))
            }
            .buttonStyle(.plain)

            HStack(spacing: 0) {
                Text("Я согласен на ")
                    .foregroundStyle(.primary)
                Button("обработку данных") {
                    viewModel.showAgreement = true
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
                    viewModel.showAgreement = false
                }

            VStack(spacing: 0) {
                HStack {
                    Text("Соглашение об обработке персональных данных")
                        .font(.headline)
                    Spacer()
                    Button {
                        viewModel.showAgreement = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Divider()

                ScrollView {
                    Text(viewModel.agreementText)
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
}
