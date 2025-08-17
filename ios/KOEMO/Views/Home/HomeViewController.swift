import UIKit
import SnapKit

class HomeViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var ticketLabel: UILabel = {
        let label = UILabel()
        label.text = "🎫 5"
        label.font = .koemoBodyBold
        label.textColor = .koemoText
        return label
    }()
    
    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "KOEMO"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .koemoBlue
        label.textAlignment = .center
        return label
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.tintColor = .koemoSecondaryText
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var mainContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var callButton: KoemoButton = {
        let button = KoemoButton(title: "📞\n話す", style: .call, size: .call)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(callButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "「誰かと話したい」\nそんな時にワンタップ"
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "オンライン中"
        label.font = .koemoCaption1
        label.textColor = .koemoGreen
        label.textAlignment = .center
        return label
    }()
    
    private lazy var quickStatsView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        view.layer.cornerRadius = CornerRadius.medium
        return view
    }()
    
    private lazy var statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()
    
    // MARK: - Properties
    
    private var currentTicketCount: Int = 5
    private var isMatching: Bool = false
    private var matchingViewController: MatchingViewController?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUserStats()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateCallButton()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .koemoBackground
        title = ""
        
        // Add main components
        view.addSubview(headerView)
        view.addSubview(mainContentView)
        view.addSubview(quickStatsView)
        
        // Setup header
        headerView.addSubview(ticketLabel)
        headerView.addSubview(logoLabel)
        headerView.addSubview(settingsButton)
        
        // Setup main content
        mainContentView.addSubview(callButton)
        mainContentView.addSubview(descriptionLabel)
        mainContentView.addSubview(statusLabel)
        
        // Setup quick stats
        quickStatsView.addSubview(statsStackView)
        setupQuickStats()
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        
        ticketLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.centerY.equalToSuperview()
        }
        
        logoLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        settingsButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
        
        mainContentView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(Spacing.large)
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
        }
        
        callButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(callButton.snp.bottom).offset(Spacing.large)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(Spacing.large)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(Spacing.medium)
            make.centerX.equalToSuperview()
        }
        
        quickStatsView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Spacing.large)
            make.left.right.equalToSuperview().inset(Spacing.medium)
            make.height.equalTo(80)
        }
        
        statsStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Spacing.medium)
        }
    }
    
    private func setupQuickStats() {
        let todayCallsLabel = createStatView(title: "今日の通話", value: "3回")
        let totalTimeLabel = createStatView(title: "総通話時間", value: "2時間")
        let availableCallsLabel = createStatView(title: "無料通話", value: "あと2回")
        
        [todayCallsLabel, totalTimeLabel, availableCallsLabel].forEach {
            statsStackView.addArrangedSubview($0)
        }
    }
    
    private func createStatView(title: String, value: String) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .koemoCaption2
        titleLabel.textColor = .koemoSecondaryText
        titleLabel.textAlignment = .center
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .koemoBodyBold
        valueLabel.textColor = .koemoText
        valueLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        return containerView
    }
    
    // MARK: - Data Loading
    
    private func loadUserData() {
        // TODO: Load user data from API
        // For now, use mock data
        currentTicketCount = 5
        updateTicketDisplay()
    }
    
    private func refreshUserStats() {
        // TODO: Refresh user statistics
        // For now, mock refresh
        updateStatsDisplay()
    }
    
    private func updateTicketDisplay() {
        ticketLabel.text = "🎫 \(currentTicketCount)"
    }
    
    private func updateStatsDisplay() {
        // This would update the stats in the bottom view
        // For now, keeping static values
    }
    
    // MARK: - Actions
    
    @objc private func callButtonTapped() {
        guard !isMatching else { return }
        
        showCallOptionsAlert()
    }
    
    @objc private func settingsButtonTapped() {
        // Switch to settings tab
        if let tabBarController = tabBarController as? MainTabBarController {
            tabBarController.showSettings()
        }
    }
    
    private func showCallOptionsAlert() {
        let alert = UIAlertController(title: "通話を開始", message: "通話方法を選択してください", preferredStyle: .actionSheet)
        
        // Free call with ad
        alert.addAction(UIAlertAction(title: "広告を見て無料通話", style: .default) { _ in
            self.startCallWithAd()
        })
        
        // Ticket call (if available)
        if currentTicketCount > 0 {
            alert.addAction(UIAlertAction(title: "チケットを使って通話（残り\(currentTicketCount)枚）", style: .default) { _ in
                self.startCallWithTicket()
            })
        }
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = callButton
            popover.sourceRect = callButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func startCallWithAd() {
        // TODO: Show ad first, then start matching
        // For now, skip ad and go directly to matching
        startMatching(useTicket: false)
    }
    
    private func startCallWithTicket() {
        startMatching(useTicket: true)
    }
    
    private func startMatching(useTicket: Bool) {
        isMatching = true
        callButton.setLoading(true)
        
        // Present matching screen
        showMatchingInterface()
        
        // TODO: Send matching request to backend
        // For now, simulate matching process
        simulateMatching()
    }
    
    private func simulateMatching() {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate finding a match
            self.handleMatchFound()
        }
    }
    
    private func handleMatchFound() {
        isMatching = false
        callButton.setLoading(false)
        
        // TODO: Present match confirmation screen
        // For now, go directly to call
        startCall()
    }
    
    private func startCall() {
        // Notify that call is starting
        let callInfo: [String: Any] = [
            "partnerId": "mock-partner-id",
            "partnerNickname": "テストユーザー"
        ]
        
        NotificationCenter.default.post(
            name: NSNotification.Name("CallDidStart"),
            object: nil,
            userInfo: callInfo
        )
    }
    
    // MARK: - Public Methods
    
    func showMatchingInterface() {
        let matchingVC = MatchingViewController()
        matchingVC.delegate = self
        matchingVC.modalPresentationStyle = .fullScreen
        present(matchingVC, animated: true)
        matchingViewController = matchingVC
    }
    
    // MARK: - Animations
    
    private func animateCallButton() {
        // Subtle pulse animation for the call button
        UIView.animate(withDuration: 2.0, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.callButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            self.callButton.transform = .identity
        }
    }
}

// MARK: - MatchingViewControllerDelegate

extension HomeViewController: MatchingViewControllerDelegate {
    func matchingDidCancel() {
        isMatching = false
        callButton.setLoading(false)
        matchingViewController?.dismiss(animated: true)
        matchingViewController = nil
    }
    
    func matchingDidFindMatch(partner: UserProfile) {
        isMatching = false
        callButton.setLoading(false)
        
        // Dismiss matching screen and start call
        matchingViewController?.dismiss(animated: true) {
            self.matchingViewController = nil
            self.startCall()
        }
    }
}

// MARK: - MatchingViewControllerDelegate Protocol

protocol MatchingViewControllerDelegate: AnyObject {
    func matchingDidCancel()
    func matchingDidFindMatch(partner: UserProfile)
}