import Foundation
import AVFoundation
import WebRTC

protocol CallServiceDelegate: AnyObject {
    func callDidConnect()
    func callDidDisconnect()
    func callDidFail(error: String)
    func callDurationUpdated(duration: TimeInterval)
}

class CallService: NSObject {
    static let shared = CallService()
    
    weak var delegate: CallServiceDelegate?
    
    private var currentCallId: String?
    private var currentPartner: UserProfile?
    private var callStartTime: Date?
    private var callTimer: Timer?
    
    private var isInitiator = false
    
    override init() {
        super.init()
        setupNotifications()
        WebRTCService.shared.delegate = self
    }
    
    // MARK: - Call Management
    
    func startCall(callId: String, partner: UserProfile, isInitiator: Bool) {
        self.currentCallId = callId
        self.currentPartner = partner
        self.isInitiator = isInitiator
        
        // Setup WebRTC
        WebRTCService.shared.createPeerConnection(for: callId)
        
        // Setup call timer
        callStartTime = Date()
        startCallTimer()
        
        if isInitiator {
            // Create offer
            createAndSendOffer()
        }
    }
    
    func endCall() {
        guard let callId = currentCallId else { return }
        
        // Stop timer
        callTimer?.invalidate()
        callTimer = nil
        
        // Calculate duration
        let duration = Date().timeIntervalSince(callStartTime ?? Date())
        
        // Disconnect WebRTC
        WebRTCService.shared.disconnect()
        
        // Notify server
        WebSocketService.shared.endCall(callId: callId)
        
        // Clear call data
        currentCallId = nil
        currentPartner = nil
        callStartTime = nil
        
        delegate?.callDidDisconnect()
    }
    
    // MARK: - WebRTC Signaling
    
    private func createAndSendOffer() {
        WebRTCService.shared.createOffer { [weak self] sdp in
            guard let self = self, let sdp = sdp, let partnerId = self.currentPartner?.nickname else { return }
            
            let signal: [String: Any] = [
                "type": "offer",
                "sdp": sdp
            ]
            
            WebSocketService.shared.sendWebRTCSignal(
                targetUserId: partnerId,
                signal: signal
            )
        }
    }
    
    func handleWebRTCSignal(from userId: String, signal: [String: Any]) {
        guard let type = signal["type"] as? String else { return }
        
        switch type {
        case "offer":
            handleOffer(from: userId, sdp: signal["sdp"] as? String)
        case "answer":
            handleAnswer(from: userId, sdp: signal["sdp"] as? String)
        case "ice-candidate":
            handleIceCandidate(from: userId, candidate: signal)
        default:
            print("Unknown signal type: \(type)")
        }
    }
    
    private func handleOffer(from userId: String, sdp: String?) {
        guard let sdp = sdp else { return }
        
        WebRTCService.shared.setRemoteDescription(sdp: sdp, type: "offer") { [weak self] success in
            if success {
                self?.createAndSendAnswer(to: userId)
            }
        }
    }
    
    private func createAndSendAnswer(to userId: String) {
        WebRTCService.shared.createAnswer { [weak self] sdp in
            guard let sdp = sdp else { return }
            
            let signal: [String: Any] = [
                "type": "answer",
                "sdp": sdp
            ]
            
            WebSocketService.shared.sendWebRTCSignal(
                targetUserId: userId,
                signal: signal
            )
        }
    }
    
    private func handleAnswer(from userId: String, sdp: String?) {
        guard let sdp = sdp else { return }
        
        WebRTCService.shared.setRemoteDescription(sdp: sdp, type: "answer") { success in
            if !success {
                print("Failed to set remote answer")
            }
        }
    }
    
    private func handleIceCandidate(from userId: String, candidate: [String: Any]) {
        print("CallService: Handle ICE candidate from \(userId) (STUBBED)")
        // WebRTC functionality stubbed for testing
    }
    
    // MARK: - Audio Controls
    
    func setMicrophoneMuted(_ muted: Bool) {
        WebRTCService.shared.setMicrophoneMuted(muted)
    }
    
    func setSpeakerEnabled(_ enabled: Bool) {
        WebRTCService.shared.setSpeakerEnabled(enabled)
    }
    
    // MARK: - Timer
    
    private func startCallTimer() {
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let startTime = self?.callStartTime else { return }
            let duration = Date().timeIntervalSince(startTime)
            self?.delegate?.callDurationUpdated(duration: duration)
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIceCandidateGenerated(_:)),
            name: NSNotification.Name("WebRTCIceCandidateGenerated"),
            object: nil
        )
    }
    
    @objc private func handleIceCandidateGenerated(_ notification: Notification) {
        guard let candidateData = notification.object as? [String: Any],
              let partnerId = currentPartner?.nickname else { return }
        
        var signal = candidateData
        signal["type"] = "ice-candidate"
        
        WebSocketService.shared.sendWebRTCSignal(
            targetUserId: partnerId,
            signal: signal
        )
    }
    
    // MARK: - Call State
    
    func getCurrentCallId() -> String? {
        return currentCallId
    }
    
    func getCurrentPartner() -> UserProfile? {
        return currentPartner
    }
    
    func getCallDuration() -> TimeInterval {
        guard let startTime = callStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func isInCall() -> Bool {
        return currentCallId != nil
    }
}

// MARK: - WebRTCServiceDelegate

extension CallService: WebRTCServiceDelegate {
    func webRTCDidConnect() {
        delegate?.callDidConnect()
    }
    
    func webRTCDidDisconnect() {
        endCall()
    }
    
    func webRTCDidReceiveRemoteAudioTrack(_ audioTrack: RTCAudioTrack) {
        // Audio track is automatically played by WebRTC
        print("Received remote audio track: \(audioTrack)")
    }
    
    func webRTCDidReceiveError(_ error: String) {
        delegate?.callDidFail(error: error)
        endCall()
    }
    
    func webRTCDidGenerateIceCandidate(_ candidate: RTCIceCandidate) {
        print("Generated ICE candidate: \(candidate)")
        // ICE candidates are handled internally by WebRTCService
    }
}