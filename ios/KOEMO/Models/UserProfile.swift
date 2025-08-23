import Foundation

struct UserProfile: Codable {
    let nickname: String
    let gender: Gender
    let age: Int?
    let region: String?
    
    enum Gender: String, CaseIterable, Codable {
        case male = "male"
        case female = "female"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .male:
                return "男性"
            case .female:
                return "女性"
            case .other:
                return "その他"
            }
        }
    }
}