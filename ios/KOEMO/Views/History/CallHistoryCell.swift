import UIKit
import SnapKit

class CallHistoryCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        view.layer.cornerRadius = CornerRadius.medium
        return view
    }()
    
    private lazy var profileImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBlue.withAlphaComponent(0.2)
        view.layer.cornerRadius = 25
        return view
    }()
    
    private lazy var profileIconLabel: UILabel = {
        let label = UILabel()
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
    
    private lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption1
        label.textColor = .koemoSecondaryText
        return label
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption2
        label.textColor = .koemoTertiaryText
        label.textAlignment = .right
        return label
    }()
    
    private lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption1
        label.textColor = .koemoBlue
        label.textAlignment = .right
        return label
    }()
    
    private lazy var messageIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoGreen
        view.layer.cornerRadius = 4
        view.isHidden = true
        return view
    }()
    
    private lazy var messageIconLabel: UILabel = {
        let label = UILabel()
        label.text = "💬"
        label.font = .systemFont(ofSize: 12)
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
        containerView.addSubview(detailsLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(durationLabel)
        containerView.addSubview(messageIndicator)
        messageIndicator.addSubview(messageIconLabel)
        
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
        
        detailsLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(2)
            make.right.equalTo(durationLabel.snp.left).offset(-Spacing.small)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.top.equalToSuperview().offset(Spacing.small)
            make.width.equalTo(60)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.right.equalTo(timeLabel)
            make.top.equalTo(timeLabel.snp.bottom).offset(2)
        }
        
        messageIndicator.snp.makeConstraints { make in
            make.right.equalTo(durationLabel.snp.left).offset(-Spacing.small)
            make.bottom.equalTo(durationLabel)
            make.size.equalTo(20)
        }
        
        messageIconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    
    func configure(with callRecord: CallRecord) {
        // Profile icon based on gender
        profileIconLabel.text = callRecord.partnerGender == .male ? "👨" : "👩"
        
        // Nickname
        nicknameLabel.text = callRecord.partnerNickname
        
        // Details (age and region if available)
        var details: [String] = []
        if let age = callRecord.partnerAge {
            details.append("\(age)歳")
        }
        if let region = callRecord.partnerRegion {
            details.append(region)
        }
        detailsLabel.text = details.joined(separator: " • ")
        
        // Time
        timeLabel.text = formatTime(callRecord.timestamp)
        
        // Duration
        durationLabel.text = formatDuration(callRecord.duration)
        
        // Message indicator
        messageIndicator.isHidden = !callRecord.hasMessages
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
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