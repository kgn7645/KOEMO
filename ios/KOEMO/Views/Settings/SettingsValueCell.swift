import UIKit
import SnapKit

class SettingsValueCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoBody
        label.textColor = .koemoText
        return label
    }()
    
    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .right
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
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(chevronImageView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(valueLabel.snp.left).offset(-Spacing.small)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.right.equalTo(chevronImageView.snp.left).offset(-Spacing.small)
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(150)
        }
    }
    
    // MARK: - Configuration
    
    func configure(title: String, value: String, hasAction: Bool) {
        titleLabel.text = title
        valueLabel.text = value
        chevronImageView.isHidden = !hasAction
        
        if !hasAction {
            // If no action, move value label to the right
            valueLabel.snp.updateConstraints { make in
                make.right.equalToSuperview().offset(-Spacing.medium)
            }
        } else {
            // Reset to normal position
            valueLabel.snp.updateConstraints { make in
                make.right.equalTo(chevronImageView.snp.left).offset(-Spacing.small)
            }
        }
    }
    
    // MARK: - Animation
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        // Only animate if cell has action
        if !chevronImageView.isHidden {
            UIView.animate(withDuration: 0.1) {
                self.transform = highlighted ? 
                    CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                self.alpha = highlighted ? 0.8 : 1.0
            }
        }
    }
}