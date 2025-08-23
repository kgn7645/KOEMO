import UIKit
import Network

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Trigger Local Network Permission early (for iOS 14+)
        triggerLocalNetworkPermission()
        
        // Check if user is already registered
        if UserDefaults.standard.string(forKey: "user_id") != nil {
            // User exists, go to main interface
            setupMainInterface()
        } else {
            // New user, show onboarding
            setupOnboardingInterface()
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