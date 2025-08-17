import UIKit
import SnapKit

class FeedbackViewController: UIViewController {
    
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
        label.text = "フィードバック"
        label.font = .koemoTitle2
        label.textColor = .koemoText
        label.textAlignment = .center
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "アプリの改善にご協力ください。\\nご意見やご要望をお聞かせください。"
        label.font = .koemoCallout
        label.textColor = .koemoSecondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var categorySegmentedControl: UISegmentedControl = {
        let items = ["バグ報告", "機能要望", "その他"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = .koemoSecondaryBackground
        control.selectedSegmentTintColor = .koemoBlue
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.koemoText], for: .normal)
        return control
    }()
    
    private lazy var subjectTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "件名を入力してください"
        textField.font = .koemoBody
        textField.textColor = .koemoText
        textField.backgroundColor = .koemoSecondaryBackground
        textField.layer.cornerRadius = CornerRadius.medium
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Spacing.medium, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: Spacing.medium, height: 0))
        textField.rightViewMode = .always
        textField.delegate = self
        return textField
    }()
    
    private lazy var messageTextView: UITextView = {
        let textView = UITextView()
        textView.font = .koemoBody
        textView.textColor = .koemoText
        textView.backgroundColor = .koemoSecondaryBackground
        textView.layer.cornerRadius = CornerRadius.medium
        textView.textContainerInset = UIEdgeInsets(
            top: Spacing.medium,
            left: Spacing.medium,
            bottom: Spacing.medium,
            right: Spacing.medium
        )
        textView.delegate = self
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "詳細を入力してください..."
        label.font = .koemoBody
        label.textColor = .koemoTertiaryText
        return label
    }()
    
    private lazy var sendButton: KoemoButton = {
        let button = KoemoButton(title: "送信", style: .primary, size: .large)
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    // MARK: - Properties
    
    private var keyboardHeight: CGFloat = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardNotifications()
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
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(createFormSection(title: "カテゴリ", content: categorySegmentedControl))
        contentView.addSubview(createFormSection(title: "件名", content: subjectTextField))
        
        let messageSection = createFormSection(title: "詳細", content: messageTextView)
        contentView.addSubview(messageSection)
        messageTextView.addSubview(placeholderLabel)
        
        contentView.addSubview(sendButton)
        
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
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.medium)
            make.left.right.equalToSuperview().inset(Spacing.large)
        }
        
        // Form sections
        let formSections = contentView.subviews.compactMap { $0 as? UIStackView }
        for (index, section) in formSections.enumerated() {
            section.snp.makeConstraints { make in
                if index == 0 {
                    make.top.equalTo(descriptionLabel.snp.bottom).offset(Spacing.extraLarge)
                } else {
                    make.top.equalTo(formSections[index - 1].snp.bottom).offset(Spacing.large)
                }
                make.left.right.equalToSuperview().inset(Spacing.large)
            }
        }
        
        subjectTextField.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        
        messageTextView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Spacing.medium + 8)
            make.left.equalToSuperview().offset(Spacing.medium + 4)
        }
        
        sendButton.snp.makeConstraints { make in
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
    
    // MARK: - Actions
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sendButtonTapped() {
        guard validateInput() else { return }
        
        sendButton.setLoading(true)
        
        // Simulate sending feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendButton.setLoading(false)
            self.showSuccessAlert()
        }
    }
    
    // MARK: - Validation
    
    private func validateInput() -> Bool {
        let subject = subjectTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let message = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if subject.isEmpty {
            showAlert(message: "件名を入力してください")
            return false
        }
        
        if message.isEmpty {
            showAlert(message: "詳細を入力してください")
            return false
        }
        
        return true
    }
    
    private func updateSendButton() {
        let subject = subjectTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let message = messageTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        sendButton.isEnabled = !subject.isEmpty && !message.isEmpty
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "入力エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "送信完了",
            message: "フィードバックを送信しました。\\nご協力ありがとうございます。",
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

extension FeedbackViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateSendButton()
        }
        return true
    }
}

// MARK: - UITextViewDelegate

extension FeedbackViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateSendButton()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}