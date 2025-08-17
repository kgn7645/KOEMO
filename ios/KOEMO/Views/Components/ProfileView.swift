import UIKit

class ProfileView: UIView {
    
    // MARK: - UI Components
    
    private lazy var avatarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoSecondaryBackground
        view.layer.cornerRadius = 40
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var avatarLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoTitle2
        label.textColor = .koemoText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoTitle3
        label.textColor = .koemoText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var ageLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var regionLabel: UILabel = {
        let label = UILabel()
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.small
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Properties
    
    private var currentProfile: UserProfile?
    private var currentDisclosureLevel: Int = 0
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(stackView)
        
        // Avatar container setup
        avatarContainerView.addSubview(avatarLabel)
        
        // Add components to stack view
        stackView.addArrangedSubview(avatarContainerView)
        stackView.addArrangedSubview(nicknameLabel)
        stackView.addArrangedSubview(ageLabel)
        stackView.addArrangedSubview(regionLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Stack view constraints
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Spacing.medium),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Spacing.medium),
            
            // Avatar container constraints
            avatarContainerView.heightAnchor.constraint(equalToConstant: 80),
            avatarContainerView.widthAnchor.constraint(equalToConstant: 80),
            
            // Avatar label constraints
            avatarLabel.centerXAnchor.constraint(equalTo: avatarContainerView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarContainerView.centerYAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(with profile: UserProfile) {
        currentProfile = profile
        updateDisplay()
    }
    
    func updateDisclosureLevel(_ level: Int, animated: Bool = true) {
        currentDisclosureLevel = level
        
        guard let profile = currentProfile else { return }
        
        if animated {
            UIView.animate(withDuration: Animation.standard, delay: 0, options: .curveEaseInOut) {
                self.updateVisibility(for: profile, level: level)
            }
        } else {
            updateVisibility(for: profile, level: level)
        }
    }
    
    private func updateDisplay() {
        guard let profile = currentProfile else { return }
        
        // Always show nickname and avatar
        nicknameLabel.text = profile.nickname
        avatarLabel.text = String(profile.nickname.prefix(1)).uppercased()
        
        // Set age and region text (but visibility is controlled by disclosure level)
        if let age = profile.age {
            ageLabel.text = "\(age)歳"
        }
        
        if let region = profile.region {
            regionLabel.text = region
        }
        
        updateVisibility(for: profile, level: currentDisclosureLevel)
    }
    
    private func updateVisibility(for profile: UserProfile, level: Int) {
        // Level 0: Only nickname (always visible)
        // Level 1: + age (30 seconds)
        // Level 2: + region (60 seconds)
        // Level 3: Full profile (180 seconds)
        
        ageLabel.alpha = (level >= 1 && profile.age != nil) ? 1.0 : 0.0
        regionLabel.alpha = (level >= 2 && profile.region != nil) ? 1.0 : 0.0
    }
    
    // MARK: - Animation Helpers
    
    func showWithAnimation() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: Animation.standard, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func hideWithAnimation(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: Animation.standard, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            completion?()
        }
    }
}