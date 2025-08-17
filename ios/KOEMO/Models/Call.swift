import Foundation

// MARK: - Call Model

struct Call: Codable, Identifiable {
    let id: String
    let participants: CallParticipants
    let timeline: CallTimeline
    let status: CallStatus
    let endReason: CallEndReason?
    let quality: CallQuality?
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "callId"
        case participants
        case timeline
        case status
        case endReason
        case quality
        case expiresAt
    }
}

// MARK: - Call Participants

struct CallParticipants: Codable {
    let caller: CallParticipant
    let callee: CallParticipant
}

struct CallParticipant: Codable {
    let userId: String
    let nickname: String
    let profileRevealLevel: Int
    
    var revealedProfile: PartialProfile {
        return PartialProfile(level: profileRevealLevel)
    }
}

// MARK: - Call Timeline

struct CallTimeline: Codable {
    let matchedAt: Date?
    let startedAt: Date?
    let endedAt: Date?
    let duration: TimeInterval
    
    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Call Status

enum CallStatus: String, Codable {
    case pending = "pending"
    case connecting = "connecting"
    case active = "active"
    case ended = "ended"
    
    var displayName: String {
        switch self {
        case .pending: return "待機中"
        case .connecting: return "接続中"
        case .active: return "通話中"
        case .ended: return "終了"
        }
    }
}

// MARK: - Call End Reason

enum CallEndReason: String, Codable {
    case userHangup = "user_hangup"
    case networkError = "network_error"
    case timeout = "timeout"
    case partnerLeft = "partner_left"
    
    var displayName: String {
        switch self {
        case .userHangup: return "ユーザーが終了"
        case .networkError: return "ネットワークエラー"
        case .timeout: return "タイムアウト"
        case .partnerLeft: return "相手が切断"
        }
    }
}

// MARK: - Call Quality

struct CallQuality: Codable {
    let connectionType: String
    let avgLatency: Double
    let packetLoss: Double
}

// MARK: - Profile Disclosure

struct PartialProfile: Codable {
    let level: Int
    
    func shouldShowAge() -> Bool {
        return level >= 1  // 30秒後
    }
    
    func shouldShowRegion() -> Bool {
        return level >= 2  // 60秒後
    }
    
    func shouldShowFullProfile() -> Bool {
        return level >= 3  // 180秒後
    }
}

// MARK: - Call Request

struct CallRequest: Codable {
    let useTicket: Bool
}

// MARK: - Call Response

struct CallResponse: Codable {
    let success: Bool
    let data: CallData?
    let error: APIError?
}

struct CallData: Codable {
    let status: String
    let requestId: String?
    let estimatedWaitTime: Int?
    let callId: String?
    let partnerId: String?
    let partnerProfile: UserProfile?
    let signalData: SignalData?
}

struct SignalData: Codable {
    let peerId: String
    let token: String
    let ttl: Int
}