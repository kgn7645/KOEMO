import UIKit

class MainTabBarController: UITabBarController {
    
    // MARK: - View Controllers
    
    private lazy var homeViewController: HomeViewController = {
        let vc = HomeViewController()
        vc.tabBarItem = UITabBarItem(
            title: "通話",
            image: UIImage(systemName: "phone"),
            selectedImage: UIImage(systemName: "phone.fill")
        )
        vc.tabBarItem.tag = 0
        return vc
    }()
    
    private lazy var historyViewController: HistoryViewController = {
        let vc = HistoryViewController()
        vc.tabBarItem = UITabBarItem(
            title: "履歴",
            image: UIImage(systemName: "clock"),
            selectedImage: UIImage(systemName: "clock.fill")
        )
        vc.tabBarItem.tag = 1
        return vc
    }()
    
    private lazy var settingsViewController: SettingsViewController = {
        let vc = SettingsViewController()
        vc.tabBarItem = UITabBarItem(
            title: "設定",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        vc.tabBarItem.tag = 2
        return vc
    }()
    
    // MARK: - Properties
    
    private var callViewController: CallViewController?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupTabBar() {
        // Tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .koemoBackground
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = .koemoSecondaryText
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.koemoSecondaryText,
            .font: UIFont.koemoCaption1
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = .koemoBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.koemoBlue,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        
        // Tab bar style
        tabBar.tintColor = .koemoBlue
        tabBar.unselectedItemTintColor = .koemoSecondaryText
        tabBar.backgroundColor = .koemoBackground
        
        // Add subtle shadow
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -1)
        tabBar.layer.shadowRadius = 4
        tabBar.layer.shadowOpacity = 0.1
    }
    
    private func setupViewControllers() {
        // Wrap view controllers in navigation controllers
        let homeNavController = UINavigationController(rootViewController: homeViewController)
        let historyNavController = UINavigationController(rootViewController: historyViewController)
        let settingsNavController = UINavigationController(rootViewController: settingsViewController)
        
        // Configure navigation controllers
        [homeNavController, historyNavController, settingsNavController].forEach { navController in
            configureNavigationController(navController)
        }
        
        // Set view controllers
        viewControllers = [homeNavController, historyNavController, settingsNavController]
        
        // Set default selected tab
        selectedIndex = 0
        
        // Set delegate
        delegate = self
    }
    
    private func configureNavigationController(_ navController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .koemoBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.koemoText,
            .font: UIFont.koemoTitle3
        ]
        appearance.shadowColor = .clear
        
        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.tintColor = .koemoBlue
        navController.navigationBar.isTranslucent = false
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(callDidStart),
            name: NSNotification.Name("CallDidStart"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(callDidEnd),
            name: NSNotification.Name("CallDidEnd"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Call Management
    
    @objc private func callDidStart(notification: Notification) {
        guard let callInfo = notification.userInfo as? [String: Any] else { return }
        presentCallInterface(with: callInfo)
    }
    
    @objc private func callDidEnd(notification: Notification) {
        dismissCallInterface()
    }
    
    private func presentCallInterface(with callInfo: [String: Any]) {
        // Dismiss any existing call interface
        if let existingCallVC = callViewController {
            existingCallVC.dismiss(animated: false)
        }
        
        // Create new call view controller
        let mockPartner = UserProfile(nickname: "テストユーザー", gender: .female, age: 25, region: "東京")
        let callVC = CallViewController(callId: "mock-call-id", partner: mockPartner, isInitiator: true)
        callVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        callVC.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        // Present call interface
        present(callVC, animated: true) {
            self.callViewController = callVC
        }
    }
    
    private func dismissCallInterface() {
        guard let callVC = callViewController else { return }
        
        callVC.dismiss(animated: true) {
            self.callViewController = nil
            
            // Switch to history tab to show the completed call
            self.selectedIndex = 1
        }
    }
    
    // MARK: - Public Methods
    
    func showMatchingInterface() {
        // Switch to home tab
        selectedIndex = 0
        
        // Tell home view controller to show matching
        if let homeNavController = viewControllers?[0] as? UINavigationController,
           let homeVC = homeNavController.viewControllers.first as? HomeViewController {
            homeVC.showMatchingInterface()
        }
    }
    
    func showCallHistory() {
        // Switch to history tab
        selectedIndex = 1
    }
    
    func showSettings() {
        // Switch to settings tab
        selectedIndex = 2
    }
}

// MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Add haptic feedback when switching tabs
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        
        // Handle tab selection
        switch tabBarController.selectedIndex {
        case 0: // Home tab
            if let homeNavController = viewController as? UINavigationController,
               let homeVC = homeNavController.viewControllers.first as? HomeViewController {
                homeVC.viewDidAppear(true)
            }
            
        case 1: // History tab
            if let historyNavController = viewController as? UINavigationController,
               let historyVC = historyNavController.viewControllers.first as? HistoryViewController {
                historyVC.refreshHistory()
            }
            
        case 2: // Settings tab
            if let settingsNavController = viewController as? UINavigationController,
               let settingsVC = settingsNavController.viewControllers.first as? SettingsViewController {
                settingsVC.refreshSettings()
            }
            
        default:
            break
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Prevent tab switching during calls
        if callViewController != nil {
            return false
        }
        
        return true
    }
}

// MARK: - Call Presentation Helper

extension MainTabBarController {
    func canPresentCall() -> Bool {
        return callViewController == nil && presentedViewController == nil
    }
}