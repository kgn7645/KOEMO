import UIKit

// MARK: - Color Palette

extension UIColor {
    // Primary Colors
    static let koemoBlue = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // #007AFF
    static let koemoGreen = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0) // #34C759
    static let koemoRed = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0) // #FF3B30
    
    // Background Colors
    static let koemoBackground = UIColor.systemBackground
    static let koemoSecondaryBackground = UIColor.secondarySystemBackground
    static let koemoTertiaryBackground = UIColor.tertiarySystemBackground
    
    // Text Colors
    static let koemoText = UIColor.label
    static let koemoSecondaryText = UIColor.secondaryLabel
    static let koemoTertiaryText = UIColor.tertiaryLabel
    
    // Accent Colors
    static let koemoCallButton = koemoBlue
    static let koemoAccept = koemoGreen
    static let koemoReject = koemoRed
    static let koemoWarning = UIColor.systemOrange
}

// MARK: - Typography

extension UIFont {
    // Display Fonts
    static let koemoTitle1 = UIFont.systemFont(ofSize: 28, weight: .bold)
    static let koemoTitle2 = UIFont.systemFont(ofSize: 22, weight: .bold)
    static let koemoTitle3 = UIFont.systemFont(ofSize: 20, weight: .semibold)
    
    // Body Fonts
    static let koemoBody = UIFont.systemFont(ofSize: 17, weight: .regular)
    static let koemoBodyBold = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let koemoCallout = UIFont.systemFont(ofSize: 16, weight: .regular)
    
    // Small Fonts
    static let koemoCaption1 = UIFont.systemFont(ofSize: 12, weight: .regular)
    static let koemoCaption2 = UIFont.systemFont(ofSize: 11, weight: .regular)
    static let koemoFootnote = UIFont.systemFont(ofSize: 13, weight: .regular)
    
    // Special Fonts
    static let koemoTimer = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .medium)
    static let koemoButton = UIFont.systemFont(ofSize: 17, weight: .semibold)
}

// MARK: - Spacing

struct Spacing {
    static let extraSmall: CGFloat = 2
    static let tiny: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    static let huge: CGFloat = 48
}

// MARK: - Corner Radius

struct CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 24
    static let circle: CGFloat = 50 // For circular buttons
}

// MARK: - Shadow

struct Shadow {
    static let light = (
        color: UIColor.black.withAlphaComponent(0.1),
        offset: CGSize(width: 0, height: 2),
        radius: CGFloat(4),
        opacity: Float(1.0)
    )
    
    static let medium = (
        color: UIColor.black.withAlphaComponent(0.2),
        offset: CGSize(width: 0, height: 4),
        radius: CGFloat(8),
        opacity: Float(1.0)
    )
    
    static let heavy = (
        color: UIColor.black.withAlphaComponent(0.3),
        offset: CGSize(width: 0, height: 8),
        radius: CGFloat(16),
        opacity: Float(1.0)
    )
}

// MARK: - Animation

struct Animation {
    static let quick: TimeInterval = 0.2
    static let standard: TimeInterval = 0.3
    static let slow: TimeInterval = 0.5
    
    static let spring = UISpringTimingParameters(
        dampingRatio: 0.8,
        initialVelocity: CGVector(dx: 0, dy: 0)
    )
}

// MARK: - Button Sizes

struct ButtonSize {
    static let small = CGSize(width: 120, height: 44)
    static let medium = CGSize(width: 160, height: 48)
    static let large = CGSize(width: 200, height: 56)
    static let callButton = CGSize(width: 120, height: 120) // Circular call button
}