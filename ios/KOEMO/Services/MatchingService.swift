import Foundation

protocol MatchingServiceDelegate: AnyObject {
    func matchingDidStart()
    func matchingDidStop()
    func matchingDidFindMatch(partner: UserProfile, callId: String)
    func matchingDidFail(error: String)
}

class MatchingService: NSObject {
    static let shared = MatchingService()
    
    weak var delegate: MatchingServiceDelegate?
    
    private var isMatching = false
    private var currentCallId: String?
    private var currentPartner: UserProfile?
    
    override init() {
        super.init()
        WebSocketService.shared.addDelegate(self)
    }
    
    // MARK: - Matching Control
    
    func startMatching() {
        guard !isMatching else {
            print("Already matching")
            return
        }
        
        // Connect to WebSocket if needed
        if !WebSocketService.shared.isConnected {
            let token = UserDefaults.standard.string(forKey: "access_token") ?? ""
            WebSocketService.shared.connect(with: token)
        }
        
        isMatching = true
        WebSocketService.shared.startMatching()
        delegate?.matchingDidStart()
        
        print("🔍 Matching started - sending request to server...")
        
        // Get user profile for matching
        let nickname = UserDefaults.standard.string(forKey: "user_nickname") ?? "Unknown"
        let gender = UserDefaults.standard.string(forKey: "user_gender") ?? "unknown"
        let age = UserDefaults.standard.integer(forKey: "user_age")
        let region = UserDefaults.standard.string(forKey: "user_region")
        
        // Send matching request via WebSocket
        let matchingMessage: [String: Any] = [
            "type": "start-matching",
            "profile": [
                "nickname": nickname,
                "gender": gender,
                "age": age,
                "region": region ?? "Unknown"
            ]
        ]
        
        WebSocketService.shared.sendMessage(matchingMessage)
    }
    
    func stopMatching() {
        guard isMatching else {
            print("Not currently matching")
            return
        }
        
        isMatching = false
        WebSocketService.shared.stopMatching()
        delegate?.matchingDidStop()
        
        print("Stopped matching")
    }
    
    func acceptMatch(callId: String) {
        guard let currentCallId = currentCallId, currentCallId == callId else {
            print("Invalid call ID for accept")
            return
        }
        
        WebSocketService.shared.acceptMatch(callId: callId)
        print("Accepted match: \(callId)")
    }
    
    func cancelMatch(callId: String) {
        guard let currentCallId = currentCallId, currentCallId == callId else {
            print("Invalid call ID for cancel")
            return
        }
        
        WebSocketService.shared.cancelMatch(callId: callId)
        self.currentCallId = nil
        isMatching = false
        
        print("Cancelled match: \(callId)")
    }
    
    // MARK: - Testing Methods
    
    private func simulateMatchFound() {
        // Create a mock partner for testing
        let mockPartner = UserProfile(
            nickname: "テストパートナー",
            gender: .female,
            age: 25,
            region: "東京都"
        )
        
        let callId = "test_call_\(Int.random(in: 1000...9999))"
        
        print("🎯 Simulated match found!")
        
        // Update internal state
        isMatching = false
        currentCallId = callId
        currentPartner = mockPartner
        
        // Notify delegate
        delegate?.matchingDidFindMatch(partner: mockPartner, callId: callId)
    }
    
    // MARK: - Status
    
    func getMatchingStatus() -> Bool {
        return isMatching
    }
    
    func getCurrentCallId() -> String? {
        return currentCallId
    }
    
    func getCurrentPartner() -> UserProfile? {
        return currentPartner
    }
}

// MARK: - WebSocketServiceDelegate

extension MatchingService: WebSocketServiceDelegate {
    func webSocketDidConnect() {
        print("WebSocket connected - ready for matching")
    }
    
    func webSocketDidDisconnect() {
        if isMatching {
            isMatching = false
            delegate?.matchingDidStop()
        }
        currentCallId = nil
        print("WebSocket disconnected")
    }
    
    func webSocketDidReceiveMatchFound(partner: UserProfile, callId: String) {
        isMatching = false
        currentCallId = callId
        currentPartner = partner
        
        // Ensure delegate is called on main thread
        DispatchQueue.main.async {
            self.delegate?.matchingDidFindMatch(partner: partner, callId: callId)
        }
        
        print("Match found with \(partner.nickname), Call ID: \(callId)")
    }
    
    func webSocketDidReceiveMessage(_ message: Message) {
        // Forward to appropriate delegate or notification center
        NotificationCenter.default.post(
            name: NSNotification.Name("NewMessageReceived"),
            object: message
        )
    }
    
    func webSocketDidReceiveCallEnd(callId: String, duration: Int) {
        if currentCallId == callId {
            currentCallId = nil
        }
        
        // Forward to appropriate delegate or notification center
        NotificationCenter.default.post(
            name: NSNotification.Name("CallEnded"),
            object: ["callId": callId, "duration": duration]
        )
        
        print("Call ended: \(callId), Duration: \(duration)s")
    }
    
    func webSocketDidReceiveError(_ error: String) {
        if isMatching {
            DispatchQueue.main.async {
                self.delegate?.matchingDidFail(error: error)
            }
        }
        print("WebSocket error: \(error)")
    }
    
    func webSocketDidReceiveStartCall(matchId: String, roomId: String, partner: UserProfile, isInitiator: Bool) {
        print("MatchingService: Received start-call for \(matchId)")
        // This will be handled by the primary delegate (HomeViewController)
        // MatchingService just logs it
    }
    
    // MARK: - WebRTC Signaling Delegate Methods (Pass-through)
    
    func webSocketDidReceiveOffer(_ offer: [String: Any], from userId: String) {
        // This is handled by HomeViewController directly for WebRTC signaling
        print("MatchingService received WebRTC offer, but HomeViewController should handle this")
    }
    
    func webSocketDidReceiveAnswer(_ answer: [String: Any], from userId: String) {
        // This is handled by HomeViewController directly for WebRTC signaling
        print("MatchingService received WebRTC answer, but HomeViewController should handle this")
    }
    
    func webSocketDidReceiveIceCandidate(_ candidate: [String: Any], from userId: String) {
        // This is handled by HomeViewController directly for WebRTC signaling
        print("MatchingService received WebRTC ICE candidate, but HomeViewController should handle this")
    }
}