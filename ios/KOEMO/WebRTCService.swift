import Foundation
import WebRTC
import AVFoundation

protocol WebRTCServiceDelegate: AnyObject {
    func webRTCDidConnect()
    func webRTCDidDisconnect()
    func webRTCDidReceiveRemoteAudioTrack(_ audioTrack: RTCAudioTrack)
    func webRTCDidReceiveError(_ error: String)
    func webRTCDidGenerateIceCandidate(_ candidate: RTCIceCandidate)
}

// MARK: - WebRTC Signaling Client

protocol WebRTCSignalingClientDelegate: AnyObject {
    func signalingClientDidConnect()
    func signalingClientDidDisconnect()
    func signalingClientDidJoinRoom(roomId: String, participantCount: Int)
    func signalingClientRoomReady(participants: [String])
    func signalingClientDidReceiveOffer(_ offer: String, from userId: String)
    func signalingClientDidReceiveAnswer(_ answer: String, from userId: String)
    func signalingClientDidReceiveIceCandidate(_ candidate: [String: Any], from userId: String)
    func signalingClientParticipantLeft(userId: String)
    func signalingClientDidReceiveError(_ error: String)
}

class WebRTCSignalingClient {
    static let shared = WebRTCSignalingClient()
    
    weak var delegate: WebRTCSignalingClientDelegate?
    
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var isConnected = false
    private var currentRoomId: String?
    private var userId: String?
    
    private let signalingURL = "ws://127.0.0.1:3000/signaling"
    
    private init() {
        print("✅ WebRTCSignalingClient initialized")
    }
    
    // MARK: - Connection Management
    
    func connect(userId: String) {
        self.userId = userId
        
        print("🔌 Connecting to signaling server as \(userId)...")
        
        // Create URLSession
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
        
        // Create WebSocket connection
        guard let url = URL(string: "\(signalingURL)?userId=\(userId)") else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        webSocket = urlSession?.webSocketTask(with: url)
        setupWebSocketHandlers()
        webSocket?.resume()
        
        // Start receiving messages
        receiveMessage()
    }
    
    func disconnect() {
        print("🔌 Disconnecting from signaling server...")
        
        if let roomId = currentRoomId {
            leaveRoom()
        }
        
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        urlSession = nil
        isConnected = false
        currentRoomId = nil
    }
    
    // MARK: - Room Management
    
    func joinRoom(_ roomId: String) {
        guard isConnected else {
            print("❌ Cannot join room: Not connected to signaling server")
            delegate?.signalingClientDidReceiveError("Not connected to signaling server")
            return
        }
        
        print("🏠 Joining room \(roomId)...")
        currentRoomId = roomId
        
        let message: [String: Any] = [
            "type": "join-room",
            "roomId": roomId
        ]
        sendMessage(message)
    }
    
    func leaveRoom() {
        guard let roomId = currentRoomId else { return }
        
        print("👋 Leaving room \(roomId)...")
        let message = ["type": "leave-room"]
        sendMessage(message)
        currentRoomId = nil
    }
    
    // MARK: - WebRTC Signaling
    
    func sendOffer(_ offer: String) {
        guard isConnected, currentRoomId != nil else {
            print("❌ Cannot send offer: Not in a room")
            return
        }
        
        print("📤 Sending offer...")
        let message: [String: Any] = [
            "type": "offer",
            "offer": offer
        ]
        sendMessage(message)
    }
    
    func sendAnswer(_ answer: String) {
        guard isConnected, currentRoomId != nil else {
            print("❌ Cannot send answer: Not in a room")
            return
        }
        
        print("📤 Sending answer...")
        let message: [String: Any] = [
            "type": "answer",
            "answer": answer
        ]
        sendMessage(message)
    }
    
    func sendIceCandidate(_ candidate: [String: Any]) {
        guard isConnected, currentRoomId != nil else {
            print("❌ Cannot send ICE candidate: Not in a room")
            return
        }
        
        print("🧊 Sending ICE candidate...")
        let message: [String: Any] = [
            "type": "ice-candidate",
            "candidate": candidate
        ]
        sendMessage(message)
    }
    
