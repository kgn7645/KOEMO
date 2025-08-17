import UIKit
import SnapKit

class SettingsSwitchCell: UITableViewCell {
    
    // MARK: - UI Components
    
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
    
    private lazy var toggleSwitch: UISwitch = {
        let switch = UISwitch()
        switch.onTintColor = .koemoBlue
        switch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        return switch
    }()
    
    // MARK: - Properties
    
    private var switchAction: ((Bool) -> Void)?
    
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
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(toggleSwitch)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.top.equalToSuperview().offset(Spacing.medium)
            make.right.equalTo(toggleSwitch.snp.left).offset(-Spacing.medium)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.right.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-Spacing.medium)
        }
        
        toggleSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    
    func configure(title: String, subtitle: String?, isOn: Bool, action: @escaping (Bool) -> Void) {
        titleLabel.text = title
        toggleSwitch.isOn = isOn
        switchAction = action
        
        if let subtitle = subtitle, !subtitle.isEmpty {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
            
            // Update title constraint for multiline layout
            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(Spacing.small)
            }
        } else {
            subtitleLabel.isHidden = true
            
            // Center title vertically
            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(Spacing.medium)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func switchValueChanged() {
        switchAction?(toggleSwitch.isOn)
        
        // Add haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
    }
}