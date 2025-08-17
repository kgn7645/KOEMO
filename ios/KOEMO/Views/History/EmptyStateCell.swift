import UIKit
import SnapKit

class EmptyStateCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var iconView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoTertiaryBackground
        view.layer.cornerRadius = 30
        return view
    }()
    
    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoTitle3
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCallout
        label.textColor = .koemoTertiaryText
        label.textAlignment = .center
        label.numberOfLines = 0
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
        containerView.addSubview(iconView)
        iconView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Spacing.medium)
        }
        
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Spacing.large)
            make.size.equalTo(60)
        }
        
        iconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(Spacing.medium)
            make.centerX.equalToSuperview()
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.small)
            make.left.right.equalToSuperview().inset(Spacing.large)
            make.bottom.lessThanOrEqualToSuperview().offset(-Spacing.large)
        }
    }
    
    // MARK: - Configuration
    
    func configure(title: String, message: String, icon: String) {
        titleLabel.text = title
        messageLabel.text = message
        
        // Set icon based on type
        switch icon {
        case "phone":
            iconLabel.text = "📞"
        case "message":
            iconLabel.text = "💬"
        default:
            iconLabel.text = "📱"
        }
    }
}