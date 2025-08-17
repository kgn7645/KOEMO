import UIKit
import SnapKit

class ChatHistoryCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        view.layer.cornerRadius = CornerRadius.medium
        return view
    }()
    
    private lazy var profileImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoGreen.withAlphaComponent(0.2)
        view.layer.cornerRadius = 25
        return view
    }()
    
    private lazy var profileIconLabel: UILabel = {
        let label = UILabel()
        label.text = "💬"
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoBodyBold
        label.textColor = .koemoText
        return label
    }()
    
    private lazy var lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption1
        label.textColor = .koemoSecondaryText
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption2
        label.textColor = .koemoTertiaryText
        label.textAlignment = .right
        return label
    }()
    
    private lazy var unreadBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoRed
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()
    
    private lazy var unreadCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private lazy var callDurationLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption2
        label.textColor = .koemoBlue
        label.textAlignment = .right
        return label
    }()
    
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
        
        contentView.addSubview(containerView)
        containerView.addSubview(profileImageView)
        profileImageView.addSubview(profileIconLabel)
        containerView.addSubview(nicknameLabel)
        containerView.addSubview(lastMessageLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(unreadBadge)
        unreadBadge.addSubview(unreadCountLabel)
        containerView.addSubview(callDurationLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Spacing.small)
            make.left.right.equalToSuperview().inset(Spacing.medium)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(50)
        }
        
        profileIconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        nicknameLabel.snp.makeConstraints { make in
            make.left.equalTo(profileImageView.snp.right).offset(Spacing.medium)
            make.top.equalToSuperview().offset(Spacing.small)
            make.right.equalTo(timeLabel.snp.left).offset(-Spacing.small)
        }
        
        lastMessageLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(2)
            make.right.equalTo(unreadBadge.snp.left).offset(-Spacing.small)
            make.bottom.lessThanOrEqualToSuperview().offset(-Spacing.small)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.top.equalToSuperview().offset(Spacing.small)
            make.width.equalTo(60)
        }
        
        unreadBadge.snp.makeConstraints { make in
            make.right.equalTo(timeLabel)
            make.centerY.equalTo(lastMessageLabel)
            make.size.equalTo(20)
        }
        
        unreadCountLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        callDurationLabel.snp.makeConstraints { make in
            make.right.equalTo(timeLabel)
            make.bottom.equalToSuperview().offset(-Spacing.small)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with chatRecord: ChatRecord) {
        nicknameLabel.text = chatRecord.partnerNickname
        lastMessageLabel.text = chatRecord.lastMessage
        timeLabel.text = formatTime(chatRecord.timestamp)
        callDurationLabel.text = "通話時間: \(formatDuration(chatRecord.callDuration))"
        
        // Unread badge
        if chatRecord.unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadCountLabel.text = chatRecord.unreadCount > 99 ? "99+" : "\(chatRecord.unreadCount)"
        } else {
            unreadBadge.isHidden = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
    
    // MARK: - Animation
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = highlighted ? 
                CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            self.containerView.alpha = highlighted ? 0.8 : 1.0
        }
    }
}