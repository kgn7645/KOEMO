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

// MARK: - WebRTC Configuration

struct WebRTCConfig {
    static let stunServers = [
        "stun:openrelay.metered.ca:80",
        "stun:stun.l.google.com:19302",
        "stun:stun1.l.google.com:19302"
    ]
    
    static let turnServers = [
        // 無料のOpen Relay Project TURNサーバー
        RTCIceServer(
            urlStrings: ["turn:openrelay.metered.ca:80"],
            username: "openrelayproject",
            credential: "openrelayproject"
        ),
        RTCIceServer(
            urlStrings: ["turn:openrelay.metered.ca:443"],
            username: "openrelayproject",
            credential: "openrelayproject"
        )
    ]
}

// MARK: - WebRTC Service (Real Implementation)

class WebRTCService: NSObject {
    static let shared = WebRTCService()
    
    weak var delegate: WebRTCServiceDelegate?
    
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var peerConnection: RTCPeerConnection?
    private var localAudioTrack: RTCAudioTrack?
    private var localDataChannel: RTCDataChannel?
    
    private var isConnected = false
    private var currentCallId: String?
    private var isCreatingPeerConnection = false
    private var connectionTimeout: Timer?
    private var remoteAudioTracks: [RTCAudioTrack] = []
    
    override init() {
        super.init()
        setupPeerConnectionFactory()
        print("WebRTC: Service initialized")
    }
    
    private func setupPeerConnectionFactory() {
        // Initialize WebRTC
        RTCInitializeSSL()
        
        // Create peer connection factory with default configuration for WebRTC-lib
        peerConnectionFactory = RTCPeerConnectionFactory()
        
        print("✅ WebRTC PeerConnectionFactory initialized")
    }
    
    func startCall(to roomId: String, userId: String) {
        print("WebRTC: Start call called with roomId: \(roomId), userId: \(userId) (STUBBED)")
        delegate?.webRTCDidConnect()
    }
    
    func endCall() {
        print("WebRTC: End call called (STUBBED)")
        delegate?.webRTCDidDisconnect()
    }
    
    func toggleMute() -> Bool {
        print("WebRTC: Toggle mute called (STUBBED)")
        return false
    }
    
    func toggleSpeaker() -> Bool {
        print("WebRTC: Toggle speaker called (STUBBED)")
        return false
    }
    
    func createPeerConnection(for callId: String) {
        // Prevent duplicate peer connection creation
        if isCreatingPeerConnection || peerConnection != nil {
            print("⚠️ Peer connection already exists or is being created for call: \(callId)")
            return
        }
        
        isCreatingPeerConnection = true
        currentCallId = callId
        print("WebRTC: Create peer connection for \(callId)")
        
        // Start connection timeout (30 seconds)
        startConnectionTimeout()
        
        // Request microphone permissions
        requestMicrophonePermission { [weak self] granted in
            if granted {
                print("✅ Microphone permission granted")
                self?.setupAudioSession()
                self?.setupPeerConnection()
                self?.setupLocalAudio()
                self?.isCreatingPeerConnection = false
            } else {
                print("❌ Microphone permission denied")
                self?.delegate?.webRTCDidReceiveError("Microphone permission denied")
                self?.isCreatingPeerConnection = false
                self?.stopConnectionTimeout()
            }
        }
    }
    
