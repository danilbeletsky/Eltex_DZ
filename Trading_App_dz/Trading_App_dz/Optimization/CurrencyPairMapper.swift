import Foundation

struct FXCurrencyPairMetrics: Equatable {
    let volatility: Double
    let rsi: Double
    let valueAtRisk: Double
    let priceText: String
    let isGrowing: Bool
    let checksum: Int
}

struct CurrencyPairRowState: Identifiable, Equatable {
    let id: UUID
    let name: String
    let priceText: String
    let isGrowing: Bool
    let rsi: Double
    let volatility: Double
    let valueAtRisk: Double
    let isHighlighted: Bool
}

struct RecentPairCardState: Identifiable, Equatable {
    let id: UUID
    let name: String
    let priceText: String
    let changePercent: Double
    let isGrowing: Bool
    let checksum: Int
}

enum CurrencyPairMapper {
    static func mapRow(
        pair: FXCurrencyPair,
        metrics: FXCurrencyPairMetrics,
        highlightRisk: Bool,
        riskThreshold: Double = 0.12
    ) -> CurrencyPairRowState {
        CurrencyPairRowState(
            id: pair.id,
            name: pair.name,
            priceText: metrics.priceText,
            isGrowing: metrics.isGrowing,
            rsi: metrics.rsi,
            volatility: metrics.volatility,
            valueAtRisk: metrics.valueAtRisk,
            isHighlighted: highlightRisk && metrics.volatility > riskThreshold
        )
    }

    static func mapRecentCard(
        pair: FXCurrencyPair,
        metrics: FXCurrencyPairMetrics
    ) -> RecentPairCardState {
        RecentPairCardState(
            id: pair.id,
            name: pair.name,
            priceText: metrics.priceText,
            changePercent: pair.changePercent,
            isGrowing: metrics.isGrowing,
            checksum: metrics.checksum
        )
    }

    static func formatPrice(_ value: Double, fractionDigits: ClosedRange<Int>) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits.lowerBound
        formatter.maximumFractionDigits = fractionDigits.upperBound
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
