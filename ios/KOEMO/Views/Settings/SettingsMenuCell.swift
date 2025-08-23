import UIKit
import SnapKit

class SettingsMenuCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .koemoBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoBody
        label.textColor = .koemoText
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCaption1
        label.textColor = .koemoSecondaryText
        label.numberOfLines = 0
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
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(chevronImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(Spacing.medium)
            make.top.equalToSuperview().offset(Spacing.medium)
            make.right.equalTo(chevronImageView.snp.left).offset(-Spacing.small)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.right.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-Spacing.medium)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
    }
    
    // MARK: - Configuration
    
    func configure(title: String, subtitle: String?, icon: String?, textColor: UIColor? = nil) {
        titleLabel.text = title
        titleLabel.textColor = textColor ?? .koemoText
        
        if let subtitle = subtitle, !subtitle.isEmpty {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.isHidden = true
        }
        
        if let iconName = icon {
            iconImageView.image = UIImage(systemName: iconName)
            iconImageView.isHidden = false
            iconImageView.tintColor = textColor ?? .koemoBlue
        } else {
            iconImageView.isHidden = true
        }
        
        // Remove and recreate title constraints to avoid conflicts
        titleLabel.snp.removeConstraints()
        
        // Update constraints safely on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let leftAnchor = self.iconImageView.isHidden ? 
                self.snp.left : self.iconImageView.snp.right
            let leftOffset = self.iconImageView.isHidden ? 
                Spacing.medium : Spacing.medium
            
            if let subtitle = subtitle, !subtitle.isEmpty {
                // Update title constraint
                self.titleLabel.snp.makeConstraints { make in
                    make.left.equalTo(leftAnchor).offset(leftOffset)
                    make.top.equalToSuperview().offset(Spacing.small)
                    make.right.equalTo(self.chevronImageView.snp.left).offset(-Spacing.small)
                }
            } else {
                // Center title vertically
                self.titleLabel.snp.makeConstraints { make in
                    make.left.equalTo(leftAnchor).offset(leftOffset)
                    make.centerY.equalToSuperview()
                    make.right.equalTo(self.chevronImageView.snp.left).offset(-Spacing.small)
                }
            }
        }
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