import UIKit
import SnapKit
import AVFoundation
import WebRTC

class CallViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBackground
        return view
    }()
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var callStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "通話中"
        label.font = .koemoBodyBold
        label.textColor = .koemoGreen
        label.textAlignment = .center
        return label
    }()
    
    private lazy var callTimerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .koemoTimer
        label.textColor = .koemoText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var partnerProfileView: ProfileView = {
        let profileView = ProfileView()
        return profileView
    }()
    
    private lazy var profileDisclosureIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        view.layer.cornerRadius = CornerRadius.small
        return view
    }()
    
    private lazy var disclosureProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .koemoBlue
        progressView.trackTintColor = .koemoTertiaryBackground
        progressView.progress = 0.0
        return progressView
    }()
    
    private lazy var disclosureLabel: UILabel = {
        let label = UILabel()
        label.text = "30秒後に年齢が表示されます"
        label.font = .koemoCaption1
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        return label
    }()
    
    // Audio level indicators
    private lazy var audioLevelsView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        view.layer.cornerRadius = CornerRadius.medium
        return view
    }()
    
    private lazy var localAudioLevelView: AudioLevelIndicator = {
        let indicator = AudioLevelIndicator(title: "あなた")
        return indicator
    }()
    
    private lazy var remoteAudioLevelView: AudioLevelIndicator = {
        let indicator = AudioLevelIndicator(title: "相手")
        return indicator
    }()
    
    // Control buttons
    private lazy var controlsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var controlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()
    
    private lazy var muteButton: CallControlButton = {
        let button = CallControlButton(
            icon: "mic.fill",
            title: "ミュート",
            style: .mute
        )
        button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var speakerButton: CallControlButton = {
        let button = CallControlButton(
            icon: "speaker.wave.2.fill",
            title: "スピーカー",
            style: .speaker
        )
        button.addTarget(self, action: #selector(speakerButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var reportButton: CallControlButton = {
        let button = CallControlButton(
            icon: "exclamationmark.triangle.fill",
            title: "通報",
            style: .report
        )
        button.addTarget(self, action: #selector(reportButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var endCallButton: CallControlButton = {
        let button = CallControlButton(
            icon: "phone.down.fill",
            title: "終了",
            style: .endCall
        )
        button.addTarget(self, action: #selector(endCallButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    private var callTimer: Timer?
    private var disclosureTimer: Timer?
    private var callStartTime: Date?
    private var callDuration: TimeInterval = 0
    private var currentDisclosureLevel: Int = 0
    
    private var partnerProfile: UserProfile?
    private var callId: String?
    private var isMuted: Bool = false
    private var isSpeakerOn: Bool = false
    private var audioLevelTimer: Timer?
    
    // MARK: - Initialization
    
    init(callId: String, partner: UserProfile, isInitiator: Bool = false) {
        self.callId = callId
        self.partnerProfile = partner
        super.init(nibName: nil, bundle: nil)
        
        // Initialize WebRTC connection
        print("Initializing WebRTC for call: \(callId) with \(partner.nickname)")
        
        // Set WebRTCService delegate
        WebRTCService.shared.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startCall()
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
        backgroundView.addSubview(headerView)
        backgroundView.addSubview(partnerProfileView)
        backgroundView.addSubview(profileDisclosureIndicator)
        backgroundView.addSubview(audioLevelsView)
        backgroundView.addSubview(controlsContainerView)
        
        // Setup header
        headerView.addSubview(callStatusLabel)
        headerView.addSubview(callTimerLabel)
        
        // Setup disclosure indicator
        profileDisclosureIndicator.addSubview(disclosureProgressView)
        profileDisclosureIndicator.addSubview(disclosureLabel)
        
        // Setup audio levels
        audioLevelsView.addSubview(localAudioLevelView)
        audioLevelsView.addSubview(remoteAudioLevelView)
        
        // Setup controls
        controlsContainerView.addSubview(controlsStackView)
        [muteButton, speakerButton, reportButton, endCallButton].forEach {
            controlsStackView.addArrangedSubview($0)
        }
        
        setupConstraints()
        
        // Configure for call state
        configureForCallState()
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(100)
        }
        
        callStatusLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.medium)
            make.centerX.equalToSuperview()
        }
        
        callTimerLabel.snp.makeConstraints { make in
            make.top.equalTo(callStatusLabel.snp.bottom).offset(Spacing.small)
            make.centerX.equalToSuperview()
        }
        
        partnerProfileView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Spacing.large)
            make.height.equalTo(250)
        }
        
        profileDisclosureIndicator.snp.makeConstraints { make in
            make.top.equalTo(partnerProfileView.snp.bottom).offset(Spacing.large)
            make.left.right.equalToSuperview().inset(Spacing.large)
            make.height.equalTo(60)
        }
        
        audioLevelsView.snp.makeConstraints { make in
            make.top.equalTo(profileDisclosureIndicator.snp.bottom).offset(Spacing.medium)
            make.left.right.equalToSuperview().inset(Spacing.large)
            make.height.equalTo(80)
        }
        
        localAudioLevelView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.top.bottom.equalToSuperview().inset(Spacing.small)
            make.width.equalTo(120)
        }
        
        remoteAudioLevelView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.top.bottom.equalToSuperview().inset(Spacing.small)
            make.width.equalTo(120)
        }
        
        disclosureProgressView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.medium)
            make.left.right.equalToSuperview().inset(Spacing.medium)
            make.height.equalTo(4)
        }
        
        disclosureLabel.snp.makeConstraints { make in
            make.top.equalTo(disclosureProgressView.snp.bottom).offset(Spacing.small)
            make.centerX.equalToSuperview()
        }
        
        controlsContainerView.snp.makeConstraints { make in
            make.top.equalTo(audioLevelsView.snp.bottom).offset(Spacing.medium)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Spacing.large)
            make.left.right.equalToSuperview()
            make.height.greaterThanOrEqualTo(100)
        }
        
        controlsStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Spacing.large)
        }
    }
    
    private func configureForCallState() {
        // Configure audio session for call
        configureAudioSession()
        
        // Hide disclosure indicator initially
        profileDisclosureIndicator.alpha = 0
        
        // Set initial button states
        updateMuteButton()
        updateSpeakerButton()
    }
    
    // MARK: - Public Configuration
    
    func configure(with callInfo: [String: Any]) {
        callId = callInfo["callId"] as? String
        
        if let partnerNickname = callInfo["partnerNickname"] as? String {
            // Create mock partner profile
            partnerProfile = UserProfile(
                nickname: partnerNickname,
                gender: .female,
                age: 25,
                region: "東京都"
            )
        }
    }
    
    // MARK: - Call Management
    
    private func startCall() {
        callStartTime = Date()
        
        // Configure partner profile
        if let profile = partnerProfile {
            partnerProfileView.configure(with: profile)
            partnerProfileView.showWithAnimation()
        }
        
        // Start timers
        startCallTimer()
        startDisclosureTimer()
        startAudioLevelMonitoring()
        
        // Update call status
        callStatusLabel.text = "接続中..."
        callStatusLabel.textColor = .koemoSecondaryText
        
        // WebRTC connection should already be initialized from HomeViewController
        // Just wait for connection status updates via delegate
        print("📞 CallViewController ready - waiting for WebRTC connection status")
    }
    
    private func endCall() {
        stopAllTimers()
        
        // End WebRTC connection
        WebRTCService.shared.disconnect()
        
        // Notify call ended
        NotificationCenter.default.post(
            name: NSNotification.Name("CallDidEnd"),
            object: nil,
            userInfo: [
                "callId": callId ?? "",
                "duration": callDuration,
                "partnerProfile": partnerProfile as Any
            ]
        )
        
        // Dismiss call interface
        dismiss(animated: true)
    }
    
    // MARK: - Timer Management
    
    private func startCallTimer() {
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCallDuration()
        }
    }
    
    private func startDisclosureTimer() {
        disclosureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateProfileDisclosure()
        }
    }
    
    private func stopAllTimers() {
        callTimer?.invalidate()
        callTimer = nil
        
        disclosureTimer?.invalidate()
        disclosureTimer = nil
        
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
    
    private func updateCallDuration() {
        guard let startTime = callStartTime else { return }
        
        callDuration = Date().timeIntervalSince(startTime)
        
        let minutes = Int(callDuration) / 60
        let seconds = Int(callDuration) % 60
        callTimerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateProfileDisclosure() {
        guard let startTime = callStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let newLevel = calculateDisclosureLevel(elapsed: elapsed)
        
        if newLevel != currentDisclosureLevel {
            currentDisclosureLevel = newLevel
            partnerProfileView.updateDisclosureLevel(newLevel, animated: true)
            updateDisclosureUI(elapsed: elapsed)
        }
        
        updateDisclosureProgress(elapsed: elapsed)
    }
    
    private func calculateDisclosureLevel(elapsed: TimeInterval) -> Int {
        if elapsed >= 180 { return 3 } // Full profile
        if elapsed >= 60 { return 2 }  // + Region
        if elapsed >= 30 { return 1 }  // + Age
        return 0 // Nickname only
    }
    
    private func updateDisclosureUI(elapsed: TimeInterval) {
        var message = ""
        var shouldShow = true
        
        if elapsed < 30 {
            message = "30秒後に年齢が表示されます"
        } else if elapsed < 60 {
            message = "60秒後に地域が表示されます"
        } else if elapsed < 180 {
            message = "180秒後に全情報が表示されます"
        } else {
            shouldShow = false
        }
        
        disclosureLabel.text = message
        
        UIView.animate(withDuration: Animation.standard) {
            self.profileDisclosureIndicator.alpha = shouldShow ? 1.0 : 0.0
        }
    }
    
    private func updateDisclosureProgress(elapsed: TimeInterval) {
        let progress: Float
        
        if elapsed < 30 {
            progress = Float(elapsed / 30.0) * 0.33
        } else if elapsed < 60 {
            progress = 0.33 + Float((elapsed - 30) / 30.0) * 0.33
        } else if elapsed < 180 {
            progress = 0.66 + Float((elapsed - 60) / 120.0) * 0.34
        } else {
            progress = 1.0
        }
        
        disclosureProgressView.setProgress(progress, animated: true)
    }
    
    // MARK: - Audio Level Monitoring
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateAudioLevels()
        }
    }
    
    private func updateAudioLevels() {
        // Get actual local audio level from WebRTC
        if let localLevel = WebRTCService.shared.getLocalAudioLevel() {
            // Use actual WebRTC audio level
            localAudioLevelView.setLevel(localLevel)
        } else if callStatusLabel.text == "通話中" {
            // Only simulate if we're actually in a call but WebRTC levels aren't available yet
            let localLevel = isMuted ? 0.0 : Float.random(in: 0.1...0.8)
            localAudioLevelView.setLevel(localLevel)
        } else {
            // Not in call yet, show zero level
            localAudioLevelView.setLevel(0.0)
        }
        
        // Get actual remote audio level from WebRTC
        if let remoteLevel = WebRTCService.shared.getRemoteAudioLevel() {
            // Use actual WebRTC audio level
            remoteAudioLevelView.setLevel(remoteLevel)
        } else if callStatusLabel.text == "通話中" {
            // Only simulate if we're actually in a call but WebRTC levels aren't available yet
            let remoteLevel = Float.random(in: 0.0...0.6)
            remoteAudioLevelView.setLevel(remoteLevel)
        } else {
            // Not in call yet, show zero level
            remoteAudioLevelView.setLevel(0.0)
        }
    }
    
    // MARK: - Audio Management
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Actions
    
    @objc private func muteButtonTapped() {
        isMuted.toggle()
        updateMuteButton()
        
        // Mute/unmute WebRTC audio
        WebRTCService.shared.setMicrophoneMuted(isMuted)
        print("Microphone \(isMuted ? "muted" : "unmuted")")
    }
    
    @objc private func speakerButtonTapped() {
        isSpeakerOn.toggle()
        updateSpeakerButton()
        
        // Update audio route through WebRTC
        WebRTCService.shared.setSpeakerEnabled(isSpeakerOn)
        print("Speaker \(isSpeakerOn ? "enabled" : "disabled")")
    }
    
    @objc private func reportButtonTapped() {
        showReportAlert()
    }
    
    @objc private func endCallButtonTapped() {
        showEndCallConfirmation()
    }
    
    // MARK: - UI Updates
    
    private func updateMuteButton() {
        muteButton.configure(
            icon: isMuted ? "mic.slash.fill" : "mic.fill",
            title: isMuted ? "ミュート中" : "ミュート",
            style: isMuted ? .active : .mute
        )
    }
    
    private func updateSpeakerButton() {
        speakerButton.configure(
            icon: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2.fill",
            title: isSpeakerOn ? "イヤホン" : "スピーカー",
            style: isSpeakerOn ? .active : .speaker
        )
    }
    
    // MARK: - Alert Methods
    
    private func showReportAlert() {
        let alert = UIAlertController(title: "通報", message: "この通話を通報しますか？\nスクリーンショットが自動的に送信されます。", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "通報する", style: .destructive) { _ in
            self.reportCall()
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showEndCallConfirmation() {
        let alert = UIAlertController(title: "通話を終了", message: "通話を終了しますか？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "終了", style: .destructive) { _ in
            self.endCall()
        })
        
        alert.addAction(UIAlertAction(title: "続ける", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func reportCall() {
        // TODO: Implement report functionality
        // - Take screenshot
        // - Send report to backend
        
        let alert = UIAlertController(title: "通報完了", message: "通報を受け付けました。\n24時間以内に確認いたします。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - WebRTCServiceDelegate

extension CallViewController: WebRTCServiceDelegate {
    func webRTCDidReceiveRemoteAudioTrack(_ audioTrack: RTCAudioTrack) {
        print("✅ Received remote audio track - audio should now be playing")
        
        DispatchQueue.main.async {
            // Update UI to indicate audio is flowing
            self.callStatusLabel.text = "通話中"
            self.callStatusLabel.textColor = .koemoGreen
            
            // Ensure audio levels are being monitored
            if self.audioLevelTimer == nil {
                self.startAudioLevelMonitoring()
            }
        }
    }
    
    func webRTCDidReceiveError(_ error: String) {
        callDidFail(error: error)
    }
    
    func webRTCDidGenerateIceCandidate(_ candidate: RTCIceCandidate) {
        print("🧊 Generated ICE candidate (STUBBED)")
        // TODO: Send ICE candidate to signaling server
    }
    
    func webRTCDidConnect() {
        DispatchQueue.main.async {
            self.callStatusLabel.text = "通話中"
            self.callStatusLabel.textColor = .koemoGreen
            
            // Ensure profile view shows partner info
            if let partner = self.partnerProfile {
                self.partnerProfileView.configure(with: partner)
            }
            
            // Start audio level monitoring if not already started
            if self.audioLevelTimer == nil {
                self.startAudioLevelMonitoring()
            }
            
            print("🎉 WebRTC connection established - voice call active")
        }
    }
    
    func webRTCDidDisconnect() {
        DispatchQueue.main.async {
            self.callStatusLabel.text = "通話終了"
            self.callStatusLabel.textColor = .koemoSecondaryText
            
            // Stop audio level monitoring
            self.stopAllTimers()
            
            // Reset audio levels
            self.localAudioLevelView.setLevel(0.0)
            self.remoteAudioLevelView.setLevel(0.0)
            
            // Show call ended and dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dismiss(animated: true)
            }
        }
    }
    
    // Helper method for error handling
    private func callDidFail(error: String) {
        callStatusLabel.text = "接続エラー"
        callStatusLabel.textColor = .systemRed
        
        // Ensure view is loaded and in window hierarchy before presenting alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Check if we can present an alert
            if self.view.window != nil {
                let alert = UIAlertController(
                    title: "通話エラー",
                    message: error,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.dismiss(animated: true)
                })
                self.present(alert, animated: true)
            } else {
                // If we can't present alert, just dismiss
                print("❌ Cannot present alert - view not in window hierarchy")
                self.dismiss(animated: true)
            }
        }
    }
}

// MARK: - Call Control Button

class CallControlButton: UIButton {
    
    enum ButtonStyle {
        case mute
        case speaker
        case report
        case endCall
        case active
    }
    
    private var buttonStyle: ButtonStyle = .mute
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    convenience init(icon: String, title: String, style: ButtonStyle) {
        self.init(frame: .zero)
        configure(icon: icon, title: title, style: style)
    }
    
    private func setupButton() {
        titleLabel?.font = .koemoCaption2
        titleLabel?.numberOfLines = 0
        titleLabel?.textAlignment = .center
        
        // Make button circular
        layer.cornerRadius = 30
        
        // Add constraints
        snp.makeConstraints { make in
            make.size.equalTo(60)
        }
    }
    
    func configure(icon: String, title: String, style: ButtonStyle) {
        buttonStyle = style
        
        setImage(UIImage(systemName: icon), for: .normal)
        setTitle(title, for: .normal)
        
        // Arrange image and title vertically
        var configuration = UIButton.Configuration.plain()
        configuration.imagePlacement = .top
        configuration.imagePadding = 4
        self.configuration = configuration
        
        applyStyle()
    }
    
    private func applyStyle() {
        switch buttonStyle {
        case .mute:
            backgroundColor = .koemoSecondaryBackground
            tintColor = .koemoText
            setTitleColor(.koemoSecondaryText, for: .normal)
            
        case .speaker:
            backgroundColor = .koemoSecondaryBackground
            tintColor = .koemoText
            setTitleColor(.koemoSecondaryText, for: .normal)
            
        case .report:
            backgroundColor = .koemoWarning.withAlphaComponent(0.1)
            tintColor = .koemoWarning
            setTitleColor(.koemoWarning, for: .normal)
            
        case .endCall:
            backgroundColor = .koemoRed
            tintColor = .white
            setTitleColor(.white, for: .normal)
            
        case .active:
            backgroundColor = .koemoBlue
            tintColor = .white
            setTitleColor(.white, for: .normal)
        }
    }
}

// MARK: - Audio Level Indicator

class AudioLevelIndicator: UIView {
    
    private let titleLabel: UILabel
    private let levelBars: [UIView]
    private let numberOfBars = 5
    
    init(title: String) {
        titleLabel = UILabel()
        levelBars = (0..<5).map { _ in UIView() }
        
        super.init(frame: .zero)
        
        titleLabel.text = title
        titleLabel.font = .koemoCaption2
        titleLabel.textColor = .koemoSecondaryText
        titleLabel.textAlignment = .center
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        
        let barsContainer = UIStackView(arrangedSubviews: levelBars)
        barsContainer.axis = .horizontal
        barsContainer.distribution = .fillEqually
        barsContainer.spacing = 2
        
        addSubview(barsContainer)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(16)
        }
        
        barsContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        // Setup bars
        levelBars.enumerated().forEach { index, bar in
            bar.backgroundColor = .koemoTertiaryBackground
            bar.layer.cornerRadius = 1
            
            bar.snp.makeConstraints { make in
                make.height.equalTo(20 + index * 4) // Graduated heights
            }
        }
    }
    
    func setLevel(_ level: Float) {
        let activeBars = Int(level * Float(numberOfBars))
        
        levelBars.enumerated().forEach { index, bar in
            let isActive = index < activeBars
            UIView.animate(withDuration: 0.1) {
                bar.backgroundColor = isActive ? .koemoGreen : .koemoTertiaryBackground
            }
        }
    }
}