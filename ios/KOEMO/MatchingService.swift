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
        WebSocketService.shared.delegate = self
    }
    
    // MARK: - Matching Control
    
    func startMatching() {
        guard !isMatching else {
            print("Already matching")
            return
        }
        
        // Connect to WebSocket if needed
        if !WebSocketService.shared.isConnected {
            WebSocketService.shared.connect()
        }
        
        isMatching = true
        WebSocketService.shared.startMatching()
        delegate?.matchingDidStart()
        
        print("🔍 Matching started - looking for partner...")
        
        // For testing: simulate finding a match after 3-5 seconds
        let delay = Double.random(in: 3.0...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if self.isMatching {
                self.simulateMatchFound()
            }
        }
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
            id: "mock_partner_123",
            nickname: "テストパートナー",
            age: 25,
            gender: "女性",
            prefecture: "東京都",
            profileImage: nil
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
        delegate?.matchingDidFindMatch(partner: partner, callId: callId)
        
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
            delegate?.matchingDidFail(error: error)
        }
        print("WebSocket error: \(error)")
    }
}