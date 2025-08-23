import UIKit
import SnapKit
import WebRTC

class HomeViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var ticketLabel: UILabel = {
        let label = UILabel()
        label.text = "🎫 5"
        label.font = .koemoBodyBold
        label.textColor = .koemoText
        return label
    }()
    
    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "KOEMO"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .koemoBlue
        label.textAlignment = .center
        return label
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.tintColor = .koemoSecondaryText
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var mainContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var callButton: KoemoButton = {
        let button = KoemoButton(title: "📞\n話す", style: .call, size: .call)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(callButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "「誰かと話したい」\nそんな時にワンタップ"
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "オンライン中"
        label.font = .koemoCaption1
        label.textColor = .koemoGreen
        label.textAlignment = .center
        return label
    }()
    
    private lazy var quickStatsView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        view.layer.cornerRadius = CornerRadius.medium
        return view
    }()
    
    private lazy var statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()
    
    // MARK: - Properties
    
    private var currentTicketCount: Int = 5
    private var isMatching: Bool = false
    private var matchingViewController: MatchingViewController?
    private var currentCallId: String?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
        setupWebSocket()
        setupMatchingService()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUserStats()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateCallButton()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .koemoBackground
        title = ""
        
        // Add main components
        view.addSubview(headerView)
        view.addSubview(mainContentView)
        view.addSubview(quickStatsView)
        
        // Setup header
        headerView.addSubview(ticketLabel)
        headerView.addSubview(logoLabel)
        headerView.addSubview(settingsButton)
        
        // Setup main content
        mainContentView.addSubview(callButton)
        mainContentView.addSubview(descriptionLabel)
        mainContentView.addSubview(statusLabel)
        
        // Setup quick stats
        quickStatsView.addSubview(statsStackView)
        setupQuickStats()
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        
        ticketLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.centerY.equalToSuperview()
        }
        
        logoLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        settingsButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        
        mainContentView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(Spacing.large)
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
        }
        
        callButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(callButton.snp.bottom).offset(Spacing.large)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(Spacing.large)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(Spacing.medium)
            make.centerX.equalToSuperview()
        }
        
        quickStatsView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Spacing.large)
            make.left.right.equalToSuperview().inset(Spacing.medium)
            make.height.equalTo(80)
        }
        
        statsStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Spacing.medium)
        }
    }
    
    private func setupQuickStats() {
        let todayCallsLabel = createStatView(title: "今日の通話", value: "3回")
        let totalTimeLabel = createStatView(title: "総通話時間", value: "2時間")
        let availableCallsLabel = createStatView(title: "無料通話", value: "あと2回")
        
        [todayCallsLabel, totalTimeLabel, availableCallsLabel].forEach {
            statsStackView.addArrangedSubview($0)
        }
    }
    
    private func createStatView(title: String, value: String) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .koemoCaption2
        titleLabel.textColor = .koemoSecondaryText
        titleLabel.textAlignment = .center
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .koemoBodyBold
        valueLabel.textColor = .koemoText
        valueLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return containerView
    }
    
    // MARK: - Data Loading
    
    private func loadUserData() {
        // TODO: Load user data from API
        // For now, use mock data
        currentTicketCount = 5
        updateTicketDisplay()
    }
    
    private func refreshUserStats() {
        // TODO: Refresh user statistics
        // For now, mock refresh
        updateStatsDisplay()
    }
    
    private func updateTicketDisplay() {
        ticketLabel.text = "🎫 \(currentTicketCount)"
    }
    
    private func updateStatsDisplay() {
        // This would update the stats in the bottom view
        // For now, keeping static values
    }
    
    // MARK: - Actions
    
    @objc private func callButtonTapped() {
        guard !isMatching else { return }
        
        showCallOptionsAlert()
    }
    
    @objc private func settingsButtonTapped() {
        // Switch to settings tab
        if let tabBarController = tabBarController as? MainTabBarController {
            tabBarController.showSettings()
        }
    }
    
    private func showCallOptionsAlert() {
        let alert = UIAlertController(title: "通話を開始", message: "通話方法を選択してください", preferredStyle: .actionSheet)
        
        // Free call with ad
        alert.addAction(UIAlertAction(title: "広告を見て無料通話", style: .default) { _ in
            self.startCallWithAd()
        })
        
        // Ticket call (if available)
        if currentTicketCount > 0 {
            alert.addAction(UIAlertAction(title: "チケットを使って通話（残り\(currentTicketCount)枚）", style: .default) { _ in
                self.startCallWithTicket()
            })
        }
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = callButton
            popover.sourceRect = callButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func startCallWithAd() {
        // TODO: Show ad first, then start matching
        // For now, skip ad and go directly to matching
        startMatching(useTicket: false)
    }
    
    private func startCallWithTicket() {
        startMatching(useTicket: true)
    }
    
    private func startMatching(useTicket: Bool) {
        isMatching = true
        callButton.setLoading(true)
        
        // Present matching screen
        showMatchingInterface()
        
        // Start real matching through WebSocket service
        print("🎯 Starting real matching via WebSocket...")
        MatchingService.shared.startMatching()
    }
    
    private func setupWebSocket() {
        print("🔌 Setting up WebSocket connection...")
        
        // Get user token from UserDefaults
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            print("❌ No user ID found - cannot setup WebSocket")
            return
        }
        
        // Connect WebSocket with token
        WebSocketService.shared.addDelegate(self)
        WebSocketService.shared.connect(with: userId)
    }
    
    private func setupMatchingService() {
        print("🎯 Setting up MatchingService...")
        MatchingService.shared.delegate = self
    }
    
    private func startCall() {
        guard let callId = UserDefaults.standard.string(forKey: "current_call_id") else {
            print("No call ID found")
            return
        }
        
        // Get partner from last match
        guard let partner = UserDefaults.standard.object(forKey: "current_partner") as? [String: Any],
              let nickname = partner["nickname"] as? String,
              let genderStr = partner["gender"] as? String else {
            print("No partner info found")
            return
        }
        
        let gender = UserProfile.Gender(rawValue: genderStr) ?? .other
        let partnerProfile = UserProfile(
            nickname: nickname,
            gender: gender,
            age: partner["age"] as? Int,
            region: partner["region"] as? String
        )
        
        let callVC = CallViewController(callId: callId, partner: partnerProfile, isInitiator: true)
        callVC.modalPresentationStyle = .fullScreen
        present(callVC, animated: true)
    }
    
    // MARK: - Public Methods
    
    public func showMatchingInterface() {
        let matchingVC = MatchingViewController()
        matchingVC.delegate = self
        matchingVC.modalPresentationStyle = .fullScreen
        present(matchingVC, animated: true)
        matchingViewController = matchingVC
    }
    
    // MARK: - Animations
    
    private func animateCallButton() {
        // Subtle pulse animation for the call button
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.callButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            self.callButton.transform = .identity
        }
    }
}

