import Foundation
import SwiftUI
import UIKit
import Combine

struct FXCurrencyPair: Identifiable, Equatable {
    let id: UUID
    let name: String
    var value: Double
    var previousValue: Double
    var history: [Double]
    
    private(set) var cachedMetrics: Metrics?
    
    var changePercent: Double {
        guard previousValue != 0 else { return 0 }
        return (value - previousValue) / previousValue * 100
    }
    
    struct Metrics: Equatable {
        let price: AttributedString
        let volatility: Double
        let rsi: Double
        let valueAtRisk: Double
        let isGrowing: Bool
    }
    
    mutating func updateMetrics() {
        self.cachedMetrics = Metrics.calculate(for: self)
    }
}

extension FXCurrencyPair.Metrics {
    static func calculate(for pair: FXCurrencyPair) -> Self {
        let priceText = Self.priceFormatter.string(from: NSNumber(value: pair.value)) ?? "\(pair.value)"
        
        let attributedPrice = NSMutableAttributedString(
            string: priceText,
            attributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: pair.value >= pair.previousValue ? UIColor.systemGreen : UIColor.systemRed
            ]
        )
        
        let returns: [Double] = {
            guard pair.history.count > 1 else { return [] }
            var results = [Double]()
            for index in 1..<pair.history.count {
                let previous = max(pair.history[index - 1], 0.0001)
                results.append(log(pair.history[index] / previous))
            }
            return results
        }()
        
        let avgReturn = returns.reduce(0, +) / Double(max(returns.count, 1))
        let variance = returns.reduce(0) { $0 + pow($1 - avgReturn, 2) } / Double(max(returns.count, 1))
        let volatility = sqrt(variance) * sqrt(252)
        
        var gains = 0.0
        var losses = 0.0
        let startIndex = max(1, pair.history.count - 14)
        
        for index in startIndex..<pair.history.count {
            let diff = pair.history[index] - pair.history[index - 1]
            if diff >= 0 {
                gains += diff
            } else {
                losses += abs(diff)
            }
        }
        
        let rsi: Double = {
            guard losses > 0 else { return 100 }
            return 100 - 100 / (1 + (gains / losses))
        }()
        
        let valueAtRisk = calculateValueAtRisk(for: pair, volatility: volatility, avgReturn: avgReturn)
        
        return Self(
            price: AttributedString(attributedPrice),
            volatility: volatility,
            rsi: rsi,
            valueAtRisk: valueAtRisk,
            isGrowing: pair.value >= pair.previousValue
        )
    }
    
    private static func calculateValueAtRisk(for pair: FXCurrencyPair, volatility: Double, avgReturn: Double) -> Double {
        let simulations = 200
        var simulatedLosses = [Double](repeating: 0, count: simulations)
        
        for path in 0..<simulations {
            var simulatedPrice = pair.value
            for _ in 0..<30 {
                let noise = Double.random(in: -1...1)
                simulatedPrice *= exp(avgReturn + volatility * 0.02 * noise)
            }
            simulatedLosses[path] = pair.value - simulatedPrice
        }
        
        let sortedLosses = simulatedLosses.sorted()
        let index = min(sortedLosses.count - 1, Int(Double(sortedLosses.count) * 0.95))
        return sortedLosses[index]
    }
    
    static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 6
        return formatter
    }()
}

@MainActor
final class CurrencyPairsGenerator: ObservableObject {
    static let pairsCount = 500
    
    @Published private(set) var pairs: [FXCurrencyPair] = []
    @Published private(set) var lastUpdatedIDs: Set<UUID> = []
    @Published private(set) var updateCycle: Int = 0
    
    private var timer: Timer?
    
