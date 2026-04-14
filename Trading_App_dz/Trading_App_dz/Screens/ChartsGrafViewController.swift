import Foundation
import UIKit

final class ChartsGrafViewController: UIViewController {
    private let chartsLayer: CAShapeLayer = CAShapeLayer()
    private let pointsLayer: CAShapeLayer = CAShapeLayer()
    private let gridLayer: CAShapeLayer = CAShapeLayer()
    private let selectedPointLayer: CAShapeLayer = CAShapeLayer()
    
    private var graf: [CandleData] = []
    private var points: [CGPoint] = []
    private var selectedIndex: Int?
    
    private let priceLabels: [UILabel] = (0..<5).map { _ in UILabel() }
    private let timeLabels: [UILabel] = (0..<5).map { _ in UILabel() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayers()
        generateCandles()
        setupGridAndLabels()
        drawLineGraph()
    }
    
    private func generateCandles() {
        graf = ChartsViewController.candles
    }
    
    private func setupLayers() {
        chartsLayer.strokeColor = UIColor.systemBlue.cgColor
        chartsLayer.fillColor = UIColor.clear.cgColor
        chartsLayer.lineWidth = 2
        
        pointsLayer.fillColor = UIColor.systemRed.cgColor
        pointsLayer.strokeColor = UIColor.systemRed.cgColor
        
        gridLayer.strokeColor = UIColor.systemGray.cgColor
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.lineWidth = 0.5
        
        selectedPointLayer.fillColor = UIColor.systemYellow.cgColor
        selectedPointLayer.strokeColor = UIColor.systemYellow.cgColor
        selectedPointLayer.lineWidth = 2
        
        view.layer.addSublayer(gridLayer)
        view.layer.addSublayer(chartsLayer)
        view.layer.addSublayer(pointsLayer)
        view.layer.addSublayer(selectedPointLayer)
    }
    
    private func setupGridAndLabels() {
        for label in priceLabels {
            label.font = .systemFont(ofSize: 12)
            label.textColor = .secondaryLabel
            label.textAlignment = .right
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
        }
        
        for label in timeLabels {
            label.font = .systemFont(ofSize: 12)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
        }
    }
    
    private func drawLineGraph() {
        guard !graf.isEmpty else { return }
        
        points.removeAll()
        
        let graphWidth = view.bounds.width - 80
        let graphHeight: CGFloat = 300
        let startX: CGFloat = 50
        let startY: CGFloat = 80
        
        var maxValue: Double = 0
        var minValue: Double = 1000
        
        for candle in graf {
            if candle.high > maxValue { maxValue = candle.high }
            if candle.low < minValue { minValue = candle.low }
        }
        
        if maxValue == minValue { maxValue = minValue + 1 }
        
        let valueRange = maxValue - minValue
        
        let path = UIBezierPath()
        
        for (index, candle) in graf.enumerated() {
            let x = startX + (CGFloat(index) / CGFloat(graf.count - 1)) * graphWidth
            let y = startY + CGFloat((maxValue - candle.high) / valueRange) * graphHeight
            let point = CGPoint(x: x, y: y)
            points.append(point)
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        chartsLayer.path = path.cgPath
        
        let pointsPath = UIBezierPath()
        for point in points {
            let rect = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
            pointsPath.append(UIBezierPath(ovalIn: rect))
        }
        pointsLayer.path = pointsPath.cgPath
        
        drawGridAndLabels(maxValue: maxValue, minValue: minValue, startX: startX, startY: startY, graphWidth: graphWidth, graphHeight: graphHeight)
    }
    
    private func drawGridAndLabels(maxValue: Double, minValue: Double, startX: CGFloat, startY: CGFloat, graphWidth: CGFloat, graphHeight: CGFloat) {
        let gridPath = UIBezierPath()
        
        let priceLevels: [Double] = [
            minValue,
            minValue + (maxValue - minValue) * 0.25,
            minValue + (maxValue - minValue) * 0.5,
            minValue + (maxValue - minValue) * 0.75,
            maxValue
        ]
        
        for (i, price) in priceLevels.enumerated() {
            let y = startY + CGFloat((maxValue - price) / (maxValue - minValue)) * graphHeight
            
            gridPath.move(to: CGPoint(x: startX - 5, y: y))
            gridPath.addLine(to: CGPoint(x: startX + graphWidth + 5, y: y))
            
            priceLabels[i].text = String(format: "%.1f", price)
            priceLabels[i].frame = CGRect(x: 0, y: y - 8, width: startX - 8, height: 16)
        }
        
        let timePositions = [0, graf.count/4, graf.count/2, graf.count * 3/4, graf.count - 1]
        
        for (i, position) in timePositions.enumerated() {
            guard position < graf.count else { continue }
            let x = startX + (CGFloat(position) / CGFloat(graf.count - 1)) * graphWidth
            
            gridPath.move(to: CGPoint(x: x, y: startY - 5))
            gridPath.addLine(to: CGPoint(x: x, y: startY + graphHeight + 5))
            
            timeLabels[i].text = "\(position + 1)"
            timeLabels[i].frame = CGRect(x: x - 15, y: startY + graphHeight + 5, width: 30, height: 16)
        }
        
        gridLayer.path = gridPath.cgPath
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: view)
        
        var minDistance: CGFloat = 50
        var closestIndex: Int?
        
        for (index, graphPoint) in points.enumerated() {
            let distance = hypot(point.x - graphPoint.x, point.y - graphPoint.y)
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }
        
        guard let index = closestIndex, index < graf.count else { return }
        selectedIndex = index
        
        let selectedPath = UIBezierPath()
        let center = points[index]
        let rect = CGRect(x: center.x - 8, y: center.y - 8, width: 16, height: 16)
        selectedPath.append(UIBezierPath(ovalIn: rect))
        selectedPointLayer.path = selectedPath.cgPath
        
        let selectedCandle = graf[index]
        let message = """
        Свеча №\(index + 1)
        Максимум: \(String(format: "%.2f", selectedCandle.high))
        Минимум: \(String(format: "%.2f", selectedCandle.low))
        Открытие: \(String(format: "%.2f", selectedCandle.open))
        Закрытие: \(String(format: "%.2f", selectedCandle.close))
        """
        
        let alert = UIAlertController(title: "Значение в точке", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        drawLineGraph()
    }
}
