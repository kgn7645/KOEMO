import UIKit
import Network

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Trigger Local Network Permission early (for iOS 14+)
        triggerLocalNetworkPermission()
        
        // Test connection before proceeding
        APIService.shared.testConnection { isConnected in
            DispatchQueue.main.async {
                if isConnected {
                    print("✅ Server connection successful")
                    // Check if user is already registered
                    if UserDefaults.standard.string(forKey: "user_id") != nil {
                        // User exists, go to main interface
                        self.setupMainInterface()
                    } else {
                        // New user, show onboarding
                        self.setupOnboardingInterface()
                    }
                } else {
                    print("❌ Server connection failed - showing offline mode")
                    self.setupOfflineInterface()
                }
            }
        }
        
        window?.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
    
    // MARK: - Private Methods
    
    private func setupMainInterface() {
        let tabBarController = MainTabBarController()
        window?.rootViewController = tabBarController
    }
    
    private func setupOnboardingInterface() {
        let onboardingVC = OnboardingViewController()
        let navigationController = UINavigationController(rootViewController: onboardingVC)
        window?.rootViewController = navigationController
    }
    
    private func setupOfflineInterface() {
        let alert = UIAlertController(
            title: "接続エラー",
            message: "サーバーに接続できません。ネットワーク接続を確認してアプリを再起動してください。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // For now, still show onboarding in offline mode
            self.setupOnboardingInterface()
        })
        
        let tempVC = UIViewController()
        window?.rootViewController = tempVC
        tempVC.present(alert, animated: true)
    }
    
    func switchToMainInterface() {
        setupMainInterface()
    }
    
    func switchToOnboarding() {
        setupOnboardingInterface()
    }
    
    // MARK: - Local Network Permission Trigger
    
    private func triggerLocalNetworkPermission() {
        print("🌐 Triggering Local Network Permission...")
        
        // Method 1: Bonjour Browser to trigger permission dialog
        let parameters = NWParameters()
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        
        let browserDescriptor = NWBrowser.Descriptor.bonjour(type: "_http._tcp", domain: "local.")
        let browser = NWBrowser(for: browserDescriptor, using: parameters)
        
        browser.stateUpdateHandler = { state in
            print("🌐 Browser state: \(state)")
            switch state {
            case .ready:
                print("✅ Local Network Browser ready - permission likely granted")
                browser.cancel()
            case .failed(let error):
                print("❌ Local Network Browser failed: \(error)")
                browser.cancel()
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { results, changes in
            print("🌐 Found \(results.count) local services")
        }
        
        browser.start(queue: DispatchQueue.main)
        
        // Auto cleanup after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            browser.cancel()
        }
    }
}