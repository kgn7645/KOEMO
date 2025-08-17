import Foundation

// MARK: - API Error

struct APIError: Codable, Error {
    let code: String
    let message: String
    let details: [String: String]?
    
    var localizedDescription: String {
        return message
    }
    
    // Common error codes
    static let authInvalidToken = APIError(code: "AUTH_INVALID_TOKEN", message: "認証トークンが無効です", details: nil)
    static let authExpiredToken = APIError(code: "AUTH_EXPIRED_TOKEN", message: "認証トークンの有効期限が切れています", details: nil)
    static let userNotFound = APIError(code: "USER_NOT_FOUND", message: "ユーザーが見つかりません", details: nil)
    static let matchTimeout = APIError(code: "MATCH_TIMEOUT", message: "マッチングがタイムアウトしました", details: nil)
    static let callAlreadyEnded = APIError(code: "CALL_ALREADY_ENDED", message: "通話は既に終了しています", details: nil)
    static let insufficientTickets = APIError(code: "INSUFFICIENT_TICKETS", message: "チケットが不足しています", details: nil)
    static let rateLimitExceeded = APIError(code: "RATE_LIMIT_EXCEEDED", message: "リクエスト制限に達しました", details: nil)
    static let serverError = APIError(code: "SERVER_ERROR", message: "サーバーエラーが発生しました", details: nil)
    static let networkError = APIError(code: "NETWORK_ERROR", message: "ネットワークエラーが発生しました", details: nil)
    
    var isAuthenticationError: Bool {
        return code == "AUTH_INVALID_TOKEN" || code == "AUTH_EXPIRED_TOKEN"
    }
    
    var shouldRetry: Bool {
        return code == "SERVER_ERROR" || code == "NETWORK_ERROR"
    }
}

// MARK: - API Response

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: APIError?
    let timestamp: Date
}

// MARK: - Common API Responses

typealias EmptyResponse = APIResponse<EmptyData>

struct EmptyData: Codable {
    // Empty struct for responses with no data
}

// MARK: - Error Handling Extensions

extension APIError {
    static func from(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }
        
        // Convert system errors to API errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return APIError(code: "NETWORK_ERROR", message: "インターネット接続を確認してください", details: nil)
            case .timedOut:
                return APIError(code: "TIMEOUT_ERROR", message: "リクエストがタイムアウトしました", details: nil)
            default:
                return APIError(code: "NETWORK_ERROR", message: "ネットワークエラーが発生しました", details: nil)
            }
        }
        
        return APIError(code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil)
    }
}