    init() {
        pairs = Self.makePairs()
        startUpdating()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startUpdating() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.updateRandomPairs()
        }
    }
    
    private func updateRandomPairs() {
        var updatedPairs = pairs
        let updateCount = Int.random(in: 8...35)
        var indexes = Set<Int>()
        
        while indexes.count < updateCount {
            indexes.insert(Int.random(in: updatedPairs.indices))
        }
        
        for index in indexes {
            updatedPairs[index].previousValue = updatedPairs[index].value
            updatedPairs[index].value = max(0.0001, updatedPairs[index].value * Double.random(in: 0.985...1.015))
            
            updatedPairs[index].history.append(updatedPairs[index].value)
            if updatedPairs[index].history.count > 240 {
                updatedPairs[index].history.removeFirst(updatedPairs[index].history.count - 240)
            }
            
            updatedPairs[index].updateMetrics()
        }
        
        pairs = updatedPairs
        lastUpdatedIDs = Set(indexes.map { updatedPairs[$0].id })
        updateCycle += 1
    }
    
    private static func makePairs() -> [FXCurrencyPair] {
        var result = [FXCurrencyPair]()
        result.reserveCapacity(pairsCount)
        
        for _ in 0..<pairsCount {
            var value = Double.random(in: 0.5...180)
            var history: [Double] = []
            history.reserveCapacity(120)
            
            for _ in 0..<120 {
                value = max(0.0001, value * Double.random(in: 0.995...1.005))
                history.append(value)
            }
            
            var pair = FXCurrencyPair(
                id: UUID(),
                name: "\(randomCode())/\(randomCode())",
                value: value,
                previousValue: history.dropLast().last ?? value,
                history: history,
                cachedMetrics: nil
            )
            pair.updateMetrics()
            result.append(pair)
        }
        
        return result
    }
    
    private static func randomCode() -> String {
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return String((0..<3).map { _ in letters.randomElement()! })
    }
}

struct RecentUpdatedPairsView: View {
    let lastUpdatedIDs: Set<UUID>
    let allPairs: [FXCurrencyPair]
    let updateCycle: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Последние обновления")
                .font(.headline)
                .padding(.horizontal, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(allPairs.filter { lastUpdatedIDs.contains($0.id) }) { pair in
                        RecentCurrencyPairCard(
                            pair: pair,
                            updateCycle: updateCycle
                        )
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

struct BadCurrencyPairsView: View {
    @StateObject private var generator = CurrencyPairsGenerator()
    @State private var highlightRisk: Bool = false
    
    var body: some View {
        LazyVStack(spacing: 0) {
            Toggle("Подсвечивать рискованные пары", isOn: $highlightRisk)
                .padding()
                .background(Color.gray.opacity(0.12))
            
            RecentUpdatedPairsView(
                lastUpdatedIDs: generator.lastUpdatedIDs,
                allPairs: generator.pairs,
                updateCycle: generator.updateCycle
            )
            
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(generator.pairs) { pair in
                        CurrencyPairRow(
                            pair: pair,
                            highlightRisk: highlightRisk
                        )
                        .id(pair.id)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }
}

struct CurrencyPairRow: View {
    let pair: FXCurrencyPair
    let highlightRisk: Bool
    
    var body: some View {
        guard let metrics = pair.cachedMetrics else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pair.name)
                        .font(.headline)
                    Text(metrics.price)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text("RSI \(metrics.rsi, specifier: "%.2f")")
                    Text("Vol \(metrics.volatility, specifier: "%.4f")")
                    Text("VaR \(metrics.valueAtRisk, specifier: "%.4f")")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        highlightRisk && metrics.volatility > 0.12
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
            .animation(.easeInOut(duration: 0.2), value: pair.value)
        )
    }
}

struct RecentCurrencyPairCard: View {
    let pair: FXCurrencyPair
    let updateCycle: Int
    
    var body: some View {
        guard let metrics = pair.cachedMetrics else {
            return AnyView(EmptyView())
        }
        
        let price = Self.cardFormatter.string(from: NSNumber(value: pair.value)) ?? "\(pair.value)"
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(pair.name)
                        .font(.caption.bold())
                    
                    Spacer()
                    
                    Circle()
                        .fill(metrics.isGrowing ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                }
                
                Text(price)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                
                Text("\(pair.changePercent, specifier: "%.2f")%")
                    .font(.caption)
                    .foregroundColor(metrics.isGrowing ? .green : .red)
                
                Text("cycle \(updateCycle)")
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
        )
    }
    
    static let cardFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 5
        return formatter
    }()
}

extension RecentUpdatedPairsView: Equatable {
    static func == (lhs: RecentUpdatedPairsView, rhs: RecentUpdatedPairsView) -> Bool {
        lhs.lastUpdatedIDs == rhs.lastUpdatedIDs && lhs.updateCycle == rhs.updateCycle
    }
}