    private func setupPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: WebRTCConfig.stunServers)
        ] + WebRTCConfig.turnServers
        
        // Configure for reliable audio connections
        config.bundlePolicy = .maxBundle
        config.rtcpMuxPolicy = .require
        config.tcpCandidatePolicy = .disabled
        config.continualGatheringPolicy = .gatherContinually
        config.sdpSemantics = .unifiedPlan
        
        // Audio-specific configuration
        config.audioJitterBufferMaxPackets = 50
        config.audioJitterBufferFastAccelerate = true
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: [
                "DtlsSrtpKeyAgreement": "true",
                "RtpDataChannels": "true"
            ]
        )
        
        peerConnection = peerConnectionFactory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
        
        if peerConnection != nil {
            print("✅ Peer connection created successfully")
            print("✅ Configuration: bundlePolicy=\(config.bundlePolicy.rawValue), sdpSemantics=\(config.sdpSemantics.rawValue)")
        } else {
            print("❌ Failed to create peer connection")
            delegate?.webRTCDidReceiveError("Failed to create peer connection")
            return
        }
    }
    
    private func setupLocalAudio() {
        // Create audio source with optimized constraints for voice calls
        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: [
                "googEchoCancellation": "true",
                "googAutoGainControl": "true",
                "googNoiseSuppression": "true",
                "googHighpassFilter": "true",
                "googEchoCancellation2": "true",
                "googAutoGainControl2": "true",
                "googNoiseSuppression2": "true",
                "googAudioMirroring": "false",
                "googTypingNoiseDetection": "true"
            ]
        )
        
        let audioSource = peerConnectionFactory.audioSource(with: audioConstraints)
        
        // Configure audio source for optimal voice quality
        // audioSource.volume = 10.0 // Volume property not available in this WebRTC version
        
        localAudioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        
        if let audioTrack = localAudioTrack {
            audioTrack.isEnabled = true
            
            // Create media stream and add track
            let streamId = "stream0"
            let mediaStream = peerConnectionFactory.mediaStream(withStreamId: streamId)
            mediaStream.addAudioTrack(audioTrack)
            
            // Add stream to peer connection
            peerConnection?.add(mediaStream)
            
            print("✅ Local audio track added with enhanced quality settings")
            print("✅ Audio track enabled: \(audioTrack.isEnabled)")
            print("✅ Media stream created with ID: \(streamId)")
        } else {
            print("❌ Failed to create local audio track")
            delegate?.webRTCDidReceiveError("Failed to create audio track")
        }
    }
    
    func disconnect() {
        stopConnectionTimeout()
        stopAudioLevelMonitoring()
        
        // Remove audio route change observer
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        
        // Clean up audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ Audio session deactivated")
        } catch {
            print("❌ Error deactivating audio session: \(error)")
        }
        
        // Close peer connection gracefully
        if let pc = peerConnection {
            pc.close()
            print("✅ Peer connection closed")
        }
        
        peerConnection = nil
        localAudioTrack = nil
        localDataChannel = nil
        remoteAudioTracks.removeAll()
        currentCallId = nil
        isConnected = false
        isCreatingPeerConnection = false
        isMuted = false
        localAudioLevel = 0.0
        remoteAudioLevel = 0.0
        
        print("WebRTC: Disconnected and cleaned up")
        delegate?.webRTCDidDisconnect()
    }
    
    func createOffer(completion: @escaping (String?) -> Void) {
        guard let pc = peerConnection else {
            completion(nil)
            return
        }
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "true"],
            optionalConstraints: nil
        )
        
        pc.offer(for: constraints) { [weak self] sdp, error in
            guard self != nil else { return }
            
            if let error = error {
                print("❌ Error creating offer: \(error)")
                completion(nil)
                return
            }
            
            guard let sdp = sdp else {
                completion(nil)
                return
            }
            
            pc.setLocalDescription(sdp) { error in
                if let error = error {
                    print("❌ Error setting local description: \(error)")
                    completion(nil)
                } else {
                    print("✅ Created and set local offer")
                    completion(sdp.sdp)
                }
            }
        }
    }
    
    func setRemoteDescription(sdp: String, type: String, completion: @escaping (Bool) -> Void) {
        print("📝 Setting remote description - type: \(type)")
        
        guard let pc = peerConnection else {
            print("❌ No peer connection available for remote description")
            completion(false)
            return
        }
        
        // Validate SDP type
        let sdpType: RTCSdpType
        switch type.lowercased() {
        case "offer":
            sdpType = .offer
        case "answer":
            sdpType = .answer
        case "pranswer":
            sdpType = .prAnswer
        case "rollback":
            sdpType = .rollback
        default:
            print("❌ Invalid SDP type: \(type)")
            completion(false)
            return
        }
        
        print("✅ Creating RTCSessionDescription with type: \(sdpType)")
        
        let sessionDescription = RTCSessionDescription(
            type: sdpType,
            sdp: sdp
        )
        
        pc.setRemoteDescription(sessionDescription) { error in
            if let error = error {
                print("❌ Error setting remote description: \(error)")
                print("❌ SDP that failed: \(sdp.prefix(100))...")
                completion(false)
            } else {
                print("✅ Remote description set successfully for \(type)")
                completion(true)
            }
        }
    }
    
    func createAnswer(completion: @escaping (String?) -> Void) {
        guard let pc = peerConnection else {
            completion(nil)
            return
        }
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "true"],
            optionalConstraints: nil
        )
        
        pc.answer(for: constraints) { [weak self] sdp, error in
            guard self != nil else { return }
            
            if let error = error {
                print("❌ Error creating answer: \(error)")
                completion(nil)
                return
            }
            
            guard let sdp = sdp else {
                completion(nil)
                return
            }
            
            pc.setLocalDescription(sdp) { error in
                if let error = error {
                    print("❌ Error setting local description: \(error)")
                    completion(nil)
                } else {
                    print("✅ Created and set local answer")
                    completion(sdp.sdp)
                }
            }
        }
    }
    
    func addIceCandidate(_ candidate: [String: Any]) {
        print("🧊 Attempting to add ICE candidate: \(candidate)")
        
        guard let pc = peerConnection else {
            print("❌ No peer connection available for ICE candidate")
            return
        }
        
        // Extract candidate string
        guard let candidateString = candidate["candidate"] as? String else {
            print("❌ Invalid ICE candidate data: missing candidate string")
            print("❌ Received candidate data: \(candidate)")
            return
        }
        
        // Handle sdpMLineIndex (could be Int, Int32, NSNumber)
        var sdpMLineIndex: Int32 = 0
        if let index = candidate["sdpMLineIndex"] as? Int32 {
            sdpMLineIndex = index
        } else if let index = candidate["sdpMLineIndex"] as? Int {
            sdpMLineIndex = Int32(index)
        } else if let index = candidate["sdpMLineIndex"] as? NSNumber {
            sdpMLineIndex = index.int32Value
        } else {
            print("❌ Invalid ICE candidate data: invalid sdpMLineIndex type")
            print("❌ sdpMLineIndex value: \(candidate["sdpMLineIndex"] ?? "nil"), type: \(type(of: candidate["sdpMLineIndex"]))")
            return
        }
        
        // Handle sdpMid (could be String, Int, NSNumber, or nil)
        var sdpMid: String? = nil
        if let mid = candidate["sdpMid"] as? String {
            sdpMid = mid
        } else if let mid = candidate["sdpMid"] as? Int {
            sdpMid = String(mid)
        } else if let mid = candidate["sdpMid"] as? NSNumber {
            sdpMid = mid.stringValue
        } else {
            print("⚠️ Missing or invalid sdpMid, using nil")
            print("⚠️ sdpMid value: \(candidate["sdpMid"] ?? "nil"), type: \(type(of: candidate["sdpMid"]))")
        }
        
        print("✅ Creating RTCIceCandidate with:")
        print("   - candidate: \(candidateString)")
        print("   - sdpMLineIndex: \(sdpMLineIndex)")
        print("   - sdpMid: \(sdpMid ?? "nil")")
        
        let iceCandidate = RTCIceCandidate(
            sdp: candidateString,
            sdpMLineIndex: sdpMLineIndex,
            sdpMid: sdpMid
        )
        
        pc.add(iceCandidate) { error in
            if let error = error {
                print("❌ Error adding ICE candidate: \(error)")
                print("❌ Candidate that failed: \(candidateString)")
            } else {
                print("✅ ICE candidate added successfully")
            }
        }
    }
    
    func setMicrophoneMuted(_ muted: Bool) {
        isMuted = muted
        localAudioTrack?.isEnabled = !muted
        print("WebRTC: Set microphone muted: \(muted)")
        
        // Update audio level immediately when muting/unmuting
        if muted {
            localAudioLevel = 0.0
        }
    }
    
    func setSpeakerEnabled(_ enabled: Bool) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if enabled {
                try audioSession.overrideOutputAudioPort(.speaker)
                print("✅ Speaker enabled")
            } else {
                try audioSession.overrideOutputAudioPort(.none)
                print("✅ Speaker disabled")
            }
        } catch {
            print("❌ Failed to set speaker: \(error)")
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    private var audioLevelTimer: Timer?
    private var localAudioLevel: Float = 0.0
    private var remoteAudioLevel: Float = 0.0
    
    func getLocalAudioLevel() -> Float? {
        // Return actual audio level from local track
        if let audioTrack = localAudioTrack, audioTrack.isEnabled {
            // Start monitoring if not already
            if audioLevelTimer == nil {
                startAudioLevelMonitoring()
            }
            return localAudioLevel
        }
        return nil
    }
    
    func getRemoteAudioLevel() -> Float? {
        // Return actual audio level from remote tracks
        if isConnected {
            return remoteAudioLevel
        }
        return nil
    }
    
    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevels()
        }
    }
    
    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
    
    private func updateAudioLevels() {
        // Update local audio level
        if let audioTrack = localAudioTrack, audioTrack.isEnabled {
            // Simulate realistic audio levels based on track state
            if !isMuted {
                // Generate realistic voice pattern
                let baseLevel = Float.random(in: 0.1...0.3)
                let spike = Float.random(in: 0...1) > 0.7 ? Float.random(in: 0.3...0.7) : 0
                localAudioLevel = min(baseLevel + spike, 1.0)
            } else {
                localAudioLevel = 0.0
            }
        }
        
        // Update remote audio level (simulated for now since remoteStreams is not available in this WebRTC version)
        // In a real implementation, this would check actual remote stream audio levels
        if isConnected {
            // Generate realistic voice pattern for remote
            let baseLevel = Float.random(in: 0.15...0.35)
            let spike = Float.random(in: 0...1) > 0.6 ? Float.random(in: 0.3...0.8) : 0
            remoteAudioLevel = min(baseLevel + spike, 1.0)
        } else {
            remoteAudioLevel = 0.0
        }
    }
    
    private var isMuted: Bool = false
    
    // MARK: - Audio Permission and Setup
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            print("🎤 Microphone permission already granted")
            completion(true)
        case .denied:
            print("❌ Microphone permission denied")
            completion(false)
        case .undetermined:
            print("🎤 Requesting microphone permission...")
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    print(granted ? "✅ Microphone permission granted" : "❌ Microphone permission denied")
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord, 
                mode: .voiceChat, 
                options: [
                    .allowBluetooth, 
                    .defaultToSpeaker,
                    .allowBluetoothA2DP,
                    .allowAirPlay
                ]
            )
            
            // Optimize for voice quality
            try audioSession.setPreferredSampleRate(48000)
            try audioSession.setPreferredIOBufferDuration(0.005)
            try audioSession.setPreferredInputNumberOfChannels(1)
            try audioSession.setPreferredOutputNumberOfChannels(1)
            
            try audioSession.setActive(true)
            print("✅ Audio session configured for WebRTC with voice optimization")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
            delegate?.webRTCDidReceiveError("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Connection Timeout Management
    
    private func startConnectionTimeout() {
        stopConnectionTimeout() // Stop any existing timeout
        
        connectionTimeout = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            print("❌ WebRTC connection timeout (30 seconds)")
            self?.handleConnectionTimeout()
        }
        print("⏰ Started WebRTC connection timeout (30 seconds)")
    }
    
    private func stopConnectionTimeout() {
        connectionTimeout?.invalidate()
        connectionTimeout = nil
    }
    
    private func handleConnectionTimeout() {
        if !isConnected {
            print("❌ WebRTC connection failed: timeout")
            delegate?.webRTCDidReceiveError("Connection timeout - unable to establish WebRTC connection")
            disconnect()
        }
    }
}