    // MARK: - WebSocket Handlers
    
    private func sendMessage(_ message: [String: Any]) {
        guard let webSocket = webSocket else { return }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: [])
            let string = String(data: data, encoding: .utf8)!
            webSocket.send(.string(string)) { error in
                if let error = error {
                    print("❌ WebSocket send error: \(error)")
                }
            }
        } catch {
            print("❌ Failed to serialize message: \(error)")
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self.handleDisconnection()
                
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self.receiveMessage()
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            print("❌ Failed to parse WebSocket message")
            return
        }
        
        guard let type = json["type"] as? String else {
            print("❌ WebSocket message missing type")
            return
        }
        
        switch type {
        case "connected":
            handleConnected(json)
        case "joined-room":
            handleJoinedRoom(json)
        case "room-ready":
            handleRoomReady(json)
        case "offer":
            handleOffer(json)
        case "answer":
            handleAnswer(json)
        case "ice-candidate":
            handleIceCandidate(json)
        case "participant-left":
            handleParticipantLeft(json)
        case "left-room":
            handleLeftRoom(json)
        case "error":
            handleError(json)
        default:
            print("⚠️ Unknown message type: \(type)")
        }
    }
    
    private func handleDisconnection() {
        isConnected = false
        currentRoomId = nil
        delegate?.signalingClientDidDisconnect()
    }
    
    private func setupWebSocketHandlers() {
        // Connection established, we'll get "connected" message
        isConnected = true
        delegate?.signalingClientDidConnect()
    }
    
    // MARK: - Message Handlers
    
    private func handleConnected(_ json: [String: Any]) {
        if let userId = json["userId"] as? String {
            print("✅ Signaling confirmed connection for user: \(userId)")
        }
    }
    
    private func handleJoinedRoom(_ json: [String: Any]) {
        if let roomId = json["roomId"] as? String,
           let participantCount = json["participantCount"] as? Int {
            print("✅ Joined room \(roomId) (\(participantCount)/2)")
            delegate?.signalingClientDidJoinRoom(roomId: roomId, participantCount: participantCount)
        }
    }
    
    private func handleRoomReady(_ json: [String: Any]) {
        if let participants = json["participants"] as? [String] {
            print("🎉 Room is ready with participants: \(participants)")
            delegate?.signalingClientRoomReady(participants: participants)
        }
    }
    
    private func handleOffer(_ json: [String: Any]) {
        if let offer = json["offer"] as? String,
           let from = json["from"] as? String {
            print("📥 Received offer from \(from)")
            delegate?.signalingClientDidReceiveOffer(offer, from: from)
        }
    }
    
    private func handleAnswer(_ json: [String: Any]) {
        if let answer = json["answer"] as? String,
           let from = json["from"] as? String {
            print("📥 Received answer from \(from)")
            delegate?.signalingClientDidReceiveAnswer(answer, from: from)
        }
    }
    
    private func handleIceCandidate(_ json: [String: Any]) {
        if let candidate = json["candidate"] as? [String: Any],
           let from = json["from"] as? String {
            print("🧊 Received ICE candidate from \(from)")
            delegate?.signalingClientDidReceiveIceCandidate(candidate, from: from)
        }
    }
    
    private func handleParticipantLeft(_ json: [String: Any]) {
        if let userId = json["userId"] as? String {
            print("👋 Participant left: \(userId)")
            delegate?.signalingClientParticipantLeft(userId: userId)
        }
    }
    
    private func handleLeftRoom(_ json: [String: Any]) {
        if let roomId = json["roomId"] as? String {
            print("✅ Left room \(roomId)")
        }
    }
    
    private func handleError(_ json: [String: Any]) {
        if let error = json["error"] as? String {
            print("❌ Server error: \(error)")
            delegate?.signalingClientDidReceiveError(error)
        }
    }
    
    // MARK: - Utility
    
    var connectionStatus: String {
        if isConnected {
            if let roomId = currentRoomId {
                return "Connected (Room: \(roomId))"
            }
            return "Connected"
        }
        return "Disconnected"
    }
}

