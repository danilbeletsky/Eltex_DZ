import SwiftUI

struct CurrenciesListView: View {
    @ObservedObject var viewModel: CurrenciesListViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Загрузка валютных пар...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                ContentUnavailableView(
                    "Нет данных",
                    systemImage: "dollarsign.circle",
                    description: Text("Валютные пары не найдены")
                )
            case .content(let content):
                currenciesContent(content)
            }
        }
        .onAppear { viewModel.send(.onAppear) }
        .onDisappear { viewModel.send(.onDisappear) }
    }

    @ViewBuilder
    private func currenciesContent(_ content: CurrenciesListViewState.Content) -> some View {
        LazyVStack(spacing: 0) {
            Toggle(
                "Подсвечивать рискованные пары",
                isOn: Binding(
                    get: { content.highlightRisk },
                    set: { viewModel.send(.setHighlightRisk($0)) }
                )
            )
            .padding()
            .background(Color.gray.opacity(0.12))

            RecentUpdatedPairsView(
                recentPairs: content.recentPairs,
                updateCycle: content.updateCycle
            )

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(content.rows) { row in
                        CurrencyPairRowView(row: row)
                            .animation(.easeInOut(duration: 0.2), value: row.priceText)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }
}

struct RecentUpdatedPairsView: View {
    let recentPairs: [RecentPairCardState]
    let updateCycle: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Последние обновления")
                .font(.headline)
                .padding(.horizontal, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentPairs) { pair in
                        RecentCurrencyPairCard(pair: pair, updateCycle: updateCycle)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .padding(.top, 12)
        .background(Color.black.opacity(0.04))
    }
}

struct CurrencyPairRowView: View {
    let row: CurrencyPairRowState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(row.name)
                    .font(.headline)

                Text(row.priceText)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(row.isGrowing ? .green : .red)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("RSI \(row.rsi, specifier: "%.2f")")
                Text("Vol \(row.volatility, specifier: "%.4f")")
                Text("VaR \(row.valueAtRisk, specifier: "%.4f")")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    row.isHighlighted
                        ? Color.yellow.opacity(0.45)
                        : Color.gray.opacity(0.12)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 8)
        .padding(.horizontal, 12)
    }
}

struct RecentCurrencyPairCard: View {
    let pair: RecentPairCardState
    let updateCycle: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pair.name)
                    .font(.caption.bold())

                Spacer()

                Circle()
                    .fill(pair.isGrowing ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }

            Text(pair.priceText)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))

            Text("\(pair.changePercent, specifier: "%.2f")%")
                .font(.caption)
                .foregroundColor(pair.isGrowing ? .green : .red)

            Text("cycle \(updateCycle) / \(pair.checksum)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 150, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 8)
    }
}
