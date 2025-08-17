import UIKit
import SnapKit

class ChatCallInfoCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoTertiaryBackground
        view.layer.cornerRadius = CornerRadius.medium
        return view
    }()
    
    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.text = "📞"
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoBodyBold
        label.textColor = .koemoText
        return label
    }()
    
    private lazy var detailsLabel: UILabel = {
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
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(detailsLabel)
        containerView.addSubview(timeLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Spacing.small)
            make.left.right.equalToSuperview().inset(Spacing.medium)
        }
        
        iconLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Spacing.medium)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconLabel.snp.right).offset(Spacing.small)
            make.top.equalToSuperview().offset(Spacing.small)
            make.right.equalTo(timeLabel.snp.left).offset(-Spacing.small)
        }
        
        detailsLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.right.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-Spacing.small)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Spacing.medium)
            make.top.equalToSuperview().offset(Spacing.small)
            make.width.equalTo(80)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with callInfo: CallInfo, partnerName: String) {
        titleLabel.text = "\(partnerName)との通話"
        
        var details = "通話時間: \(formatDuration(callInfo.duration))"
        if let gender = callInfo.partnerGender, let age = callInfo.partnerAge {
            details += "\n\(gender.displayName) • \(age)歳"
            if let region = callInfo.partnerRegion {
                details += " • \(region)"
            }
        }
        
        detailsLabel.text = details
        timeLabel.text = formatDateTime(callInfo.timestamp)
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
        
        if Calendar.current.isToday(date) {
            formatter.dateFormat = "今日 HH:mm"
        } else if Calendar.current.isYesterday(date) {
            formatter.dateFormat = "昨日 HH:mm"
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
        }
        
        return formatter.string(from: date)
    }
}