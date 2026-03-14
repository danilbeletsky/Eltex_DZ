import UIKit
import Foundation

var balance: Double = 20000
let currency = "RUB"

var isPositionOpen = false
var buyPrice: Double = 0

for _ in 0..<10 {
    
    let price = Double.random(in: 1000...50000)
    
    if !isPositionOpen {
        
        let choice = Int.random(in: 0...2)
        
        if choice == 0 {
            print("\(String(format:"%.2f", price)) \(currency) - игнор")
        }else if choice == 1 {
            buyPrice = price
            isPositionOpen = true
            print("\(String(format:"%.2f",price)) \(currency) - покупка")
        }
    } else {
        let sellPrice = price
        let income = sellPrice - buyPrice
        
        balance += income
        
        print("\(String(format:"%.2f",price)) \(currency) - продажа")
        print("ПРОДАЖА FROM = \(String(format:"%.2f",buyPrice)) -> TO = \(String(format:"%.2f",sellPrice)), INCOME = \(String(format:"%.2f",income))")
        
        isPositionOpen = false
    }
}

print("Баланс: \(String(format:"%.2f",balance))")