class WebRTCService: NSObject {
    static let shared = WebRTCService()
    
    weak var delegate: WebRTCServiceDelegate?
    private let signalingClient = WebRTCSignalingClient.shared
    
    // MARK: - WebRTC Properties
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    private var localAudioTrack: RTCAudioTrack?
    private var audioSource: RTCAudioSource?
    private var audioSession = AVAudioSession.sharedInstance()
    
    private var isConnected = false
    private var currentCallId: String?
    
    // MARK: - ICE Servers Configuration
    private let iceServers = [
        RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
        RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"])
    ]
    
    override init() {
        super.init()
        setupPeerConnectionFactory()
        signalingClient.delegate = self
        print("✅ WebRTCService initialized with real WebRTC and signaling")
    }
    
    // MARK: - Setup
    
    private func setupPeerConnectionFactory() {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        peerConnectionFactory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
        
        print("✅ WebRTC: PeerConnectionFactory setup completed")
    }
    
    private func configureAudioSession() {
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: .allowBluetooth)
            try audioSession.setMode(.voiceChat)
            try audioSession.setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - Connection Management
    
    func createPeerConnection(for callId: String) {
        currentCallId = callId
        print("📞 WebRTC: Creating peer connection for callId: \(callId)")
        
        // Connect to signaling server
        let userId = UserDefaults.standard.string(forKey: "user_id") ?? "ios_user_\(UUID().uuidString.prefix(8))"
        signalingClient.connect(userId: userId)
        
        configureAudioSession()
        
        let configuration = RTCConfiguration()
        configuration.iceServers = iceServers
        configuration.bundlePolicy = .balanced
        configuration.rtcpMuxPolicy = .require
        configuration.tcpCandidatePolicy = .disabled
        configuration.candidateNetworkPolicy = .all
        configuration.keyType = .ECDSA
        configuration.sdpSemantics = .unifiedPlan
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: [
                "DtlsSrtpKeyAgreement": "true"
            ]
        )
        
        peerConnection = peerConnectionFactory.peerConnection(
            with: configuration,
            constraints: constraints,
            delegate: self
        )
        
