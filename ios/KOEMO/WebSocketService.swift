import Foundation
// import SocketIO // Temporarily disabled for build testing

protocol WebSocketServiceDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect()
    func webSocketDidReceiveMatchFound(partner: UserProfile, callId: String)
    func webSocketDidReceiveMessage(_ message: Message)
    func webSocketDidReceiveCallEnd(callId: String, duration: Int)
    func webSocketDidReceiveError(_ error: String)
}

class WebSocketService {
    static let shared = WebSocketService()
    
    weak var delegate: WebSocketServiceDelegate?
    
    // Stubbed for build testing
    private var isWebSocketConnected = false
    
    private init() {
        print("WebSocketService initialized (stub version)")
    }
    
    // MARK: - Connection Management (Stubbed)
    
    func connect(with token: String) {
        print("WebSocket: Connecting with token (stubbed)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isWebSocketConnected = true
            self.delegate?.webSocketDidConnect()
        }
    }
    
    func disconnect() {
        print("WebSocket: Disconnecting (stubbed)")
        isWebSocketConnected = false
        delegate?.webSocketDidDisconnect()
    }
    
    var isConnected: Bool {
        return isWebSocketConnected
    }
    
    // MARK: - Mock Event Simulation
    
    func simulateMatchFound() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let mockPartner = UserProfile(nickname: "テストユーザー", gender: .female, age: 25, region: "東京")
            let mockCallId = UUID().uuidString
            self.delegate?.webSocketDidReceiveMatchFound(partner: mockPartner, callId: mockCallId)
        }
    }
    
    // MARK: - Matching Functions (Stubbed)
    
    func startMatching() {
        print("WebSocket: Starting matching (stubbed)")
        simulateMatchFound()
    }
    
    func stopMatching() {
        print("WebSocket: Stopping matching (stubbed)")
    }
    
    func acceptMatch(callId: String) {
        print("WebSocket: Accepting match \(callId) (stubbed)")
    }
    
    func cancelMatch(callId: String) {
        print("WebSocket: Canceling match \(callId) (stubbed)")
    }
    
    // MARK: - Call Functions (Stubbed)
    
    func endCall(callId: String) {
        print("WebSocket: Ending call \(callId) (stubbed)")
    }
    
    // MARK: - Message Functions (Stubbed)
    
    func sendMessage(receiverId: String, content: String) {
        print("WebSocket: Sending message to \(receiverId): \(content) (stubbed)")
    }
    
    // MARK: - WebRTC Signaling (Stubbed)
    
    func sendWebRTCSignal(targetUserId: String, signal: [String: Any]) {
        print("WebSocket: Sending WebRTC signal to \(targetUserId): \(signal) (stubbed)")
    }
}