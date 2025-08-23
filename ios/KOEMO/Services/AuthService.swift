import Foundation
import UIKit

class AuthService {
    static let shared = AuthService()
    
    private var currentUser: User?
    
    private init() {
        // Load saved user data on initialization
        loadCurrentUser()
        APIService.shared.loadAccessToken()
    }
    
    // MARK: - Authentication
    
    func register(nickname: String, gender: UserProfile.Gender, age: Int?, region: String?, completion: @escaping (Result<User, Error>) -> Void) {
        let deviceId = getDeviceId()
        
        APIService.shared.register(
            deviceId: deviceId,
            nickname: nickname,
            gender: gender.rawValue,
            age: age,
            region: region
        ) { [weak self] result in
            switch result {
            case .success(let response):
                if response.success, let authData = response.data {
                    let user = User(
                        id: authData.userId,
                        deviceId: deviceId,
                        profile: authData.profile,
                        status: UserStatus(current: .online, lastActiveAt: Date()),
                        tickets: TicketInfo(balance: 0, freeCallsToday: 3, lastFreeCallAt: nil),
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    self?.currentUser = user
                    self?.saveCurrentUser(user)
                    completion(.success(user))
                } else if let error = response.error {
                    completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: error.message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func login(completion: @escaping (Result<User, Error>) -> Void) {
        let deviceId = getDeviceId()
        
        APIService.shared.login(deviceId: deviceId) { [weak self] result in
            switch result {
            case .success(let response):
                if response.success, let authData = response.data {
                    let user = User(
                        id: authData.userId,
                        deviceId: deviceId,
                        profile: authData.profile,
                        status: UserStatus(current: .online, lastActiveAt: Date()),
                        tickets: authData.tickets ?? TicketInfo(balance: 0, freeCallsToday: 3, lastFreeCallAt: nil),
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    self?.currentUser = user
                    self?.saveCurrentUser(user)
                    completion(.success(user))
                } else if let error = response.error {
                    completion(.failure(NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: error.message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        APIService.shared.logout { [weak self] result in
            switch result {
            case .success:
                self?.currentUser = nil
                self?.clearCurrentUser()
                WebSocketService.shared.disconnect()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - User Management
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func isLoggedIn() -> Bool {
        return currentUser != nil && APIService.shared.isLoggedIn()
    }
    
    func needsOnboarding() -> Bool {
        return !UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
    }
    
    // MARK: - Device ID Management
    
    private func getDeviceId() -> String {
        let key = "device_id"
        
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    // MARK: - User Persistence
    
    private func saveCurrentUser(_ user: User) {
        do {
            let userData = try JSONEncoder().encode(user)
            UserDefaults.standard.set(userData, forKey: "current_user")
        } catch {
            print("Failed to save user data: \(error)")
        }
    }
    
    private func loadCurrentUser() {
        guard let userData = UserDefaults.standard.data(forKey: "current_user") else {
            return
        }
        
        do {
            currentUser = try JSONDecoder().decode(User.self, from: userData)
        } catch {
            print("Failed to load user data: \(error)")
        }
    }
    
    private func clearCurrentUser() {
        UserDefaults.standard.removeObject(forKey: "current_user")
    }
    
    // MARK: - Auto Login
    
    func autoLogin(completion: @escaping (Bool) -> Void) {
        if !isLoggedIn() {
            completion(false)
            return
        }
        
        // Try to refresh token and validate session
        login { result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
}