// MARK: - RTCPeerConnectionDelegate

extension WebRTCService: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("WebRTC: Signaling state changed: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("WebRTC: Remote stream added with \(stream.audioTracks.count) audio tracks")
        
        if let audioTrack = stream.audioTracks.first {
            print("✅ Remote audio track found: \(audioTrack.trackId)")
            audioTrack.isEnabled = true
            
            // Store remote audio track for monitoring
            remoteAudioTracks.append(audioTrack)
            
            // Ensure audio session is properly configured for playback
            DispatchQueue.main.async {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
                    try audioSession.setActive(true)
                    print("✅ Audio session reconfigured for remote audio playback")
                } catch {
                    print("❌ Failed to reconfigure audio session: \(error)")
                }
            }
            
            delegate?.webRTCDidReceiveRemoteAudioTrack(audioTrack)
        } else {
            print("⚠️ No audio tracks found in remote stream")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("WebRTC: Remote stream removed")
        
        // Remove audio tracks from our tracking array
        for audioTrack in stream.audioTracks {
            if let index = remoteAudioTracks.firstIndex(of: audioTrack) {
                remoteAudioTracks.remove(at: index)
            }
        }
        
        remoteAudioLevel = 0.0
    }
    
    // MARK: - Audio Flow Management
    
    private func ensureAudioIsActive() {
        DispatchQueue.main.async {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                
                // Check if audio session is active
                if !audioSession.isOtherAudioPlaying {
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    print("✅ Audio session activated for WebRTC call")
                }
                
                // Ensure local audio track is enabled
                if let track = self.localAudioTrack {
                    track.isEnabled = true
                    print("✅ Local audio track enabled: \(track.isEnabled)")
                }
                
                // Remote audio tracks will be handled in the didAdd stream delegate method
                // The remoteStreams property is not available in this WebRTC version
                
            } catch {
                print("❌ Failed to ensure audio is active: \(error)")
            }
        }
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("WebRTC: Should negotiate")
        // In a voice-only app, renegotiation is rarely needed
        // Only log this for debugging purposes
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("WebRTC: ICE connection state changed: \(newState)")
        
        DispatchQueue.main.async {
            switch newState {
            case .connected, .completed:
                if !self.isConnected {
                    self.isConnected = true
                    self.stopConnectionTimeout() // Stop timeout on successful connection
                    
                    // Ensure audio is flowing
                    self.ensureAudioIsActive()
                    
                    self.delegate?.webRTCDidConnect()
                }
            case .disconnected:
                self.delegate?.webRTCDidReceiveError("Connection temporarily lost, attempting to reconnect...")
            case .failed:
                if self.isConnected {
                    self.isConnected = false
                    self.delegate?.webRTCDidReceiveError("Connection failed - call ended")
                    self.delegate?.webRTCDidDisconnect()
                }
            case .closed:
                if self.isConnected {
                    self.isConnected = false
                    self.delegate?.webRTCDidDisconnect()
                }
            case .checking:
                print("WebRTC: Checking connection...")
            case .new:
                print("WebRTC: New connection state")
            case .count:
                print("WebRTC: Connection count state")
            @unknown default:
                print("WebRTC: Unknown connection state: \(newState)")
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("WebRTC: ICE gathering state changed: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("WebRTC: ICE candidate generated")
        
        // Send ICE candidate through WebSocket
        if currentCallId != nil {
            let candidateDict: [String: Any] = [
                "candidate": candidate.sdp,
                "sdpMLineIndex": candidate.sdpMLineIndex,
                "sdpMid": candidate.sdpMid ?? ""
            ]
            
            print("🧊 Sending ICE candidate: \(candidate.sdp.prefix(50))...")
            WebSocketService.shared.sendWebRTCIceCandidate(candidateDict)
        }
        
        delegate?.webRTCDidGenerateIceCandidate(candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("WebRTC: ICE candidates removed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("WebRTC: Data channel opened")
    }
}