import UIKit
import SnapKit

class ProfileEditViewController: UIViewController {
    
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
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "プロフィール編集"
        label.font = .koemoTitle2
        label.textColor = .koemoText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var profileImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .koemoBlue.withAlphaComponent(0.2)
        view.layer.cornerRadius = 50
        return view
    }()
    
    private lazy var profileIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        label.textAlignment = .center
        return label
    }()
    
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
        control.addTarget(self, action: #selector(genderChanged), for: .valueChanged)
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
    
    private lazy var saveButton: KoemoButton = {
        let button = KoemoButton(title: "保存", style: .primary, size: .large)
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    private var originalProfile: UserProfile?
    private var keyboardHeight: CGFloat = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardNotifications()
        updateProfileIcon()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .koemoBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(profileImageView)
        profileImageView.addSubview(profileIconLabel)
        contentView.addSubview(createFormSection(title: "ニックネーム", content: nicknameTextField))
        contentView.addSubview(createFormSection(title: "性別", content: genderSegmentedControl))
        contentView.addSubview(createFormSection(title: "年齢", content: ageTextField))
        contentView.addSubview(createFormSection(title: "地域", content: regionTextField))
        contentView.addSubview(saveButton)
        
        setupConstraints()
        setupNavigationBar()
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.large)
            make.centerX.equalToSuperview()
        }
        
        profileImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.large)
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }
        
        profileIconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // Form sections
        let formSections = contentView.subviews.compactMap { $0 as? UIStackView }
        for (index, section) in formSections.enumerated() {
            section.snp.makeConstraints { make in
                if index == 0 {
                    make.top.equalTo(profileImageView.snp.bottom).offset(Spacing.extraLarge)
                } else {
                    make.top.equalTo(formSections[index - 1].snp.bottom).offset(Spacing.large)
                }
                make.left.right.equalToSuperview().inset(Spacing.large)
            }
        }
        
        saveButton.snp.makeConstraints { make in
            if let lastSection = formSections.last {
                make.top.equalTo(lastSection.snp.bottom).offset(Spacing.extraLarge)
            }
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Spacing.large)
        }
    }
    
    private func setupNavigationBar() {
        // Cancel button
        let cancelButton = UIBarButtonItem(
            title: "キャンセル",
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.leftBarButtonItem = cancelButton
    }
    
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
    
    // MARK: - Configuration
    
    func configure(with profile: UserProfile?) {
        originalProfile = profile
        
        guard let profile = profile else { return }
        
        nicknameTextField.text = profile.nickname
        ageTextField.text = profile.age.map { String($0) }
        regionTextField.text = profile.region
        
        // Set gender
        if let genderIndex = UserProfile.Gender.allCases.firstIndex(of: profile.gender) {
            genderSegmentedControl.selectedSegmentIndex = genderIndex
        }
        
        updateProfileIcon()
    }
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard validateInput() else { return }
        
        saveButton.setLoading(true)
        
        // Create updated profile
        let updatedProfile = createUserProfile()
        
        // TODO: Send update request to backend
        // For now, simulate success after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.saveButton.setLoading(false)
            self.showSuccessAlert()
        }
    }
    
    @objc private func genderChanged() {
        updateProfileIcon()
    }
    
    // MARK: - Profile Icon
    
    private func updateProfileIcon() {
        let genderIndex = genderSegmentedControl.selectedSegmentIndex
        let gender = UserProfile.Gender.allCases[genderIndex]
        profileIconLabel.text = gender == .male ? "👨" : "👩"
    }
    
    // MARK: - Validation
    
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
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "入力エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "保存完了",
            message: "プロフィールを更新しました。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })
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

extension ProfileEditViewController: UITextFieldDelegate {
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