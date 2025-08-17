import UIKit
import SnapKit

class OnboardingViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "KOEMO"
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textColor = .koemoBlue
        label.textAlignment = .center
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "プロフィール設定"
        label.font = .koemoTitle1
        label.textColor = .koemoText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "ランダム通話を始めるために\n基本情報を入力してください"
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Form Components
    
    private lazy var nicknameTextField: UITextField = {
        let textField = createTextField(placeholder: "ニックネーム（1-20文字）")
        textField.delegate = self
        return textField
    }()
    
    private lazy var genderSegmentedControl: UISegmentedControl = {
        let items = UserProfile.Gender.allCases.map { $0.displayName }
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = .koemoSecondaryBackground
        control.selectedSegmentTintColor = .koemoBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.koemoText], for: .normal)
        return control
    }()
    
    private lazy var ageTextField: UITextField = {
        let textField = createTextField(placeholder: "年齢（18歳以上）")
        textField.keyboardType = .numberPad
        textField.delegate = self
        return textField
    }()
    
    private lazy var regionTextField: UITextField = {
        let textField = createTextField(placeholder: "地域（任意）")
        textField.delegate = self
        return textField
    }()
    
    private lazy var startButton: KoemoButton = {
        let button = KoemoButton(title: "始める", style: .primary, size: .large)
        button.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private lazy var termsLabel: UILabel = {
        let label = UILabel()
        label.text = "続行することで、利用規約とプライバシーポリシーに同意したものとみなされます"
        label.font = .koemoCaption1
        label.textColor = .koemoTertiaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Properties
    
    private var keyboardHeight: CGFloat = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardNotifications()
        
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure navigation bar stays hidden
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .koemoBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add all UI components to content view
        [logoLabel, titleLabel, subtitleLabel, 
         createFormSection(title: "ニックネーム", content: nicknameTextField),
         createFormSection(title: "性別", content: genderSegmentedControl),
         createFormSection(title: "年齢", content: ageTextField),
         createFormSection(title: "地域", content: regionTextField),
         startButton, termsLabel].forEach {
            contentView.addSubview($0)
        }
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        logoLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.huge)
            make.centerX.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoLabel.snp.bottom).offset(Spacing.large)
            make.centerX.equalToSuperview()
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.medium)
            make.left.right.equalToSuperview().inset(Spacing.large)
        }
        
        // Form sections
        let formSections = contentView.subviews.compactMap { $0 as? UIStackView }
        for (index, section) in formSections.enumerated() {
            section.snp.makeConstraints { make in
                if index == 0 {
                    make.top.equalTo(subtitleLabel.snp.bottom).offset(Spacing.extraLarge)
                } else {
                    make.top.equalTo(formSections[index - 1].snp.bottom).offset(Spacing.large)
                }
                make.left.right.equalToSuperview().inset(Spacing.large)
            }
        }
        
        startButton.snp.makeConstraints { make in
            if let lastSection = formSections.last {
                make.top.equalTo(lastSection.snp.bottom).offset(Spacing.extraLarge)
            } else {
                make.top.equalTo(subtitleLabel.snp.bottom).offset(Spacing.extraLarge)
            }
            make.centerX.equalToSuperview()
        }
        
        termsLabel.snp.makeConstraints { make in
            make.top.equalTo(startButton.snp.bottom).offset(Spacing.large)
            make.left.right.equalToSuperview().inset(Spacing.large)
            make.bottom.equalToSuperview().offset(-Spacing.large)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = .koemoBody
        textField.textColor = .koemoText
        textField.backgroundColor = .koemoSecondaryBackground
        textField.layer.cornerRadius = CornerRadius.medium
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Spacing.medium, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: Spacing.medium, height: 0))
        textField.rightViewMode = .always
        textField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        return textField
    }
    
    private func createFormSection(title: String, content: UIView) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .koemoBodyBold
        titleLabel.textColor = .koemoText
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, content])
        stackView.axis = .vertical
        stackView.spacing = Spacing.small
        stackView.alignment = .fill
        
        return stackView
    }
    
    // MARK: - Validation
    
    private func validateForm() {
        let nickname = nicknameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let ageText = ageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let isNicknameValid = nickname.count >= 1 && nickname.count <= 20
        let isAgeValid = Int(ageText) ?? 0 >= 18
        
        startButton.isEnabled = isNicknameValid && isAgeValid
    }
    
    // MARK: - Actions
    
    @objc private func startButtonTapped() {
        guard validateInput() else { return }
        
        startButton.setLoading(true)
        
        // Create user profile
        let profile = createUserProfile()
        
        // TODO: Send registration request to backend
        // For now, simulate success after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startButton.setLoading(false)
            self.completeOnboarding()
        }
    }
    
    private func validateInput() -> Bool {
        let nickname = nicknameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let ageText = ageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        // Validate nickname
        if nickname.isEmpty || nickname.count > 20 {
            showAlert(message: "ニックネームは1〜20文字で入力してください")
            return false
        }
        
        // Validate age
        guard let age = Int(ageText), age >= 18 else {
            showAlert(message: "年齢は18歳以上で入力してください")
            return false
        }
        
        return true
    }
    
    private func createUserProfile() -> UserProfile {
        let nickname = nicknameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let genderIndex = genderSegmentedControl.selectedSegmentIndex
        let gender = UserProfile.Gender.allCases[genderIndex]
        let age = Int(ageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        let region = regionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return UserProfile(
            nickname: nickname,
            gender: gender,
            age: age,
            region: region?.isEmpty == true ? nil : region
        )
    }
    
    private func completeOnboarding() {
        // Mark user as authenticated
        UserDefaults.standard.set(true, forKey: "user_authenticated")
        
        // Switch to main interface
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchToMainInterface()
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "入力エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate

extension OnboardingViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        // Validate character limits
        if textField == nicknameTextField {
            if updatedText.count > 20 { return false }
        } else if textField == ageTextField {
            // Only allow numbers
            if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
                return false
            }
            if updatedText.count > 3 { return false }
        }
        
        // Trigger validation after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.validateForm()
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nicknameTextField:
            ageTextField.becomeFirstResponder()
        case ageTextField:
            regionTextField.becomeFirstResponder()
        case regionTextField:
            textField.resignFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}