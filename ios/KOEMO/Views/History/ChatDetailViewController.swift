import UIKit
import SnapKit

class ChatDetailViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .koemoBackground
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: Spacing.small, left: 0, bottom: 0, right: 0)
        
        // Register cells
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView.register(ChatCallInfoCell.self, forCellReuseIdentifier: "ChatCallInfoCell")
        
        return tableView
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        return view
    }()
    
    private lazy var messageInputView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBackground
        view.layer.cornerRadius = CornerRadius.medium
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.koemoTertiaryBackground.cgColor
        return view
    }()
    
    private lazy var messageTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "メッセージを入力..."
        textField.font = .koemoBody
        textField.textColor = .koemoText
        textField.delegate = self
        return textField
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        button.tintColor = .koemoBlue
        button.isEnabled = false
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    private var partnerNickname: String = ""
    private var messages: [ChatMessage] = []
    private var callInfo: CallInfo?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardNotifications()
        loadMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollToBottom(animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .koemoBackground
        title = partnerNickname
        
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(messageInputView)
        messageInputView.addSubview(messageTextField)
        messageInputView.addSubview(sendButton)
        
        setupConstraints()
        setupNavigationBar()
    }
    
    private func setupConstraints() {
        inputContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(60)
        }
        
        messageInputView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Spacing.small)
            make.left.right.equalToSuperview().inset(Spacing.medium)
        }
        
        messageTextField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.centerY.equalToSuperview()
            make.right.equalTo(sendButton.snp.left).offset(-Spacing.small)
        }
        
        sendButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(inputContainerView.snp.top)
        }
    }
    
    private func setupNavigationBar() {
        // Add info button
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(infoButtonTapped)
        )
        navigationItem.rightBarButtonItem = infoButton
    }
    
    // MARK: - Configuration
    
    func configure(with callRecord: CallRecord) {
        partnerNickname = callRecord.partnerNickname
        callInfo = CallInfo(
            duration: callRecord.duration,
            timestamp: callRecord.timestamp,
            partnerGender: callRecord.partnerGender,
            partnerAge: callRecord.partnerAge,
            partnerRegion: callRecord.partnerRegion
        )
    }
    
    func configure(with chatRecord: ChatRecord) {
        partnerNickname = chatRecord.partnerNickname
        callInfo = CallInfo(
            duration: chatRecord.callDuration,
            timestamp: chatRecord.timestamp,
            partnerGender: nil,
            partnerAge: nil,
            partnerRegion: nil
        )
    }
    
    // MARK: - Data Loading
    
    private func loadMessages() {
        // TODO: Load real messages from API
        // For now, load mock messages
        loadMockMessages()
        tableView.reloadData()
    }
    
    private func loadMockMessages() {
        messages = [
            ChatMessage(
                id: "1",
                text: "こんにちは！楽しい通話でした",
                timestamp: Date().addingTimeInterval(-1800),
                isFromUser: false
            ),
            ChatMessage(
                id: "2",
                text: "こちらこそありがとうございました！",
                timestamp: Date().addingTimeInterval(-1700),
                isFromUser: true
            ),
            ChatMessage(
                id: "3",
                text: "また機会があったらお話しましょう",
                timestamp: Date().addingTimeInterval(-1600),
                isFromUser: false
            ),
            ChatMessage(
                id: "4",
                text: "はい、ぜひ！",
                timestamp: Date().addingTimeInterval(-1500),
                isFromUser: true
            )
        ]
    }
    
    // MARK: - Actions
    
    @objc private func sendButtonTapped() {
        guard let text = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        sendMessage(text)
        messageTextField.text = ""
        updateSendButton()
    }
    
    @objc private func infoButtonTapped() {
        showCallInfo()
    }
    
    private func sendMessage(_ text: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            text: text,
            timestamp: Date(),
            isFromUser: true
        )
        
        messages.append(message)
        
        let indexPath = IndexPath(row: messages.count, section: 0)
        tableView.insertRows(at: [indexPath], with: .bottom)
        scrollToBottom(animated: true)
        
        // TODO: Send message to backend
    }
    
    private func updateSendButton() {
        let hasText = !(messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        sendButton.isEnabled = hasText
        sendButton.tintColor = hasText ? .koemoBlue : .koemoTertiaryText
    }
    
    private func scrollToBottom(animated: Bool) {
        DispatchQueue.main.async {
            let lastSection = self.tableView.numberOfSections - 1
            let lastRow = self.tableView.numberOfRows(inSection: lastSection) - 1
            
            if lastRow >= 0 {
                let indexPath = IndexPath(row: lastRow, section: lastSection)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            }
        }
    }
    
    private func showCallInfo() {
        guard let callInfo = callInfo else { return }
        
        let alert = UIAlertController(title: "通話情報", message: nil, preferredStyle: .alert)
        
        var infoText = "通話時間: \(formatDuration(callInfo.duration))\n"
        infoText += "日時: \(formatDateTime(callInfo.timestamp))"
        
        if let gender = callInfo.partnerGender {
            infoText += "\n性別: \(gender.displayName)"
        }
        if let age = callInfo.partnerAge {
            infoText += "\n年齢: \(age)歳"
        }
        if let region = callInfo.partnerRegion {
            infoText += "\n地域: \(region)"
        }
        
        alert.message = infoText
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        
        inputContainerView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-keyboardHeight + view.safeAreaInsets.bottom)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.scrollToBottom(animated: false)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        inputContainerView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - UITableViewDataSource

extension ChatDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count + 1 // +1 for call info cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            // Call info cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCallInfoCell", for: indexPath) as? ChatCallInfoCell else {
                return UITableViewCell()
            }
            if let callInfo = callInfo {
                cell.configure(with: callInfo, partnerName: partnerNickname)
            }
            return cell
        } else {
            // Message cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as? ChatMessageCell else {
                return UITableViewCell()
            }
            let message = messages[indexPath.row - 1]
            cell.configure(with: message)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension ChatDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 80 : 60
    }
}

// MARK: - UITextFieldDelegate

extension ChatDetailViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateSendButton()
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonTapped()
        return true
    }
}

// MARK: - Data Models

struct ChatMessage {
    let id: String
    let text: String
    let timestamp: Date
    let isFromUser: Bool
}

struct CallInfo {
    let duration: TimeInterval
    let timestamp: Date
    let partnerGender: UserProfile.Gender?
    let partnerAge: Int?
    let partnerRegion: String?
}