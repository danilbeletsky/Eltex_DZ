import UIKit

final class SplashScreenViewController: UIViewController {
    private let logoImageView = UIImageView()
    private let loadingDuration: TimeInterval = 5.0
    private var didStartAnimation = false

    private let onFinishLoading: () -> Void

    init(onFinishLoading: @escaping () -> Void) {
        self.onFinishLoading = onFinishLoading
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStartAnimation else { return }
        didStartAnimation = true
        startLoadingFlow()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        logoImageView.image = UIImage(named: "logo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 240),
            logoImageView.heightAnchor.constraint(equalToConstant: 128)
        ])
    }

    private func startLoadingFlow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startLogoAnimation()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDuration) { [weak self] in
            self?.onFinishLoading()
        }
    }

    private func startLogoAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1.0
        rotation.repeatCount = .infinity

        let pulseAlpha = CABasicAnimation(keyPath: "opacity")
        pulseAlpha.fromValue = 1.0
        pulseAlpha.toValue = 0.35
        pulseAlpha.duration = 0.55
        pulseAlpha.autoreverses = true
        pulseAlpha.repeatCount = .infinity

        logoImageView.layer.add(rotation, forKey: "splashRotation")
        logoImageView.layer.add(pulseAlpha, forKey: "splashAlphaPulse")
    }
}
