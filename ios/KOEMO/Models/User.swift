import Foundation

// MARK: - User Model

struct User: Codable {
    let id: String
    let deviceId: String
    let profile: UserProfile
    let status: UserStatus
    let tickets: TicketInfo
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case deviceId
        case profile
        case status
        case tickets
        case createdAt
        case updatedAt
    }
}

// MARK: - User Profile

struct UserProfile: Codable {
    let nickname: String
    let gender: Gender
    let age: Int?
    let region: String?
    
    enum Gender: String, Codable, CaseIterable {
        case male = "male"
        case female = "female"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .male: return "男性"
            case .female: return "女性"
            case .other: return "その他"
            }
        }
    }
}

// MARK: - User Status

struct UserStatus: Codable {
    let current: Status
    let lastActiveAt: Date
    
    enum Status: String, Codable {
        case online = "online"
        case offline = "offline"
        case calling = "calling"
        case matching = "matching"
        
        var displayName: String {
            switch self {
            case .online: return "オンライン"
            case .offline: return "オフライン"
            case .calling: return "通話中"
            case .matching: return "マッチング中"
            }
        }
    }
}

// MARK: - Ticket Info

struct TicketInfo: Codable {
    let balance: Int
    let freeCallsToday: Int
    let lastFreeCallAt: Date?
}

// MARK: - User Registration Request

struct UserRegistrationRequest: Codable {
    let deviceId: String
    let nickname: String
    let gender: String
    let age: Int
    let region: String?
}

// MARK: - Authentication Response

struct AuthenticationResponse: Codable {
    let success: Bool
    let data: AuthData?
    let error: APIError?
}

struct AuthData: Codable {
    let userId: String
    let accessToken: String
    let refreshToken: String
    let profile: UserProfile
}