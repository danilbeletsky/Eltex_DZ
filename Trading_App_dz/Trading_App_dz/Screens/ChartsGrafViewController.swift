import Foundation
import UIKit

final class ChartsGrafViewController: UIViewController {
    private let chartsLayer = CAShapeLayer()
    private let pointsLayer = CAShapeLayer()
    private let gridLayer = CAShapeLayer()
    private let selectedPointLayer = CAShapeLayer()
    private let currentPriceIndicatorView = UIView()

    private var graf: [CandleData] = []
    private var points: [CGPoint] = []
    private var selectedIndex: Int?
    private var liveUpdateTimer: Timer?

    private let priceLabels: [UILabel] = (0..<5).map { _ in UILabel() }
    private let timeLabels: [UILabel] = (0..<5).map { _ in UILabel() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayers()
        generateCandles()
        setupGridAndLabels()
        setupCurrentPriceIndicator()
        drawLineGraph()
        startLiveUpdates()
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

    private func setupCurrentPriceIndicator() {
        currentPriceIndicatorView.backgroundColor = .systemBlue
        currentPriceIndicatorView.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
        currentPriceIndicatorView.layer.cornerRadius = 6
        currentPriceIndicatorView.isUserInteractionEnabled = false
        view.addSubview(currentPriceIndicatorView)

        let pulseScale = CABasicAnimation(keyPath: "transform.scale")
        pulseScale.fromValue = 1.0
        pulseScale.toValue = 1.45
        pulseScale.duration = 0.8
        pulseScale.autoreverses = true
        pulseScale.repeatCount = .infinity

        let pulseAlpha = CABasicAnimation(keyPath: "opacity")
        pulseAlpha.fromValue = 1.0
        pulseAlpha.toValue = 0.5
        pulseAlpha.duration = 0.8
        pulseAlpha.autoreverses = true
        pulseAlpha.repeatCount = .infinity

        currentPriceIndicatorView.layer.add(pulseScale, forKey: "pulseScale")
        currentPriceIndicatorView.layer.add(pulseAlpha, forKey: "pulseAlpha")
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

    private func drawLineGraph(animated: Bool = false) {
        guard !graf.isEmpty else { return }

        points.removeAll()
        let layout = graphLayout

        var maxValue: Double = 0
        var minValue: Double = 1_000

        for candle in graf {
            if candle.high > maxValue { maxValue = candle.high }
            if candle.low < minValue { minValue = candle.low }
        }

        if maxValue == minValue { maxValue = minValue + 1 }

        let valueRange = maxValue - minValue
        let path = UIBezierPath()
        let oldPath = chartsLayer.path
        let oldIndicatorCenter = currentPriceIndicatorView.center
        let denominator = CGFloat(max(graf.count - 1, 1))

        for (index, candle) in graf.enumerated() {
            let x = layout.startX + (CGFloat(index) / denominator) * layout.graphWidth
            let y = layout.startY + CGFloat((maxValue - candle.high) / valueRange) * layout.graphHeight
            let point = CGPoint(x: x, y: y)
            points.append(point)

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        chartsLayer.path = path.cgPath
        if animated, let oldPath {
            let pathAnimation = CABasicAnimation(keyPath: "path")
            pathAnimation.fromValue = oldPath
            pathAnimation.toValue = path.cgPath
            pathAnimation.duration = 0.5
            pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            chartsLayer.add(pathAnimation, forKey: "lineMorph")
        }

        let pointsPath = UIBezierPath()
        for point in points {
            let rect = CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)
            pointsPath.append(UIBezierPath(ovalIn: rect))
        }
        pointsLayer.path = pointsPath.cgPath

        drawGridAndLabels(
            maxValue: maxValue,
            minValue: minValue,
            startX: layout.startX,
            startY: layout.startY,
            graphWidth: layout.graphWidth,
            graphHeight: layout.graphHeight
        )
        updateCurrentPriceIndicator(animated: animated, from: oldIndicatorCenter)
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

        let timePositions = [0, graf.count / 4, graf.count / 2, graf.count * 3 / 4, graf.count - 1]
        let timeDenominator = CGFloat(max(graf.count - 1, 1))

        for (i, position) in timePositions.enumerated() {
            guard position < graf.count else { continue }
            let x = startX + (CGFloat(position) / timeDenominator) * graphWidth

            gridPath.move(to: CGPoint(x: x, y: startY - 5))
            gridPath.addLine(to: CGPoint(x: x, y: startY + graphHeight + 5))

            timeLabels[i].text = "\(position + 1)"
            timeLabels[i].frame = CGRect(x: x - 15, y: startY + graphHeight + 5, width: 30, height: 16)
        }

        gridLayer.path = gridPath.cgPath
    }

    private func updateCurrentPriceIndicator(animated: Bool, from oldCenter: CGPoint) {
        guard let lastPoint = points.last else { return }

        if oldCenter == .zero || !animated {
            currentPriceIndicatorView.center = lastPoint
            return
        }

        currentPriceIndicatorView.center = oldCenter
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut]) {
            self.currentPriceIndicatorView.center = lastPoint
        }
    }

    private func startLiveUpdates() {
        liveUpdateTimer?.invalidate()
        liveUpdateTimer = Timer.scheduledTimer(
            timeInterval: 1.8,
            target: self,
            selector: #selector(addNewPoint),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func addNewPoint() {
        guard let last = graf.last else { return }

        let open = last.close
        let close = open + Double.random(in: -8...8)
        let high = max(open, close) + Double.random(in: 0.8...3.5)
        let low = min(open, close) - Double.random(in: 0.8...3.5)

        graf.append(CandleData(open: open, close: close, high: high, low: low))
        if graf.count > 36 {
            graf.removeFirst(graf.count - 36)
        }

        drawLineGraph(animated: true)
    }

    private var graphLayout: (startX: CGFloat, startY: CGFloat, graphWidth: CGFloat, graphHeight: CGFloat) {
        let startX: CGFloat = 50
        let startY: CGFloat = 80
        let graphWidth = max(view.bounds.width - 80, 220)
        let graphHeight: CGFloat = 300
        return (startX, startY, graphWidth, graphHeight)
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

    deinit {
        liveUpdateTimer?.invalidate()
    }
}
