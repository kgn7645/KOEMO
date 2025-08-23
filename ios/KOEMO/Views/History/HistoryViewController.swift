import UIKit
import SnapKit

class HistoryViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["通話履歴", "チャット"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = .koemoSecondaryBackground
        control.selectedSegmentTintColor = .koemoBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.koemoText], for: .normal)
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .koemoBackground
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        tableView.contentInset = UIEdgeInsets(top: Spacing.small, left: 0, bottom: 0, right: 0)
        
        // Register cells
        tableView.register(CallHistoryCell.self, forCellReuseIdentifier: "CallHistoryCell")
        tableView.register(ChatHistoryCell.self, forCellReuseIdentifier: "ChatHistoryCell")
        tableView.register(EmptyStateCell.self, forCellReuseIdentifier: "EmptyStateCell")
        
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = .koemoBlue
        control.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return control
    }()
    
    // MARK: - Properties
    
    private var callHistory: [CallRecord] = []
    private var chatHistory: [ChatRecord] = []
    private var isShowingCallHistory: Bool = true
    
    enum HistoryMode {
        case calls
        case chats
    }
    
    private var currentMode: HistoryMode = .calls
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadHistoryData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshHistory()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .koemoBackground
        title = "履歴"
        
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        
        setupConstraints()
        setupNavigationBar()
    }
    
    private func setupConstraints() {
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Spacing.medium)
            make.left.right.equalToSuperview().inset(Spacing.medium)
            make.height.equalTo(32)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(Spacing.medium)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func setupNavigationBar() {
        // Clear button
        let clearButton = UIBarButtonItem(
            title: "クリア",
            style: .plain,
            target: self,
            action: #selector(clearButtonTapped)
        )
        clearButton.tintColor = .koemoRed
        navigationItem.rightBarButtonItem = clearButton
    }
    
    // MARK: - Data Loading
    
    private func loadHistoryData() {
        // TODO: Load real data from API
        // For now, load mock data
        loadMockData()
        tableView.reloadData()
    }
    
    private func loadMockData() {
        // Mock call history
        callHistory = [
            CallRecord(
                id: "1",
                partnerNickname: "山田太郎",
                partnerGender: .male,
                partnerAge: 28,
                partnerRegion: "東京都",
                duration: 245,
                timestamp: Date().addingTimeInterval(-3600),
                hasMessages: true
            ),
            CallRecord(
                id: "2",
                partnerNickname: "佐藤花子",
                partnerGender: .female,
                partnerAge: 24,
                partnerRegion: "大阪府",
                duration: 180,
                timestamp: Date().addingTimeInterval(-7200),
                hasMessages: false
            ),
            CallRecord(
                id: "3",
                partnerNickname: "田中一郎",
                partnerGender: .male,
                partnerAge: 31,
                partnerRegion: "愛知県",
                duration: 420,
                timestamp: Date().addingTimeInterval(-10800),
                hasMessages: true
            )
        ]
        
        // Mock chat history
        chatHistory = [
            ChatRecord(
                id: "1",
                partnerNickname: "山田太郎",
                lastMessage: "楽しい時間をありがとうございました！",
                timestamp: Date().addingTimeInterval(-3600),
                unreadCount: 0,
                callDuration: 245
            ),
            ChatRecord(
                id: "3",
                partnerNickname: "田中一郎",
                lastMessage: "また話しましょう",
                timestamp: Date().addingTimeInterval(-10800),
                unreadCount: 2,
                callDuration: 420
            )
        ]
    }
    
    // MARK: - Public Methods
    
    func refreshHistory() {
        loadHistoryData()
    }
    
    // MARK: - Actions
    
    @objc private func segmentChanged() {
        currentMode = segmentedControl.selectedSegmentIndex == 0 ? .calls : .chats
        tableView.reloadData()
        
        // Add haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
    }
    
    @objc private func refreshData() {
        // TODO: Refresh data from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadHistoryData()
            self.refreshControl.endRefreshing()
        }
    }
    
    @objc private func clearButtonTapped() {
        showClearConfirmation()
    }
    
    private func showClearConfirmation() {
        let title = currentMode == .calls ? "通話履歴をクリア" : "チャット履歴をクリア"
        let message = currentMode == .calls ? "すべての通話履歴を削除しますか？" : "すべてのチャット履歴を削除しますか？"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "削除", style: .destructive) { _ in
            self.clearHistory()
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func clearHistory() {
        if currentMode == .calls {
            callHistory.removeAll()
        } else {
            chatHistory.removeAll()
        }
        
        tableView.reloadData()
        
        // TODO: Send clear request to backend
    }
}

// MARK: - UITableViewDataSource

extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentMode == .calls {
            return callHistory.isEmpty ? 1 : callHistory.count
        } else {
            return chatHistory.isEmpty ? 1 : chatHistory.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if currentMode == .calls {
            if callHistory.isEmpty {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyStateCell", for: indexPath) as? EmptyStateCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "通話履歴がありません",
                    message: "誰かと通話すると履歴が表示されます",
                    icon: "phone"
                )
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "CallHistoryCell", for: indexPath) as? CallHistoryCell else {
                    return UITableViewCell()
                }
                cell.configure(with: callHistory[indexPath.row])
                return cell
            }
        } else {
            if chatHistory.isEmpty {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyStateCell", for: indexPath) as? EmptyStateCell else {
                    return UITableViewCell()
                }
                cell.configure(
                    title: "チャット履歴がありません",
                    message: "通話中にメッセージを送ると履歴が表示されます",
                    icon: "message"
                )
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatHistoryCell", for: indexPath) as? ChatHistoryCell else {
                    return UITableViewCell()
                }
                cell.configure(with: chatHistory[indexPath.row])
                return cell
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (currentMode == .calls && callHistory.isEmpty) || (currentMode == .chats && chatHistory.isEmpty) {
            return 200
        }
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if currentMode == .calls && !callHistory.isEmpty {
            let callRecord = callHistory[indexPath.row]
            if callRecord.hasMessages {
                showChatDetail(for: callRecord)
            }
        } else if currentMode == .chats && !chatHistory.isEmpty {
            let chatRecord = chatHistory[indexPath.row]
            showChatDetail(for: chatRecord)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Only allow swipe actions on actual data rows
        if (currentMode == .calls && callHistory.isEmpty) || (currentMode == .chats && chatHistory.isEmpty) {
            return nil
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "削除") { _, _, completion in
            self.deleteItem(at: indexPath)
            completion(true)
        }
        
        deleteAction.backgroundColor = .koemoRed
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func deleteItem(at indexPath: IndexPath) {
        if currentMode == .calls {
            callHistory.remove(at: indexPath.row)
        } else {
            chatHistory.remove(at: indexPath.row)
        }
        
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        // If no items left, reload to show empty state
        if (currentMode == .calls && callHistory.isEmpty) || (currentMode == .chats && chatHistory.isEmpty) {
            tableView.reloadData()
        }
    }
    
    private func showChatDetail(for callRecord: CallRecord) {
        let chatVC = ChatDetailViewController()
        chatVC.configure(with: callRecord)
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    private func showChatDetail(for chatRecord: ChatRecord) {
        let chatVC = ChatDetailViewController()
        chatVC.configure(with: chatRecord)
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

// MARK: - Data Models

struct CallRecord {
    let id: String
    let partnerNickname: String
    let partnerGender: UserProfile.Gender
    let partnerAge: Int?
    let partnerRegion: String?
    let duration: TimeInterval
    let timestamp: Date
    let hasMessages: Bool
}

struct ChatRecord {
    let id: String
    let partnerNickname: String
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
    let callDuration: TimeInterval
}