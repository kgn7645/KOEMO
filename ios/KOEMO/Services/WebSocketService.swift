import Foundation
import WebRTC
// import SocketIO // Temporarily disabled for build testing

protocol WebSocketServiceDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect()
    func webSocketDidReceiveMatchFound(partner: UserProfile, callId: String)
    func webSocketDidReceiveMessage(_ message: Message)
    func webSocketDidReceiveCallEnd(callId: String, duration: Int)
    func webSocketDidReceiveError(_ error: String)
    func webSocketDidReceiveStartCall(matchId: String, roomId: String, partner: UserProfile, isInitiator: Bool)
    
    // WebRTC Signaling delegate methods
    func webSocketDidReceiveOffer(_ offer: [String: Any], from userId: String)
    func webSocketDidReceiveAnswer(_ answer: [String: Any], from userId: String)
    func webSocketDidReceiveIceCandidate(_ candidate: [String: Any], from userId: String)
}

class WebSocketService {
    static let shared = WebSocketService()
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    // WebSocket properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var isWebSocketConnected = false
    private var currentPartner: UserProfile?
    
    private init() {
        print("WebSocketService initialized")
        urlSession = URLSession(configuration: .default)
    }
    
    // MARK: - Connection Management
    
    func connect(with token: String) {
        print("🔌 WebSocket: Connecting with userId: \(token)")
        
        // Use the correct WebSocket endpoint that matches the backend
        guard let url = URL(string: "ws://192.168.0.8:3000?token=\(token)") else {
            print("❌ Invalid WebSocket URL")
            notifyDelegates { $0.webSocketDidReceiveError("Invalid WebSocket URL") }
            return
        }
        
        self.webSocketTask = urlSession?.webSocketTask(with: url)
        
        webSocketTask?.resume()
        
        // Start listening for messages
        receiveMessage()
        
        // Check connection status
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.webSocketTask?.state == .running {
                print("✅ WebSocket connected successfully")
                self.isWebSocketConnected = true
                self.notifyDelegates { $0.webSocketDidConnect() }
            } else {
                print("❌ WebSocket connection failed")
                self.notifyDelegates { $0.webSocketDidReceiveError("Connection failed") }
            }
        }
    }
    
    func disconnect() {
        print("🔌 WebSocket: Disconnecting...")
        webSocketTask?.cancel(with: .goingAway, reason: Data())
        webSocketTask = nil
        isWebSocketConnected = false
        notifyDelegates { $0.webSocketDidDisconnect() }
    }
    
    var isConnected: Bool {
        return isWebSocketConnected
    }
    
    // MARK: - Message Handling
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] (result: Result<URLSessionWebSocketTask.Message, Error>) in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📨 WebSocket received: \(text)")
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📨 WebSocket received data: \(text)")
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // Continue listening
                self?.receiveMessage()
                
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self?.notifyDelegates { $0.webSocketDidReceiveError("Receive error: \(error.localizedDescription)") }
            }
        }
    }
    
    private func handleMessage(_ messageText: String) {
        print("📨 Processing message: \(messageText)")
        
        guard let data = messageText.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("❌ Invalid message format: \(messageText)")
            return
        }
        
        print("📨 Message type: \(type)")
        print("📨 Full JSON: \(json)")
        
        switch type {
        case "connected":
            print("✅ WebSocket connection confirmed")
        case "match-found":
            print("🎉 Match found message received")
            
            // Extract partner information from the match-found message
            var partnerNickname = "Unknown"
            var partnerGender = UserProfile.Gender.male
            var partnerAge: Int? = nil
            var partnerRegion: String? = nil
            var callId = "call_\(UUID().uuidString)"
            
            if let partner = json["partner"] as? [String: Any] {
                partnerNickname = partner["nickname"] as? String ?? "Unknown"
                
                if let genderString = partner["gender"] as? String {
                    switch genderString {
                    case "female":
                        partnerGender = .female
                    case "male":
                        partnerGender = .male
                    default:
                        partnerGender = .male
                    }
                }
                
                partnerAge = partner["age"] as? Int
                partnerRegion = partner["region"] as? String
            }
            
            if let matchId = json["matchId"] as? String {
                callId = matchId
            }
            
            print("🎉 Match found with: \(partnerNickname) (\(partnerGender), age: \(partnerAge ?? 0))")
            
            let partnerProfile = UserProfile(
                nickname: partnerNickname,
                gender: partnerGender,
                age: partnerAge,
                region: partnerRegion
            )
            
            // Store current partner for later use in start-call
            currentPartner = partnerProfile
            
            notifyDelegates { $0.webSocketDidReceiveMatchFound(partner: partnerProfile, callId: callId) }
        case "match_cancelled", "match-cancelled":
            print("❌ Match was cancelled")
        case "matching_started":
            print("🎯 Matching started")
        case "matching_stopped":
            print("🛑 Matching stopped")
        case "match_accepted":
            print("✅ Match accepted")
        case "call_ended":
            print("📴 Call ended")
        case "error":
            var errorMessage = "Unknown error"
            if let errorData = json["data"] as? [String: Any],
               let message = errorData["message"] as? String {
                errorMessage = message
            } else if let message = json["error"] as? String {
                errorMessage = message
            }
            print("❌ WebSocket error: \(errorMessage)")
            notifyDelegates { $0.webSocketDidReceiveError(errorMessage) }
            
        // WebRTC Signaling messages
        case "offer":
            handleWebRTCOffer(json)
        case "answer":
            handleWebRTCAnswer(json)
        case "ice-candidate":
            handleWebRTCIceCandidate(json)
        case "room-ready":
            print("🏠 Room is ready for WebRTC connection")
        case "joined-room":
            print("✅ Joined WebRTC room")
        case "start-call":
            print("📞 Start call message received")
            // Handle start-call message
            if let matchId = json["matchId"] as? String,
               let roomId = json["roomId"] as? String,
               let isInitiator = json["isInitiator"] as? Bool,
               let partner = currentPartner {
                print("📞 Starting WebRTC call - matchId: \(matchId), roomId: \(roomId), isInitiator: \(isInitiator)")
                notifyDelegates { $0.webSocketDidReceiveStartCall(matchId: matchId, roomId: roomId, partner: partner, isInitiator: isInitiator) }
            } else {
                print("❌ Missing information for start-call: matchId, roomId, isInitiator, or partner")
            }
        case "joined-room":
            print("✅ Joined WebRTC room successfully")
        case "room-ready":
            print("🏠 Room is ready - both participants joined")
        case "call-ended":
            print("📴 Call ended message received")
            let reason = json["reason"] as? String ?? "unknown"
            print("📴 Call ended reason: \(reason)")
            notifyDelegates { $0.webSocketDidReceiveCallEnd(callId: "", duration: 0) }
        
        default:
            print("❓ Unknown message type: \(type)")
        }
    }
    
    func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let text = String(data: data, encoding: .utf8) else {
            print("❌ Failed to serialize message")
            return
        }
        
        print("📤 WebSocket sending: \(text)")
        webSocketTask?.send(URLSessionWebSocketTask.Message.string(text)) { error in
            if let error = error {
                print("❌ WebSocket send error: \(error)")
            }
        }
    }
    
    // MARK: - Mock Event Simulation
    
    func simulateMatchFound() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let mockPartner = UserProfile(nickname: "テストユーザー", gender: .female, age: 25, region: "東京")
            let mockCallId = UUID().uuidString
            self.notifyDelegates { $0.webSocketDidReceiveMatchFound(partner: mockPartner, callId: mockCallId) }
        }
    }
    
    // MARK: - Matching Functions
    
    func startMatching() {
        print("🔍 WebSocket: Starting matching")
        let message: [String: Any] = [
            "type": "join_matching"
        ]
        sendMessage(message)
    }
    
    func stopMatching() {
        print("🛑 WebSocket: Stopping matching")
        let message: [String: Any] = [
            "type": "leave_matching"
        ]
        sendMessage(message)
    }
    
    func acceptMatch(callId: String) {
        print("✅ WebSocket: Accepting match \(callId)")
        let message: [String: Any] = [
            "type": "accept_match",
            "payload": ["callId": callId]
        ]
        sendMessage(message)
    }
    
    func cancelMatch(callId: String) {
        print("❌ WebSocket: Canceling match \(callId)")
        let message: [String: Any] = [
            "type": "cancel_match",
            "payload": ["callId": callId]
        ]
        sendMessage(message)
    }
    
    // MARK: - Call Functions
    
    func endCall(callId: String) {
        print("📴 WebSocket: Ending call \(callId)")
        let message: [String: Any] = [
            "type": "end_call",
            "payload": ["callId": callId]
        ]
        sendMessage(message)
        
        // Also leave WebRTC room
        leaveWebRTCRoom()
    }
    
    // MARK: - Message Functions (Stubbed)
    
    func sendMessage(receiverId: String, content: String) {
        print("WebSocket: Sending message to \(receiverId): \(content) (stubbed)")
    }
    
    // MARK: - WebRTC Signaling Message Handlers
    
    private func handleWebRTCOffer(_ json: [String: Any]) {
        print("📢 Received WebRTC offer")
        
        guard let offerSdp = json["offer"] as? String,
              let from = json["from"] as? String else {
            print("❌ Invalid offer format")
            return
        }
        
        // Convert SDP string to offer dictionary format
        let offer = ["sdp": offerSdp, "type": "offer"]
        notifyDelegates { $0.webSocketDidReceiveOffer(offer, from: from) }
    }
    
    private func handleWebRTCAnswer(_ json: [String: Any]) {
        print("📣 Received WebRTC answer")
        
        guard let answerSdp = json["answer"] as? String,
              let from = json["from"] as? String else {
            print("❌ Invalid answer format")
            return
        }
        
        // Convert SDP string to answer dictionary format
        let answer = ["sdp": answerSdp, "type": "answer"]
        notifyDelegates { $0.webSocketDidReceiveAnswer(answer, from: from) }
    }
    
    private func handleWebRTCIceCandidate(_ json: [String: Any]) {
        print("🧊 Received WebRTC ICE candidate")
        
        guard let candidate = json["candidate"] as? [String: Any],
              let from = json["from"] as? String else {
            print("❌ Invalid ICE candidate format")
            return
        }
        
        notifyDelegates { $0.webSocketDidReceiveIceCandidate(candidate, from: from) }
    }
    
    // MARK: - WebRTC Signaling Message Sending
    
    func joinWebRTCRoom(roomId: String) {
        let message: [String: Any] = [
            "type": "join-room",
            "roomId": roomId
        ]
        sendMessage(message)
    }
    
    func sendWebRTCOffer(_ offer: [String: Any], to roomId: String) {
        // Extract SDP string from offer dictionary
        let sdpString = offer["sdp"] as? String ?? ""
        
        let message: [String: Any] = [
            "type": "offer",
            "offer": sdpString,
            "to": roomId
        ]
        
        print("📤 Sending WebRTC offer with SDP length: \(sdpString.count)")
        sendMessage(message)
    }
    
    func sendWebRTCAnswer(_ answer: [String: Any], to roomId: String) {
        // Extract SDP string from answer dictionary
        let sdpString = answer["sdp"] as? String ?? ""
        
        let message: [String: Any] = [
            "type": "answer",
            "answer": sdpString,
            "to": roomId
        ]
        
        print("📤 Sending WebRTC answer with SDP length: \(sdpString.count)")
        sendMessage(message)
    }
    
    func sendWebRTCIceCandidate(_ candidate: [String: Any]) {
        let message: [String: Any] = [
            "type": "ice-candidate",
            "candidate": candidate
        ]
        sendMessage(message)
    }
    
    func leaveWebRTCRoom() {
        let message: [String: Any] = [
            "type": "leave-room"
        ]
        sendMessage(message)
    }
    
    func sendWebRTCSignal(targetUserId: String, signal: [String: Any]) {
        print("WebSocket: Sending WebRTC signal to \(targetUserId): \(signal) (stubbed)")
    }
    
    // MARK: - Delegate Management
    
    func addDelegate(_ delegate: WebSocketServiceDelegate) {
        delegates.add(delegate)
        print("🔌 Added delegate: \(type(of: delegate))")
    }
    
    func removeDelegate(_ delegate: WebSocketServiceDelegate) {
        delegates.remove(delegate)
        print("🔌 Removed delegate: \(type(of: delegate))")
    }
    
    private func notifyDelegates(_ block: (WebSocketServiceDelegate) -> Void) {
        delegates.allObjects.forEach { delegate in
            if let wsDelegate = delegate as? WebSocketServiceDelegate {
                block(wsDelegate)
            }
        }
    }
}