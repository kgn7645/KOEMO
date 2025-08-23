import Foundation
import Alamofire

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://koemo-backend.onrender.com/api"
    
    // Debug function to test connection
    func testConnection(completion: @escaping (Bool) -> Void) {
        AF.request("https://koemo-backend.onrender.com/health")
            .validate()
            .response { response in
                let isConnected = response.error == nil
                print("🔗 Connection test: \(isConnected ? "SUCCESS" : "FAILED")")
                if let error = response.error {
                    print("🔗 Error: \(error)")
                }
                completion(isConnected)
            }
    }
    private var accessToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    
    func register(deviceId: String, nickname: String, gender: String, age: Int?, region: String?, completion: @escaping (Result<AuthenticationResponse, Error>) -> Void) {
        let parameters: [String: Any] = [
            "deviceId": deviceId,
            "nickname": nickname,
            "gender": gender,
            "age": age as Any,
            "region": region as Any
        ]
        
        AF.request("\(baseURL)/register",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default)
            .validate()
            .responseDecodable(of: AuthenticationResponse.self) { response in
                switch response.result {
                case .success(let authResponse):
                    if authResponse.success, let data = authResponse.data {
                        self.accessToken = data.accessToken
                        self.saveTokens(accessToken: data.accessToken, refreshToken: data.refreshToken)
                    }
                    completion(.success(authResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func login(deviceId: String, completion: @escaping (Result<AuthenticationResponse, Error>) -> Void) {
        let parameters = ["deviceId": deviceId]
        
        AF.request("\(baseURL)/login",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default)
            .validate()
            .responseDecodable(of: AuthenticationResponse.self) { response in
                switch response.result {
                case .success(let authResponse):
                    if authResponse.success, let data = authResponse.data {
                        self.accessToken = data.accessToken
                        self.saveTokens(accessToken: data.accessToken, refreshToken: data.refreshToken)
                    }
                    completion(.success(authResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = accessToken else {
            completion(.failure(APIError.unauthorized))
            return
        }
        
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        AF.request("\(baseURL)/logout",
                   method: .post,
                   headers: headers)
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    self.clearTokens()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Token Management
    
    private func saveTokens(accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: "access_token")
        UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
    }
    
    private func clearTokens() {
        self.accessToken = nil
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
    }
    
    func loadAccessToken() {
        self.accessToken = UserDefaults.standard.string(forKey: "access_token")
    }
    
    func getAccessToken() -> String? {
        return accessToken
    }
    
    func isLoggedIn() -> Bool {
        return accessToken != nil
    }
}