// MARK: - MatchingViewControllerDelegate

extension HomeViewController: MatchingViewControllerDelegate {
    func matchingDidCancel() {
        // TODO: Stop MatchingService when services are added to project
        isMatching = false
        callButton.setLoading(false)
        currentCallId = nil // リセット
        matchingViewController?.dismiss(animated: true)
        matchingViewController = nil
    }
    
    func matchingDidFindMatch(partner: UserProfile) {
        // This will be handled by MatchingServiceDelegate instead
    }
}

// MARK: - WebRTCServiceDelegate

extension HomeViewController: WebRTCServiceDelegate {
    func webRTCDidConnect() {
        print("✅ WebRTC connected successfully")
    }
    
    func webRTCDidDisconnect() {
        print("❌ WebRTC disconnected")
    }
    
    func webRTCDidReceiveRemoteAudioTrack(_ audioTrack: RTCAudioTrack) {
        print("🎵 Received remote audio track")
    }
    
    func webRTCDidReceiveError(_ error: String) {
        print("❌ WebRTC error: \(error)")
    }
    
    func webRTCDidGenerateIceCandidate(_ candidate: RTCIceCandidate) {
        print("🧊 Generated ICE candidate")
    }
}

// MARK: - MatchingServiceDelegate

extension HomeViewController: MatchingServiceDelegate {
    func matchingDidStart() {
        print("Matching started")
    }
    
