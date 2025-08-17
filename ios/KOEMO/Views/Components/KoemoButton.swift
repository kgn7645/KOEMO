import UIKit

class KoemoButton: UIButton {
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case call
        case text
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        case call
    }
    
    private var buttonStyle: ButtonStyle = .primary
    private var buttonSize: ButtonSize = .medium
    private var isLoading = false
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    convenience init(title: String, style: ButtonStyle = .primary, size: ButtonSize = .medium) {
        self.init(frame: .zero)
        self.buttonStyle = style
        self.buttonSize = size
        setTitle(title, for: .normal)
        applyStyle()
    }
    
    private func setup() {
        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        applyStyle()
    }
    
    private func applyStyle() {
        // Remove existing constraints if any
        translatesAutoresizingMaskIntoConstraints = false
        
        // Apply size constraints
        switch buttonSize {
        case .small:
            heightAnchor.constraint(equalToConstant: 44).isActive = true
            widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        case .medium:
            heightAnchor.constraint(equalToConstant: 48).isActive = true
            widthAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true
        case .large:
            heightAnchor.constraint(equalToConstant: 56).isActive = true
            widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        case .call:
            heightAnchor.constraint(equalToConstant: 120).isActive = true
            widthAnchor.constraint(equalToConstant: 120).isActive = true
        }
        
        // Apply visual style
        switch buttonStyle {
        case .primary:
            backgroundColor = .koemoBlue
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
            
        case .secondary:
            backgroundColor = .koemoSecondaryBackground
            setTitleColor(.koemoBlue, for: .normal)
            setTitleColor(.koemoBlue.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.koemoSecondaryText, for: .disabled)
            layer.borderWidth = 1
            layer.borderColor = UIColor.koemoBlue.cgColor
            
        case .destructive:
            backgroundColor = .koemoRed
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)
            
        case .call:
            backgroundColor = .koemoBlue
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.7), for: .highlighted)
            layer.cornerRadius = 60 // Make it circular
            
        case .text:
            backgroundColor = .clear
            setTitleColor(.koemoBlue, for: .normal)
            setTitleColor(.koemoBlue.withAlphaComponent(0.7), for: .highlighted)
            setTitleColor(.koemoSecondaryText, for: .disabled)
        }
        
        // Common styling
        if buttonStyle != .call && buttonStyle != .text {
            layer.cornerRadius = CornerRadius.medium
        }
        
        titleLabel?.font = .koemoButton
        
        // Add shadow for non-text buttons
        if buttonStyle != .text {
            applyShadow()
        }
        
        // Accessibility
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
    
    private func applyShadow() {
        layer.shadowColor = Shadow.light.color.cgColor
        layer.shadowOffset = Shadow.light.offset
        layer.shadowRadius = Shadow.light.radius
        layer.shadowOpacity = Shadow.light.opacity
    }
    
    @objc private func buttonTapped() {
        // Add haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        
        // Animation
        UIView.animate(withDuration: Animation.quick, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: Animation.quick) {
                self.transform = .identity
            }
        }
    }
    
    // MARK: - Loading State
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
        isEnabled = !loading
        
        if loading {
            titleLabel?.alpha = 0
            activityIndicator.startAnimating()
        } else {
            titleLabel?.alpha = 1
            activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - Override States
    
    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.6
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: Animation.quick) {
                self.alpha = self.isHighlighted ? 0.8 : 1.0
            }
        }
    }
}