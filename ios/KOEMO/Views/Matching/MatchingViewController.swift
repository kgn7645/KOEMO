import UIKit
import SnapKit

class MatchingViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBackground
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "マッチング中..."
        label.font = .koemoTitle2
        label.textColor = .koemoText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var animationContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var pulseView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBlue.withAlphaComponent(0.3)
        view.layer.cornerRadius = 60
        view.alpha = 0
        return view
    }()
    
    private lazy var centerCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBlue
        view.layer.cornerRadius = 40
        return view
    }()
    
    private lazy var searchIconLabel: UILabel = {
        let label = UILabel()
        label.text = "👥"
        label.font = .systemFont(ofSize: 32)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "相手を探しています"
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var waitTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "予想待ち時間: 5秒"
        label.font = .koemoCaption1
        label.textColor = .koemoTertiaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var cancelButton: KoemoButton = {
        let button = KoemoButton(title: "キャンセル", style: .secondary, size: .medium)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Match confirmation views (hidden initially)
    private lazy var matchFoundView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBackground
        view.alpha = 0
        return view
    }()
    
    private lazy var matchTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "マッチしました！"
        label.font = .koemoTitle2
        label.textColor = .koemoGreen
        label.textAlignment = .center
        return label
    }()
    
    private lazy var partnerProfileView: ProfileView = {
        let profileView = ProfileView()
        return profileView
    }()
    
    private lazy var confirmationLabel: UILabel = {
        let label = UILabel()
        label.text = "この方と通話を\n始めますか？"
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var countdownLabel: UILabel = {
        let label = UILabel()
        label.text = "自動接続まで 10秒"
        label.font = .koemoCaption1
        label.textColor = .koemoTertiaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var actionButtonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Spacing.medium
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var skipButton: KoemoButton = {
        let button = KoemoButton(title: "スキップ", style: .secondary, size: .medium)
        button.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var acceptButton: KoemoButton = {
        let button = KoemoButton(title: "通話する", style: .primary, size: .medium)
        button.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    weak var delegate: MatchingViewControllerDelegate?
    private var matchingTimer: Timer?
    private var countdownTimer: Timer?
    private var countdownSeconds: Int = 10
    private var foundPartner: UserProfile?
    
    enum MatchingState {
        case searching
        case found
        case confirmed
    }
    
    private var currentState: MatchingState = .searching {
        didSet {
            updateUIForState()
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startMatchingAnimation()
        startMatchingProcess()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllTimers()
    }
    
    deinit {
        stopAllTimers()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.addSubview(backgroundView)
        backgroundView.addSubview(titleLabel)
        backgroundView.addSubview(animationContainerView)
        backgroundView.addSubview(statusLabel)
        backgroundView.addSubview(waitTimeLabel)
        backgroundView.addSubview(cancelButton)
        
        // Setup animation container
        animationContainerView.addSubview(pulseView)
        animationContainerView.addSubview(centerCircleView)
        centerCircleView.addSubview(searchIconLabel)
        
        // Setup match found view
        setupMatchFoundView()
        
        setupConstraints()
    }
    
    private func setupMatchFoundView() {
        view.addSubview(matchFoundView)
        
        matchFoundView.addSubview(matchTitleLabel)
        matchFoundView.addSubview(partnerProfileView)
        matchFoundView.addSubview(confirmationLabel)
        matchFoundView.addSubview(countdownLabel)
        matchFoundView.addSubview(actionButtonsStackView)
        
        actionButtonsStackView.addArrangedSubview(skipButton)
        actionButtonsStackView.addArrangedSubview(acceptButton)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Spacing.huge)
            make.centerX.equalToSuperview()
        }
        
        animationContainerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(120)
        }
        
        pulseView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(120)
        }
        
        centerCircleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(80)
        }
        
        searchIconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(animationContainerView.snp.bottom).offset(Spacing.large)
            make.centerX.equalToSuperview()
        }
        
        waitTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(Spacing.small)
            make.centerX.equalToSuperview()
        }
        
        cancelButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Spacing.extraLarge)
            make.centerX.equalToSuperview()
        }
        
        // Match found view constraints
        matchFoundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        matchTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Spacing.huge)
            make.centerX.equalToSuperview()
        }
        
        partnerProfileView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Spacing.large)
            make.height.equalTo(200)
        }
        
        confirmationLabel.snp.makeConstraints { make in
            make.top.equalTo(partnerProfileView.snp.bottom).offset(Spacing.large)
            make.centerX.equalToSuperview()
        }
        
        countdownLabel.snp.makeConstraints { make in
            make.top.equalTo(confirmationLabel.snp.bottom).offset(Spacing.medium)
            make.centerX.equalToSuperview()
        }
        
        actionButtonsStackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Spacing.extraLarge)
            make.left.right.equalToSuperview().inset(Spacing.large)
        }
    }
    
    // MARK: - State Management
    
    private func updateUIForState() {
        switch currentState {
        case .searching:
            showSearchingUI()
        case .found:
            showMatchFoundUI()
        case .confirmed:
            showConfirmedUI()
        }
    }
    
    private func showSearchingUI() {
        UIView.animate(withDuration: Animation.standard) {
            self.backgroundView.alpha = 1
            self.matchFoundView.alpha = 0
        }
    }
    
    private func showMatchFoundUI() {
        UIView.animate(withDuration: Animation.standard) {
            self.backgroundView.alpha = 0
            self.matchFoundView.alpha = 1
        }
        
        // Configure partner profile
        if let partner = foundPartner {
            partnerProfileView.configure(with: partner)
            partnerProfileView.showWithAnimation()
        }
        
        // Start countdown
        startCountdown()
    }
    
    private func showConfirmedUI() {
        acceptButton.setLoading(true)
        skipButton.isEnabled = false
        stopCountdown()
    }
    
    // MARK: - Matching Process
    
    private func startMatchingProcess() {
        // TODO: Send matching request to backend
        // For now, simulate finding a match after random delay
        let randomDelay = Double.random(in: 2.0...8.0)
        
        matchingTimer = Timer.scheduledTimer(withTimeInterval: randomDelay, repeats: false) { _ in
            self.simulateMatchFound()
        }
    }
    
    private func simulateMatchFound() {
        // Create mock partner
        foundPartner = UserProfile(
            nickname: "テストユーザー",
            gender: .female,
            age: 25,
            region: "東京都"
        )
        
        currentState = .found
    }
    
    // MARK: - Animation
    
    private func startMatchingAnimation() {
        // Pulse animation
        UIView.animate(withDuration: 1.5, delay: 0, options: [.repeat, .autoreverse]) {
            self.pulseView.alpha = 0.6
            self.pulseView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }
        
        // Rotation animation for center circle
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 2.0
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        centerCircleView.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    private func stopMatchingAnimation() {
        view.layer.removeAllAnimations()
        centerCircleView.layer.removeAllAnimations()
        pulseView.layer.removeAllAnimations()
    }
    
    // MARK: - Countdown
    
    private func startCountdown() {
        countdownSeconds = 10
        updateCountdownLabel()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.countdownSeconds -= 1
            self.updateCountdownLabel()
            
            if self.countdownSeconds <= 0 {
                self.autoAcceptMatch()
            }
        }
    }
    
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func updateCountdownLabel() {
        countdownLabel.text = "自動接続まで \(countdownSeconds)秒"
    }
    
    private func autoAcceptMatch() {
        acceptButtonTapped()
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        stopAllTimers()
        delegate?.matchingDidCancel()
    }
    
    @objc private func skipButtonTapped() {
        stopAllTimers()
        
        // TODO: Send skip request to backend and find new match
        // For now, just restart matching
        foundPartner = nil
        currentState = .searching
        startMatchingProcess()
    }
    
    @objc private func acceptButtonTapped() {
        guard let partner = foundPartner else { return }
        
        currentState = .confirmed
        
        // Simulate connection delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.delegate?.matchingDidFindMatch(partner: partner)
        }
    }
    
    // MARK: - Helper Methods
    
    private func stopAllTimers() {
        matchingTimer?.invalidate()
        matchingTimer = nil
        
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        stopMatchingAnimation()
    }
}