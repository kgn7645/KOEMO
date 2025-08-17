import UIKit
import SnapKit

class BlockedUserCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        view.layer.cornerRadius = CornerRadius.medium
        return view
    }()
    
    private lazy var profileImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoRed.withAlphaComponent(0.2)
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
    
    private lazy var blockedDateLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption2
        label.textColor = .koemoTertiaryText
        label.textAlignment = .right
        return label
    }()
    
    private lazy var blockedIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoRed
        view.layer.cornerRadius = 4
        return view
    }()
    
    private lazy var blockedLabel: UILabel = {
        let label = UILabel()
        label.text = "ブロック中"
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
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
        containerView.addSubview(blockedDateLabel)
        containerView.addSubview(blockedIndicator)
        blockedIndicator.addSubview(blockedLabel)
        
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
            make.right.equalTo(blockedDateLabel.snp.left).offset(-Spacing.small)
        }
        
        detailsLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(2)
            make.right.equalTo(blockedIndicator.snp.left).offset(-Spacing.small)
        }
        
        blockedDateLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.top.equalToSuperview().offset(Spacing.small)
            make.width.equalTo(80)
        }
        
        blockedIndicator.snp.makeConstraints { make in
            make.right.equalTo(blockedDateLabel)
            make.bottom.equalToSuperview().offset(-Spacing.small)
            make.width.equalTo(60)
            make.height.equalTo(16)
        }
        
        blockedLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    
    func configure(with blockedUser: BlockedUser) {
        // Profile icon based on gender (with blocked appearance)
        profileIconLabel.text = blockedUser.gender == .male ? "👨" : "👩"
        
        // Nickname
        nicknameLabel.text = blockedUser.nickname
        
        // Details (age if available)
        var details: [String] = []
        if let age = blockedUser.age {
            details.append("\(age)歳")
        }
        details.append(blockedUser.gender.displayName)
        detailsLabel.text = details.joined(separator: " • ")
        
        // Blocked date
        blockedDateLabel.text = formatDate(blockedUser.blockedDate)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isToday(date) {
            return "今日"
        } else if Calendar.current.isYesterday(date) {
            return "昨日"
        } else {
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
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