    func matchingDidStop() {
        isMatching = false
        callButton.setLoading(false)
        matchingViewController?.dismiss(animated: true)
        matchingViewController = nil
    }
    
    func matchingDidFindMatch(partner: UserProfile, callId: String) {
        DispatchQueue.main.async {
            print("🎉 Match found via MatchingService: \(partner.nickname)")
            // This is mainly handled by webSocketDidReceiveMatchFound
            // Just update UI state here to avoid duplicate processing
            self.isMatching = false
            self.callButton.setLoading(false)
        }
    }
    
    func matchingDidFail(error: String) {
        DispatchQueue.main.async {
            self.isMatching = false
            self.callButton.setLoading(false)
            
            let alert = UIAlertController(title: "マッチングエラー", message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - WebSocketServiceDelegate

extension HomeViewController: WebSocketServiceDelegate {
    func webSocketDidConnect() {
        print("✅ WebSocket connected")
    }
    
    func webSocketDidDisconnect() {
        print("❌ WebSocket disconnected")
    }
    
    func webSocketDidReceiveMatchFound(partner: UserProfile, callId: String) {
        print("🎉 Match found: \(partner.nickname), callId: \(callId)")
        DispatchQueue.main.async {
            // Update MatchingViewController with match information instead of dismissing it
            if let matchingVC = self.matchingViewController {
                matchingVC.setMatchInformation(partner: partner, matchId: callId)
            } else {
                print("⚠️ MatchingViewController not found, presenting CallViewController directly")
                self.presentCallViewController(partner: partner, callId: callId)
            }
        }
    }
    
    private func presentCallViewController(partner: UserProfile, callId: String) {
        print("📞 Presenting CallViewController for \(partner.nickname)")
        let callVC = CallViewController(callId: callId, partner: partner, isInitiator: false)
        callVC.modalPresentationStyle = .fullScreen
        
        // Find the top-most view controller
        var topController: UIViewController = self
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        print("📞 Top controller: \(type(of: topController))")
        topController.present(callVC, animated: true) {
            print("✅ CallViewController presented successfully")
        }
    }
    
    func webSocketDidReceiveMessage(_ message: Message) {
        // Handle other WebSocket messages
    }
    
    func webSocketDidReceiveCallEnd(callId: String, duration: Int) {
        print("📴 Call ended: \(callId), duration: \(duration)")
    }
    
    func webSocketDidReceiveError(_ error: String) {
        print("❌ WebSocket error: \(error)")
        DispatchQueue.main.async {
            self.isMatching = false
            self.callButton.setLoading(false)
        }
    }
    
    func webSocketDidReceiveStartCall(matchId: String, roomId: String, partner: UserProfile, isInitiator: Bool) {
        // Ensure all UI operations happen on main thread
        DispatchQueue.main.async {
            print("📞 Received start-call for matchId: \(matchId), roomId: \(roomId)")
            print("📞 Partner: \(partner.nickname), isInitiator: \(isInitiator)")
            print("📞 Current view controller: \(String(describing: self.presentedViewController))")
            
            // 重複を防ぐ：同じマッチIDの場合は無視
            if self.currentCallId == matchId {
                print("📞 Ignoring duplicate start-call for matchId: \(matchId)")
                return
            }
            
            self.currentCallId = matchId
            
            print("📞 Main thread: Joining WebRTC room and initializing connection...")
            
            // Join WebRTC room for signaling
            WebSocketService.shared.joinWebRTCRoom(roomId: roomId)
            
            // Initialize WebRTC connection
            WebRTCService.shared.createPeerConnection(for: roomId)
            WebRTCService.shared.delegate = self
            
            // If this user is the initiator, create an offer after peer connection is established
            if isInitiator {
                // Wait longer for peer connection to be fully established
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    print("🎯 Creating WebRTC offer as initiator...")
                    WebRTCService.shared.createOffer { offerSdp in
                        if let offerSdp = offerSdp {
                            print("✅ WebRTC offer created successfully")
                            print("📝 Offer SDP length: \(offerSdp.count) characters")
                            let offer = ["sdp": offerSdp, "type": "offer"]
                            WebSocketService.shared.sendWebRTCOffer(offer, to: roomId)
                            print("📤 WebRTC offer sent to room: \(roomId)")
                        } else {
                            print("❌ Failed to create WebRTC offer - peer connection may not be ready")
                        }
                    }
                }
            }
            
            print("📞 Main thread: Dismissing matching screen if present...")
            // Dismiss matching screen and present call interface
            // Dismiss matching view if present
            if let matchingVC = self.matchingViewController {
                matchingVC.dismiss(animated: false) {
                    self.matchingViewController = nil
                    self.proceedWithCall(matchId: matchId, roomId: roomId, partner: partner, isInitiator: isInitiator)
                }
            } else {
                self.proceedWithCall(matchId: matchId, roomId: roomId, partner: partner, isInitiator: isInitiator)
            }
        }
    }
    
    // MARK: - WebRTC Signaling Delegate Methods
    
    func webSocketDidReceiveOffer(_ offer: [String: Any], from userId: String) {
        print("📢 Received WebRTC offer from \(userId)")
        
        // Set remote description with offer
        if let sdpString = offer["sdp"] as? String {
            WebRTCService.shared.setRemoteDescription(sdp: sdpString, type: "offer") { success in
                if success {
                    print("✅ Remote offer set successfully, creating answer...")
                    
                    // Create and send answer
                    WebRTCService.shared.createAnswer { answerSdp in
                        if let answerSdp = answerSdp {
                            print("✅ Created answer, sending via WebSocket")
                            let answer = ["sdp": answerSdp, "type": "answer"]
                            WebSocketService.shared.sendWebRTCAnswer(answer, to: self.currentCallId ?? "")
                        } else {
                            print("❌ Failed to create answer")
                        }
                    }
                } else {
                    print("❌ Failed to set remote offer")
                }
            }
        }
    }
    
    func webSocketDidReceiveAnswer(_ answer: [String: Any], from userId: String) {
        print("📣 Received WebRTC answer from \(userId)")
        
        // Set remote description with answer
        if let sdpString = answer["sdp"] as? String {
            WebRTCService.shared.setRemoteDescription(sdp: sdpString, type: "answer") { success in
                if success {
                    print("✅ Remote answer set successfully - WebRTC connection should establish soon")
                } else {
                    print("❌ Failed to set remote answer")
                }
            }
        }
    }
    
    func webSocketDidReceiveIceCandidate(_ candidate: [String: Any], from userId: String) {
        print("🧊 Received ICE candidate from \(userId)")
        print("🧊 Candidate details: \(candidate)")
        WebRTCService.shared.addIceCandidate(candidate)
    }
    
    private func proceedWithCall(matchId: String, roomId: String, partner: UserProfile, isInitiator: Bool) {
        print("📞 Proceeding with call setup...")
        
        // Present CallViewController first
        let callVC = CallViewController(callId: matchId, partner: partner, isInitiator: isInitiator)
        callVC.modalPresentationStyle = .fullScreen
        
        self.present(callVC, animated: true) {
            print("✅ CallViewController presented")
            
            // Now set up WebRTC connection
            print("📞 Setting up WebRTC connection...")
            
            // Set delegates
            WebRTCService.shared.delegate = callVC
            
            // Join WebRTC room for signaling
            WebSocketService.shared.joinWebRTCRoom(roomId: roomId)
            
            // Create peer connection
            WebRTCService.shared.createPeerConnection(for: roomId)
            
            // If this user is the initiator, create an offer after peer connection is ready
            if isInitiator {
                print("📞 This user is the initiator - will create offer once peer connection is ready")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.createWebRTCOffer(roomId: roomId)
                }
            }
        }
    }
    
    private func createWebRTCOffer(roomId: String) {
        print("📞 Creating WebRTC offer...")
        WebRTCService.shared.createOffer { offerSdp in
            if let offerSdp = offerSdp {
                print("✅ Created offer, sending via WebSocket")
                let offer = ["sdp": offerSdp, "type": "offer"]
                WebSocketService.shared.sendWebRTCOffer(offer, to: roomId)
            } else {
                print("❌ Failed to create WebRTC offer")
            }
        }
    }
}