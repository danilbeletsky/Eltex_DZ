import SwiftUI

struct FeedbackScreen: View {
    @StateObject private var viewModel: FeedbackViewModel
    @FocusState private var focusedField: FeedbackViewModel.Field?

    private let themes = [
        "Проблема с выводом",
        "Проблема с ботом",
        "P2P продавец не отвечает",
        "Проблемы с обменом"
    ]

    init(onSubmitted: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: FeedbackViewModel(onSubmitted: onSubmitted))
    }

    var body: some View {
        ZStack {
            Form {
                Section("Ваше имя") {
                    TextField("Имя автора", text: $viewModel.name)
                        .focused($focusedField, equals: .name)
                    AnimatedValidationError(message: viewModel.displayedNameError)
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
                    AnimatedValidationError(message: viewModel.displayedMessageError)
                }

                Section("Направление обращения") {
                    UIKitPickerThemsView(
                        thems: themes,
                        selectedThemes: $viewModel.selectedThemes
                    )
                    .frame(height: CGFloat(themes.count) * 54)
                }

                Section {
                    agreementRow
                    AnimatedValidationError(message: viewModel.displayedAgreementError)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .disabled(viewModel.showBotCheck)
            .opacity(viewModel.showBotCheck ? 0.35 : 1)
            .animation(.easeInOut(duration: 0.3), value: viewModel.showBotCheck)

            if viewModel.showAgreement {
                agreementOverlay
            }

            if viewModel.showBotCheck {
                botCheckOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
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
            if !viewModel.showBotCheck {
                submitButton
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showBotCheck)
        .alert("Сообщение отправлено", isPresented: successAlertBinding) {
            Button("OK") {
                viewModel.dismissAlert()
            }
        }
        .alert("Проверка не пройдена, попробуйте еще раз", isPresented: failureAlertBinding) {
            Button("OK", role: .cancel) {
                viewModel.dismissAlert()
            }
        }
    }

    private var successAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.activeAlert == .submissionSucceeded },
            set: { isPresented in
                if !isPresented, viewModel.activeAlert == .submissionSucceeded {
                    viewModel.dismissAlert()
                }
            }
        )
    }

    private var failureAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.activeAlert == .botCheckFailed },
            set: { isPresented in
                if !isPresented, viewModel.activeAlert == .botCheckFailed {
                    viewModel.dismissAlert()
                }
            }
        )
    }

    private var submitButton: some View {
        Button("Отправить") {
            focusedField = nil
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.submitFeedback()
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .disabled(!viewModel.canSubmit)
        .opacity(viewModel.canSubmit ? 1 : 0.45)
        .animation(.easeInOut(duration: 0.25), value: viewModel.canSubmit)
    }

    private var botCheckOverlay: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Проверка на бота")
                .font(.title2.bold())

            Text("Следующая команда")
                .font(.headline)

            if let direction = viewModel.currentCommandDirection {
                Text(direction.commandTitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .id(direction.commandTitle + "\(viewModel.currentCommandIndex)")
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            BotSwipePad(
                isHighlighted: $viewModel.swipePadHighlighted,
                onSwipeEnded: { translation in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.handleSwipeEnded(translation: translation)
                    }
                }
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.97))
    }

    private var agreementRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isAgreed.toggle()
                }
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.showAgreement = true
                    }
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.showAgreement = false
                    }
                }

            VStack(spacing: 0) {
                HStack {
                    Text("Соглашение об обработке персональных данных")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.showAgreement = false
                        }
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

private struct AnimatedValidationError: View {
    let message: String?

    var body: some View {
        Group {
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        )
                    )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: message)
    }
}

private struct BotSwipePad: View {
    @Binding var isHighlighted: Bool
    let onSwipeEnded: (CGSize) -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                isHighlighted
                    ? Color.accentColor.opacity(0.3)
                    : Color(.secondarySystemFill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 1)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isHighlighted else { return }
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHighlighted = true
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHighlighted = false
                        }
                        onSwipeEnded(value.translation)
                    }
            )
            .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }
}
