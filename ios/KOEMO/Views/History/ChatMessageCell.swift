import UIKit
import SnapKit

class ChatMessageCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var messageBubble: UIView = {
        let view = UIView()
        view.layer.cornerRadius = CornerRadius.medium
        return view
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoBody
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption2
        label.textColor = .koemoTertiaryText
        return label
    }()
    
    // MARK: - Properties
    
    private var isFromUser: Bool = false
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(messageBubble)
        messageBubble.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // Constraints will be updated based on message direction
    }
    
    private func updateConstraints(for isFromUser: Bool) {
        messageBubble.snp.removeConstraints()
        messageLabel.snp.removeConstraints()
        timeLabel.snp.removeConstraints()
        
        if isFromUser {
            // Right-aligned (user's messages)
            messageBubble.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Spacing.small)
                make.right.equalToSuperview().offset(-Spacing.medium)
                make.left.greaterThanOrEqualToSuperview().offset(80)
                make.bottom.equalTo(timeLabel.snp.top).offset(-Spacing.extraSmall)
            }
            
            timeLabel.snp.makeConstraints { make in
                make.right.equalTo(messageBubble)
                make.bottom.equalToSuperview().offset(-Spacing.small)
            }
        } else {
            // Left-aligned (partner's messages)
            messageBubble.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Spacing.small)
                make.left.equalToSuperview().offset(Spacing.medium)
                make.right.lessThanOrEqualToSuperview().offset(-80)
                make.bottom.equalTo(timeLabel.snp.top).offset(-Spacing.extraSmall)
            }
            
            timeLabel.snp.makeConstraints { make in
                make.left.equalTo(messageBubble)
                make.bottom.equalToSuperview().offset(-Spacing.small)
            }
        }
        
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Spacing.medium)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with message: ChatMessage) {
        isFromUser = message.isFromUser
        
        messageLabel.text = message.text
        timeLabel.text = formatTime(message.timestamp)
        
        if isFromUser {
            messageBubble.backgroundColor = .koemoBlue
            messageLabel.textColor = .white
        } else {
            messageBubble.backgroundColor = .koemoSecondaryBackground
            messageLabel.textColor = .koemoText
        }
        
        updateConstraints(for: isFromUser)
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}