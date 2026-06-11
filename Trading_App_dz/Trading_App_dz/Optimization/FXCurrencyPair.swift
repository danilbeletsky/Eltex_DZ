import Foundation

struct FXCurrencyPair: Identifiable, Equatable {
    let id: UUID
    let name: String
    var value: Double
    var previousValue: Double
    var history: [Double]

    var changePercent: Double {
        guard previousValue != 0 else { return 0 }
        return (value - previousValue) / previousValue * 100
    }

    var isGrowing: Bool {
        value >= previousValue
    }
}

struct CurrencyPairsSnapshot: Equatable {
    let pairs: [FXCurrencyPair]
    let lastUpdatedPairs: [FXCurrencyPair]
    let updateCycle: Int
}
