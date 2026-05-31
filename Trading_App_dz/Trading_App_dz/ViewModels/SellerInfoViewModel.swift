import Foundation

final class SellerInfoViewModel {
    let title: String
    let subtitle: String
    let details: String

    init(offer: P2POffer) {
        title = offer.sellerName
        subtitle = "\(offer.pair.from)/\(offer.pair.to)"
        details = """
        Рейтинг: \(Int.random(in: 90...100))%
        Успешных сделок: \(Int.random(in: 400...5000))
        Среднее время ответа: \(Int.random(in: 1...8)) мин
        Курс: \(String(format: "%.6f", offer.rate)) \(offer.pair.to)
        Резерв: \(String(format: "%.2f", offer.reserve)) \(offer.pair.to)
        Верификация: Пройдена
        """
    }
}
