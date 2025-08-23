import UIKit
import SnapKit
import WebRTC

protocol MatchingViewControllerDelegate: AnyObject {
    func matchingDidCancel()
    func matchingDidFindMatch(partner: UserProfile)
}

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
    private var currentMatchId: String?
    private var hasAcceptedMatch = false
    
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
        print("🎯 MatchingViewController: Real matching process via WebSocket")
        // Real matching is handled via HomeViewController and WebSocket
        // This view controller just shows the UI
    }
    
    func setMatchInformation(partner: UserProfile, matchId: String) {
        print("📝 Setting match information: \(partner.nickname), matchId: \(matchId)")
        foundPartner = partner
        currentMatchId = matchId
        hasAcceptedMatch = false // リセット
        currentState = .found
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
        
        // 重複送信を防ぐ
        if hasAcceptedMatch {
            print("⚠️ Match already accepted, ignoring duplicate request")
            return
        }
        
        hasAcceptedMatch = true
        currentState = .confirmed
        stopAllTimers()
        
        print("✅ User accepted match, sending accept-match message...")
        
        // Send accept-match message to backend
        let acceptMessage: [String: Any] = [
            "type": "accept-match",
            "matchId": currentMatchId ?? "unknown_match"
        ]
        
        WebSocketService.shared.sendMessage(acceptMessage)
        
        // Update UI to show connecting state
        updateUIForConnecting()
        
        // Start connection timeout (30 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if self.currentState == .confirmed {
                // Connection timeout
                print("❌ WebRTC connection timeout")
                self.handleConnectionError("接続がタイムアウトしました")
            }
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
    
    private func updateUIForConnecting() {
        DispatchQueue.main.async {
            self.matchTitleLabel.text = "接続中..."
            self.confirmationLabel.text = "音声通話に接続しています"
            self.countdownLabel.text = ""
            
            // Hide action buttons during connection
            self.actionButtonsStackView.isHidden = true
            
            // Show loading animation
            self.startConnectingAnimation()
        }
    }
    
    private func startConnectingAnimation() {
        // Reuse the pulse animation for connecting state
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.pulseView.alpha = 0.6
        })
    }
    
    private func stopConnectingAnimation() {
        pulseView.layer.removeAllAnimations()
        pulseView.alpha = 0
    }
    
    private func handleConnectionError(_ message: String) {
        DispatchQueue.main.async {
            self.stopConnectingAnimation()
            
            let alert = UIAlertController(title: "接続エラー", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "再試行", style: .default) { _ in
                self.acceptButtonTapped()
            })
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { _ in
                self.delegate?.matchingDidCancel()
            })
            
            self.present(alert, animated: true)
        }
    }
    
    private func startCall(with partner: UserProfile, callId: String) {
        stopConnectingAnimation()
        
        let callVC = CallViewController(callId: callId, partner: partner, isInitiator: true)
        callVC.modalPresentationStyle = .fullScreen
        
        dismiss(animated: false) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(callVC, animated: true)
            }
        }
    }
}

// MARK: - WebRTCServiceDelegate

extension MatchingViewController: WebRTCServiceDelegate {
    func webRTCDidConnect() {
        print("✅ WebRTC connected, starting call")
        
        DispatchQueue.main.async {
            guard let partner = self.foundPartner else { return }
            
            // Get the call ID from WebRTCService
            let callId = "call_\(Int.random(in: 1000...9999))"
            self.startCall(with: partner, callId: callId)
        }
    }
    
    func webRTCDidDisconnect() {
        print("❌ WebRTC disconnected during matching")
        
        DispatchQueue.main.async {
            if self.currentState == .confirmed {
                self.handleConnectionError("接続が切断されました")
            }
        }
    }
    
    func webRTCDidReceiveRemoteAudioTrack(_ audioTrack: RTCAudioTrack) {
        print("🎵 Remote audio track received during matching")
        // This will be handled by CallViewController
    }
    
    func webRTCDidReceiveError(_ error: String) {
        print("❌ WebRTC error: \(error)")
        
        DispatchQueue.main.async {
            self.handleConnectionError("WebRTC エラー: \(error)")
        }
    }
    
    func webRTCDidGenerateIceCandidate(_ candidate: RTCIceCandidate) {
        print("🧊 ICE candidate generated during matching")
        // Handled by WebRTCService internally
    }
}