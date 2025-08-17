import UIKit
import SnapKit

class SettingsProfileCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var profileImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBlue.withAlphaComponent(0.2)
        view.layer.cornerRadius = 30
        return view
    }()
    
    private lazy var profileIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoTitle3
        label.textColor = .koemoText
        return label
    }()
    
    private lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        return label
    }()
    
    private lazy var editLabel: UILabel = {
        let label = UILabel()
        label.text = "編集"
        label.font = .koemoCallout
        label.textColor = .koemoBlue
        return label
    }()
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .koemoTertiaryText
        imageView.contentMode = .scaleAspectFit
        return imageView
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
        backgroundColor = .koemoSecondaryBackground
        accessoryType = .none
        
        contentView.addSubview(profileImageView)
        profileImageView.addSubview(profileIconLabel)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(detailsLabel)
        contentView.addSubview(editLabel)
        contentView.addSubview(chevronImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        profileImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(60)
        }
        
        profileIconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        nicknameLabel.snp.makeConstraints { make in
            make.left.equalTo(profileImageView.snp.right).offset(Spacing.medium)
            make.top.equalTo(profileImageView).offset(8)
            make.right.equalTo(editLabel.snp.left).offset(-Spacing.small)
        }
        
        detailsLabel.snp.makeConstraints { make in
            make.left.equalTo(nicknameLabel)
            make.top.equalTo(nicknameLabel.snp.bottom).offset(4)
            make.right.equalTo(nicknameLabel)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        
        editLabel.snp.makeConstraints { make in
            make.right.equalTo(chevronImageView.snp.left).offset(-Spacing.small)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    
    func configure(with profile: UserProfile?) {
        guard let profile = profile else {
            nicknameLabel.text = "プロフィール未設定"
            detailsLabel.text = "タップして設定してください"
            profileIconLabel.text = "👤"
            return
        }
        
        nicknameLabel.text = profile.nickname
        
        // Profile icon based on gender
        profileIconLabel.text = profile.gender == .male ? "👨" : "👩"
        
        // Details
        var details: [String] = []
        if let age = profile.age {
            details.append("\(age)歳")
        }
        details.append(profile.gender.displayName)
        if let region = profile.region {
            details.append(region)
        }
        
        detailsLabel.text = details.joined(separator: " • ")
    }
    
    // MARK: - Animation
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.1) {
            self.transform = highlighted ? 
                CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            self.alpha = highlighted ? 0.8 : 1.0
        }
    }
}