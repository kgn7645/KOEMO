import UIKit
import SnapKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .koemoBackground
        tableView.delegate = self
        tableView.dataSource = self
        
        // Improve performance and stability
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 30
        tableView.estimatedSectionFooterHeight = 0
        
        // Register cells
        tableView.register(SettingsProfileCell.self, forCellReuseIdentifier: "SettingsProfileCell")
        tableView.register(SettingsMenuCell.self, forCellReuseIdentifier: "SettingsMenuCell")
        tableView.register(SettingsSwitchCell.self, forCellReuseIdentifier: "SettingsSwitchCell")
        tableView.register(SettingsValueCell.self, forCellReuseIdentifier: "SettingsValueCell")
        
        return tableView
    }()
    
    // MARK: - Properties
    
    private var userProfile: UserProfile?
    private var settingsData: [SettingsSection] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔧 Settings: viewDidLoad started")
        
        do {
            setupUI()
            loadUserProfile()
            setupSettingsData()
            print("✅ Settings: viewDidLoad completed successfully")
        } catch {
            print("❌ Settings: Error in viewDidLoad: \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSettings()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .koemoBackground
        title = "設定"
        
        view.addSubview(tableView)
        
        setupConstraints()
        setupNavigationBar()
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupNavigationBar() {
        // No additional navigation items needed for now
    }
    
    // MARK: - Data Loading
    
    private func loadUserProfile() {
        // Load actual user profile from UserDefaults
        let nickname = UserDefaults.standard.string(forKey: "user_nickname") ?? "未設定"
        let genderString = UserDefaults.standard.string(forKey: "user_gender") ?? "male"
        let age = UserDefaults.standard.object(forKey: "user_age") as? Int ?? 0
        let region = UserDefaults.standard.string(forKey: "user_region")
        
        // Convert gender string to enum
        let gender = UserProfile.Gender(rawValue: genderString) ?? .male
        
        userProfile = UserProfile(
            nickname: nickname,
            gender: gender,
            age: age > 0 ? age : nil,
            region: region
        )
        
        print("📊 Loaded user profile from UserDefaults:")
        print("   Nickname: \(nickname)")
        print("   Gender: \(genderString)")
        print("   Age: \(age)")
        print("   Region: \(region ?? "未設定")")
    }
    
    private func setupSettingsData() {
        settingsData = [
            // Profile section
            SettingsSection(
                title: nil,
                items: [
                    .profile(userProfile)
                ]
            ),
            
            // App preferences
            SettingsSection(
                title: "アプリ設定",
                items: [
                    .switch(
                        title: "通知",
                        subtitle: "新しいマッチングやメッセージの通知",
                        isOn: true,
                        action: { [weak self] isOn in
                            self?.handleNotificationToggle(isOn)
                        }
                    ),
                    .switch(
                        title: "バイブレーション",
                        subtitle: "通知時のバイブレーション",
                        isOn: true,
                        action: { [weak self] isOn in
                            self?.handleVibrationToggle(isOn)
                        }
                    ),
                    .value(
                        title: "言語",
                        value: "日本語",
                        action: { [weak self] in
                            self?.showLanguageSettings()
                        }
                    )
                ]
            ),
            
            // Call settings
            SettingsSection(
                title: "通話設定",
                items: [
                    .switch(
                        title: "自動スピーカー",
                        subtitle: "通話開始時に自動でスピーカーをON",
                        isOn: false,
                        action: { [weak self] isOn in
                            self?.handleAutoSpeakerToggle(isOn)
                        }
                    ),
                    .switch(
                        title: "背景ノイズ抑制",
                        subtitle: "通話中の背景音を軽減",
                        isOn: true,
                        action: { [weak self] isOn in
                            self?.handleNoiseSuppressionToggle(isOn)
                        }
                    )
                ]
            ),
            
            // Privacy settings
            SettingsSection(
                title: "プライバシー",
                items: [
                    .menu(
                        title: "ブロックリスト",
                        subtitle: "ブロックしたユーザーの管理",
                        icon: "person.crop.circle.badge.minus",
                        action: { [weak self] in
                            self?.showBlockList()
                        }
                    ),
                    .menu(
                        title: "通話履歴の削除",
                        subtitle: "保存された通話履歴をクリア",
                        icon: "trash",
                        action: { [weak self] in
                            self?.showClearHistoryConfirmation()
                        }
                    )
                ]
            ),
            
            // About section
            SettingsSection(
                title: "アプリについて",
                items: [
                    .menu(
                        title: "利用規約",
                        subtitle: nil,
                        icon: "doc.text",
                        action: { [weak self] in
                            self?.showTermsOfService()
                        }
                    ),
                    .menu(
                        title: "プライバシーポリシー",
                        subtitle: nil,
                        icon: "lock.doc",
                        action: { [weak self] in
                            self?.showPrivacyPolicy()
                        }
                    ),
                    .menu(
                        title: "お問い合わせ",
                        subtitle: nil,
                        icon: "envelope",
                        action: { [weak self] in
                            self?.showContactSupport()
                        }
                    ),
                    .value(
                        title: "バージョン",
                        value: "1.0.0",
                        action: nil
                    )
                ]
            ),
            
            // Account actions
            SettingsSection(
                title: nil,
                items: [
                    .menu(
                        title: "アカウント削除",
                        subtitle: "アカウントとすべてのデータを削除",
                        icon: "person.crop.circle.badge.xmark",
                        textColor: .koemoRed,
                        action: { [weak self] in
                            self?.showDeleteAccountConfirmation()
                        }
                    )
                ]
            )
        ]
        
        // Reload table view synchronously to prevent timing issues
        tableView.reloadData()
    }
    
    // MARK: - Public Methods
    
    func refreshSettings() {
        // Only refresh if data hasn't been set yet
        guard settingsData.isEmpty else { return }
        loadUserProfile()
        setupSettingsData()
    }
    
    // MARK: - Setting Actions
    
    private func handleNotificationToggle(_ isOn: Bool) {
        // TODO: Update notification settings
        UserDefaults.standard.set(isOn, forKey: "notifications_enabled")
        print("Notifications: \(isOn)")
    }
    
    private func handleVibrationToggle(_ isOn: Bool) {
        // TODO: Update vibration settings
        UserDefaults.standard.set(isOn, forKey: "vibration_enabled")
        print("Vibration: \(isOn)")
    }
    
    private func handleAutoSpeakerToggle(_ isOn: Bool) {
        // TODO: Update auto speaker settings
        UserDefaults.standard.set(isOn, forKey: "auto_speaker_enabled")
        print("Auto speaker: \(isOn)")
    }
    
    private func handleNoiseSuppressionToggle(_ isOn: Bool) {
        // TODO: Update noise suppression settings
        UserDefaults.standard.set(isOn, forKey: "noise_suppression_enabled")
        print("Noise suppression: \(isOn)")
    }
    
    // MARK: - Menu Actions
    
    private func showLanguageSettings() {
        let alert = UIAlertController(title: "言語設定", message: "アプリの表示言語を選択してください", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "日本語", style: .default) { _ in
            // TODO: Change language to Japanese
        })
        
        alert.addAction(UIAlertAction(title: "English", style: .default) { _ in
            // TODO: Change language to English
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func showBlockList() {
        let blockListVC = BlockListViewController()
        navigationController?.pushViewController(blockListVC, animated: true)
    }
    
    private func showClearHistoryConfirmation() {
        let alert = UIAlertController(
            title: "通話履歴の削除",
            message: "すべての通話履歴とチャット履歴を削除しますか？この操作は取り消せません。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { _ in
            self.clearAllHistory()
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func clearAllHistory() {
        // TODO: Clear all history from backend
        
        // Show success message
        let alert = UIAlertController(
            title: "削除完了",
            message: "すべての履歴を削除しました。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showTermsOfService() {
        let webVC = WebViewController()
        webVC.title = "利用規約"
        // TODO: Load actual terms URL
        webVC.loadURL("https://example.com/terms")
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func showPrivacyPolicy() {
        let webVC = WebViewController()
        webVC.title = "プライバシーポリシー"
        // TODO: Load actual privacy policy URL
        webVC.loadURL("https://example.com/privacy")
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func showContactSupport() {
        let alert = UIAlertController(title: "お問い合わせ", message: "お問い合わせ方法を選択してください", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "メールで問い合わせ", style: .default) { _ in
            self.openEmail()
        })
        
        alert.addAction(UIAlertAction(title: "アプリ内フィードバック", style: .default) { _ in
            self.showFeedbackForm()
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func openEmail() {
        if let url = URL(string: "mailto:support@koemo.app") {
            UIApplication.shared.open(url)
        }
    }
    
    private func showFeedbackForm() {
        let feedbackVC = FeedbackViewController()
        let navController = UINavigationController(rootViewController: feedbackVC)
        present(navController, animated: true)
    }
    
    private func showDeleteAccountConfirmation() {
        let alert = UIAlertController(
            title: "アカウント削除",
            message: "アカウントを削除すると、すべてのデータが完全に削除され、復元できなくなります。本当に削除しますか？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { _ in
            self.showFinalDeleteConfirmation()
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showFinalDeleteConfirmation() {
        let alert = UIAlertController(
            title: "最終確認",
            message: "この操作は取り消せません。「DELETE」と入力してください。",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "DELETE"
        }
        
        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { _ in
            if let textField = alert.textFields?.first,
               textField.text == "DELETE" {
                self.deleteAccount()
            } else {
                self.showInvalidConfirmationAlert()
            }
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showInvalidConfirmationAlert() {
        let alert = UIAlertController(
            title: "入力エラー",
            message: "「DELETE」と正確に入力してください。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func deleteAccount() {
        // TODO: Send delete account request to backend
        
        // For now, just clear local data and return to onboarding
        UserDefaults.standard.removeObject(forKey: "user_authenticated")
        
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchToOnboarding()
        }
    }
    
    private func editProfile() {
        let profileEditVC = ProfileEditViewController()
        profileEditVC.configure(with: userProfile)
        let navController = UINavigationController(rootViewController: profileEditVC)
        present(navController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsData[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Bounds check
        guard indexPath.section < settingsData.count,
              indexPath.row < settingsData[indexPath.section].items.count else {
            print("⚠️ Settings: Invalid indexPath \(indexPath)")
            return UITableViewCell()
        }
        
        let section = settingsData[indexPath.section]
        let item = section.items[indexPath.row]
        
        switch item {
        case .profile(let profile):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsProfileCell", for: indexPath) as? SettingsProfileCell else {
                print("⚠️ Settings: Failed to dequeue SettingsProfileCell")
                return UITableViewCell()
            }
            cell.configure(with: profile)
            return cell
            
        case .menu(let title, let subtitle, let icon, let textColor, _):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsMenuCell", for: indexPath) as? SettingsMenuCell else {
                print("⚠️ Settings: Failed to dequeue SettingsMenuCell")
                return UITableViewCell()
            }
            cell.configure(title: title, subtitle: subtitle, icon: icon, textColor: textColor)
            return cell
            
        case .switch(let title, let subtitle, let isOn, let action):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsSwitchCell", for: indexPath) as? SettingsSwitchCell else {
                print("⚠️ Settings: Failed to dequeue SettingsSwitchCell")
                return UITableViewCell()
            }
            cell.configure(title: title, subtitle: subtitle, isOn: isOn, action: action)
            return cell
            
        case .value(let title, let value, let action):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsValueCell", for: indexPath) as? SettingsValueCell else {
                print("⚠️ Settings: Failed to dequeue SettingsValueCell")
                return UITableViewCell()
            }
            cell.configure(title: title, value: value, hasAction: action != nil)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingsData[section].title
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = settingsData[indexPath.section]
        let item = section.items[indexPath.row]
        
        switch item {
        case .profile:
            editProfile()
        case .menu(_, _, _, _, let action):
            action()
        case .value(_, _, let action):
            action?()
        case .switch:
            break // Handled by the switch itself
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = settingsData[indexPath.section]
        let item = section.items[indexPath.row]
        
        switch item {
        case .profile:
            return 80
        default:
            return UITableView.automaticDimension
        }
    }
}

// MARK: - Settings Data Models

enum SettingsItem {
    case profile(UserProfile?)
    case menu(title: String, subtitle: String?, icon: String?, textColor: UIColor? = nil, action: () -> Void)
    case `switch`(title: String, subtitle: String?, isOn: Bool, action: (Bool) -> Void)
    case value(title: String, value: String, action: (() -> Void)?)
}

struct SettingsSection {
    let title: String?
    let items: [SettingsItem]
}