        createLocalAudioTrack()
        print("✅ WebRTC: Peer connection created successfully")
    }
    
    private func createLocalAudioTrack() {
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        audioSource = peerConnectionFactory.audioSource(with: audioConstraints)
        localAudioTrack = peerConnectionFactory.audioTrack(with: audioSource!, trackId: "audio0")
        
        let streamId = "stream0"
        let mediaStream = peerConnectionFactory.mediaStream(withStreamId: streamId)
        mediaStream.addAudioTrack(localAudioTrack!)
        peerConnection?.add(mediaStream)
        
        print("✅ WebRTC: Local audio track created and added to stream")
    }
    
    // MARK: - Offer/Answer (Stubbed)
    
    func createOffer(completion: @escaping (String?) -> Void) {
        guard let peerConnection = peerConnection else {
            print("❌ WebRTC: No peer connection available for offer")
            completion(nil)
            return
        }
        
        print("📞 WebRTC: Creating offer...")
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: nil
        )
        
        peerConnection.offer(for: constraints) { [weak self] (sessionDescription, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ WebRTC: Failed to create offer: \(error)")
                    completion(nil)
                    return
                }
                
                guard let sdp = sessionDescription else {
                    print("❌ WebRTC: No SDP in offer")
                    completion(nil)
                    return
                }
                
                // Set local description
                peerConnection.setLocalDescription(sdp) { [weak self] error in
                    if let error = error {
                        print("❌ WebRTC: Failed to set local description: \(error)")
                        completion(nil)
                    } else {
                        print("✅ WebRTC: Offer created and local description set")
                        // Send offer through signaling
                        self?.signalingClient.sendOffer(sdp.sdp)
                        completion(sdp.sdp)
                    }
                }
            }
        }
    }
    
    func createAnswer(completion: @escaping (String?) -> Void) {
        guard let peerConnection = peerConnection else {
            print("❌ WebRTC: No peer connection available for answer")
            completion(nil)
            return
        }
        
        print("📞 WebRTC: Creating answer...")
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: nil
        )
        
        peerConnection.answer(for: constraints) { [weak self] (sessionDescription, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ WebRTC: Failed to create answer: \(error)")
                    completion(nil)
                    return
                }
                
                guard let sdp = sessionDescription else {
                    print("❌ WebRTC: No SDP in answer")
                    completion(nil)
                    return
                }
                
                // Set local description
                peerConnection.setLocalDescription(sdp) { [weak self] error in
                    if let error = error {
                        print("❌ WebRTC: Failed to set local description: \(error)")
                        completion(nil)
                    } else {
                        print("✅ WebRTC: Answer created and local description set")
                        // Send answer through signaling
                        self?.signalingClient.sendAnswer(sdp.sdp)
                        completion(sdp.sdp)
                    }
                }
            }
        }
    }
    
    func setRemoteDescription(sdp: String, type: String, completion: @escaping (Bool) -> Void) {
        guard let peerConnection = peerConnection else {
            print("❌ WebRTC: No peer connection available for remote description")
            completion(false)
            return
        }
        
        print("📞 WebRTC: Setting remote description of type \(type)")
        
        let sdpType: RTCSdpType
        switch type.lowercased() {
        case "offer":
            sdpType = .offer
        case "answer":
            sdpType = .answer
        case "pranswer":
            sdpType = .prAnswer
        default:
            print("❌ WebRTC: Unknown SDP type: \(type)")
            completion(false)
            return
        }
        
        let sessionDescription = RTCSessionDescription(type: sdpType, sdp: sdp)
        
        peerConnection.setRemoteDescription(sessionDescription) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ WebRTC: Failed to set remote description: \(error)")
                    completion(false)
                } else {
                    print("✅ WebRTC: Remote description set successfully")
                    completion(true)
                }
            }
        }
    }
    
    func addIceCandidate(candidate: String, sdpMLineIndex: Int32, sdpMid: String?) {
        guard let peerConnection = peerConnection else {
            print("❌ WebRTC: No peer connection available for ICE candidate")
            return
        }
        
        print("🧊 WebRTC: Adding ICE candidate: \(candidate)")
        
        let iceCandidate = RTCIceCandidate(
            sdp: candidate,
            sdpMLineIndex: sdpMLineIndex,
            sdpMid: sdpMid
        )
        
        peerConnection.add(iceCandidate)
        print("✅ WebRTC: ICE candidate added successfully")
    }
    
    // MARK: - Audio Control (Stubbed)
    
    func setMicrophoneMuted(_ muted: Bool) {
        localAudioTrack?.isEnabled = !muted
        print("WebRTC: Microphone \(muted ? "muted" : "unmuted")")
    }
    
    func setSpeakerEnabled(_ enabled: Bool) {
        do {
            try audioSession.overrideOutputAudioPort(enabled ? .speaker : .none)
            print("Speaker \(enabled ? "enabled" : "disabled")")
        } catch {
            print("Failed to set speaker: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    func disconnect() {
        print("🔌 WebRTC: Disconnecting...")
        
        // Disconnect from signaling server
        signalingClient.disconnect()
        
        // Close peer connection
        peerConnection?.close()
        peerConnection = nil
        
        // Clean up audio track
        localAudioTrack = nil
        audioSource = nil
        
        // Reset state
        isConnected = false
        currentCallId = nil
        
        // Deactivate audio session
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        delegate?.webRTCDidDisconnect()
        print("✅ WebRTC: Disconnected and cleaned up")
    }
    
    deinit {
        print("🗑️ WebRTC: Deinitializing service")
        disconnect()
    }
    
    // MARK: - Public Methods
    
    func joinRoom(_ roomId: String) {
        signalingClient.joinRoom(roomId)
    }
    
    func leaveRoom() {
        signalingClient.leaveRoom()
    }
    
    var isSignalingConnected: Bool {
        return signalingClient.connectionStatus.contains("Connected")
    }
}

// MARK: - RTCPeerConnectionDelegate

extension WebRTCService: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("WebRTC: Signaling state changed to \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("✅ WebRTC: Remote stream added")
        
        if let audioTrack = stream.audioTracks.first {
            DispatchQueue.main.async {
                self.delegate?.webRTCDidReceiveRemoteAudioTrack(audioTrack)
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("WebRTC: Remote stream removed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("WebRTC: ICE connection state changed to \(newState)")
        
        DispatchQueue.main.async {
            switch newState {
            case .connected:
                self.isConnected = true
                self.delegate?.webRTCDidConnect()
            case .disconnected, .failed, .closed:
                self.isConnected = false
                self.delegate?.webRTCDidDisconnect()
            default:
                break
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("WebRTC: ICE gathering state changed to \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("WebRTC: ICE candidate generated")
        
        // Send ICE candidate through signaling
        let candidateDict: [String: Any] = [
            "candidate": candidate.sdp,
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "sdpMid": candidate.sdpMid ?? ""
        ]
        signalingClient.sendIceCandidate(candidateDict)
        
        DispatchQueue.main.async {
            self.delegate?.webRTCDidGenerateIceCandidate(candidate)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("WebRTC: ICE candidates removed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("WebRTC: Data channel opened")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("WebRTC: Should negotiate")
        // This is called when negotiation is needed
    }
}

// MARK: - WebRTCSignalingClientDelegate

extension WebRTCService: WebRTCSignalingClientDelegate {
    func signalingClientDidConnect() {
        print("✅ WebRTC: Signaling connected")
        // Join room after connecting
        if let roomId = currentCallId {
            signalingClient.joinRoom(roomId)
        }
    }
    
    func signalingClientDidDisconnect() {
        print("❌ WebRTC: Signaling disconnected")
    }
    
    func signalingClientDidJoinRoom(roomId: String, participantCount: Int) {
        print("✅ WebRTC: Joined room \(roomId) (\(participantCount)/2)")
    }
    
    func signalingClientRoomReady(participants: [String]) {
        print("🎉 WebRTC: Room ready, can start call")
        // Room is ready, caller can create offer
    }
    
    func signalingClientDidReceiveOffer(_ offer: String, from userId: String) {
        print("📥 WebRTC: Received offer from \(userId)")
        
        // Set remote description
        setRemoteDescription(sdp: offer, type: "offer") { [weak self] success in
            if success {
                // Create answer
                self?.createAnswer { answer in
                    print("📤 WebRTC: Created and sent answer")
                }
            }
        }
    }
    
    func signalingClientDidReceiveAnswer(_ answer: String, from userId: String) {
        print("📥 WebRTC: Received answer from \(userId)")
        
        // Set remote description
        setRemoteDescription(sdp: answer, type: "answer") { success in
            if success {
                print("✅ WebRTC: Call established")
            }
        }
    }
    
    func signalingClientDidReceiveIceCandidate(_ candidate: [String: Any], from userId: String) {
        print("🧊 WebRTC: Received ICE candidate from \(userId)")
        
        guard let candidateSdp = candidate["candidate"] as? String,
              let sdpMLineIndex = candidate["sdpMLineIndex"] as? Int32,
              let sdpMid = candidate["sdpMid"] as? String else {
            print("❌ WebRTC: Invalid ICE candidate format")
            return
        }
        
        addIceCandidate(candidate: candidateSdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
    
    func signalingClientParticipantLeft(userId: String) {
        print("👋 WebRTC: Participant \(userId) left")
        delegate?.webRTCDidDisconnect()
    }
    
    func signalingClientDidReceiveError(_ error: String) {
        print("❌ WebRTC Signaling Error: \(error)")
        delegate?.webRTCDidReceiveError(error)
    }
}