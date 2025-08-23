import UIKit
import SnapKit

class BlockListViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .koemoBackground
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        
        // Register cells
        tableView.register(BlockedUserCell.self, forCellReuseIdentifier: "BlockedUserCell")
        tableView.register(EmptyStateCell.self, forCellReuseIdentifier: "EmptyStateCell")
        
        return tableView
    }()
    
    // MARK: - Properties
    
    private var blockedUsers: [BlockedUser] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadBlockedUsers()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .koemoBackground
        title = "ブロックリスト"
        
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
        // Back button is automatically added by navigation controller
    }
    
    // MARK: - Data Loading
    
    private func loadBlockedUsers() {
        // TODO: Load blocked users from API
        // For now, use mock data
        loadMockData()
        tableView.reloadData()
    }
    
    private func loadMockData() {
        blockedUsers = [
            BlockedUser(
                id: "1",
                nickname: "迷惑ユーザー1",
                gender: .male,
                age: 30,
                blockedDate: Date().addingTimeInterval(-86400)
            ),
            BlockedUser(
                id: "2",
                nickname: "スパムユーザー",
                gender: .female,
                age: 25,
                blockedDate: Date().addingTimeInterval(-172800)
            )
        ]
    }
    
    // MARK: - Actions
    
    private func unblockUser(at indexPath: IndexPath) {
        let user = blockedUsers[indexPath.row]
        
        let alert = UIAlertController(
            title: "ブロック解除",
            message: "\(user.nickname)のブロックを解除しますか？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "解除", style: .default) { _ in
            self.performUnblock(at: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func performUnblock(at indexPath: IndexPath) {
        // TODO: Send unblock request to backend
        
        blockedUsers.remove(at: indexPath.row)
        
        if blockedUsers.isEmpty {
            tableView.reloadData()
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        // Show success message
        let alert = UIAlertController(
            title: "ブロック解除完了",
            message: "ユーザーのブロックを解除しました。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BlockListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.isEmpty ? 1 : blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if blockedUsers.isEmpty {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyStateCell", for: indexPath) as? EmptyStateCell else {
                return UITableViewCell()
            }
            cell.configure(
                title: "ブロックしたユーザーはいません",
                message: "不適切な行動をするユーザーをブロックできます",
                icon: "person.crop.circle.badge.minus"
            )
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedUserCell", for: indexPath) as? BlockedUserCell else {
                return UITableViewCell()
            }
            cell.configure(with: blockedUsers[indexPath.row])
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension BlockListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return blockedUsers.isEmpty ? 200 : 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !blockedUsers.isEmpty {
            unblockUser(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if blockedUsers.isEmpty {
            return nil
        }
        
        let unblockAction = UIContextualAction(style: .normal, title: "解除") { _, _, completion in
            self.unblockUser(at: indexPath)
            completion(true)
        }
        
        unblockAction.backgroundColor = .koemoGreen
        unblockAction.image = UIImage(systemName: "person.crop.circle.badge.checkmark")
        
        return UISwipeActionsConfiguration(actions: [unblockAction])
    }
}

// MARK: - Data Models

struct BlockedUser {
    let id: String
    let nickname: String
    let gender: UserProfile.Gender
    let age: Int?
    let blockedDate: Date
}