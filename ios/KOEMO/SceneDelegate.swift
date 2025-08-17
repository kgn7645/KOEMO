import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // Check if user is authenticated
        let isAuthenticated = UserDefaults.standard.bool(forKey: "user_authenticated")
        
        if isAuthenticated {
            // Show main tab bar controller
            setupMainInterface()
        } else {
            // Show onboarding/registration
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
}