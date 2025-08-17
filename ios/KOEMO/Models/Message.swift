import Foundation

// MARK: - Message Model

struct Message: Codable, Identifiable {
    let id: String
    let callId: String
    let sender: MessageSender
    let receiver: MessageReceiver
    let content: MessageContent
    let status: MessageStatus
    let createdAt: Date
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "messageId"
        case callId
        case sender
        case receiver
        case content
        case status
        case createdAt
        case expiresAt
    }
    
    var isFromCurrentUser: Bool {
        // This would be determined by comparing sender.userId with current user
        return false // Placeholder
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - Message Sender/Receiver

struct MessageSender: Codable {
    let userId: String
    let nickname: String
}

struct MessageReceiver: Codable {
    let userId: String
    let nickname: String
}

// MARK: - Message Content

struct MessageContent: Codable {
    let text: String
    let type: MessageType
}

enum MessageType: String, Codable {
    case text = "text"
    case emoji = "emoji"
    case system = "system"
}

// MARK: - Message Status

struct MessageStatus: Codable {
    let sent: Bool
    let delivered: Bool
    let deliveredAt: Date?
}

// MARK: - Send Message Request

struct SendMessageRequest: Codable {
    let callId: String
    let recipientId: String
    let content: String
}

// MARK: - Message Response

struct MessageResponse: Codable {
    let success: Bool
    let data: MessageResponseData?
    let error: APIError?
}

struct MessageResponseData: Codable {
    let messageId: String
    let sentAt: Date
    let expiresAt: Date
}

// MARK: - Messages History Response

struct MessagesHistoryResponse: Codable {
    let success: Bool
    let data: MessagesHistoryData?
    let error: APIError?
}

struct MessagesHistoryData: Codable {
    let messages: [Message]
    let hasMore: Bool
}