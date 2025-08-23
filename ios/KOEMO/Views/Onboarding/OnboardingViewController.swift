import UIKit
import SnapKit
import Alamofire
import Network

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
        print("🚀🚀🚀 START BUTTON TAPPED - BEGIN REGISTRATION PROCESS 🚀🚀🚀")
        
        guard validateInput() else { 
            print("❌ Validation failed - stopping registration")
            return 
        }
        
        startButton.setLoading(true)
        
        // iOS 14+ Local Network Permission を事前に要求
        print("🌐 Requesting Local Network Permission...")
        requestLocalNetworkPermission { [weak self] granted in
            print("🌐 Local Network Permission result: \(granted)")
            if granted {
                print("✅ Local Network Permission granted - proceeding with registration")
                self?.proceedWithRegistration()
            } else {
                print("❌ Local Network Permission denied - showing instructions")
                self?.showLocalNetworkPermissionAlert()
            }
        }
    }
    
    private func proceedWithRegistration() {
        // Create user profile
        let profile = createUserProfile()
        
        // Register user with API
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        print("📡 Starting API registration...")
        print("Device ID: \(deviceId)")
        print("Profile: \(profile)")
        print("🌍 Will attempt to connect to: http://192.168.0.8:3000/api/register")
        
        registerWithAPI(deviceId: deviceId, profile: profile)
    }
    
    private func showLocalNetworkPermissionAlert() {
        startButton.setLoading(false)
        
        let instructions = """
        ローカルネットワーク許可が必要です:
        
        1. 設定アプリを開く
        2. プライバシーとセキュリティ
        3. ローカルネットワーク
        4. KOEMO をオンにする
        
        または、アプリを再起動して許可ダイアログを表示してください。
        """
        
        let alert = UIAlertController(
            title: "ローカルネットワーク許可が必要",
            message: instructions,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "設定を開く", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "再試行", style: .default) { _ in
            self.startButtonTapped()
        })
        
        alert.addAction(UIAlertAction(title: "オフライン続行", style: .cancel) { _ in
            self.proceedWithRegistration()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Local Network Permission
    
    private func requestLocalNetworkPermission(completion: @escaping (Bool) -> Void) {
        print("🌐 Requesting Local Network Permission...")
        
        let parameters = NWParameters()
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        
        let browserDescriptor = NWBrowser.Descriptor.bonjour(type: "_http._tcp", domain: "local.")
        let browser = NWBrowser(for: browserDescriptor, using: parameters)
        
        var hasCompleted = false
        
        browser.stateUpdateHandler = { state in
            if hasCompleted { return }
            
            print("🌐 Browser state: \(state)")
            switch state {
            case .ready:
                print("✅ Local Network Browser ready - permission likely granted")
                hasCompleted = true
                browser.cancel()
                DispatchQueue.main.async {
                    completion(true)
                }
            case .failed(let error):
                print("❌ Local Network Browser failed: \(error)")
                hasCompleted = true
                browser.cancel()
                DispatchQueue.main.async {
                    completion(false)
                }
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { results, changes in
            print("🌐 Found \(results.count) local services")
        }
        
        browser.start(queue: DispatchQueue.main)
        
        // タイムアウト処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if !hasCompleted {
                print("⏰ Browser timeout - assuming permission denied")
                hasCompleted = true
                browser.cancel()
                completion(false)
            }
        }
    }
    
    // MARK: - Network Diagnostics
    
    private func testWithURLSession(deviceId: String, profile: UserProfile) {
        print("🔬 Testing with URLSession directly...")
        
        guard let url = URL(string: "http://192.168.0.8:3000/api/register") else {
            print("🔬 Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let requestData: [String: Any] = [
            "deviceId": deviceId,
            "nickname": profile.nickname,
            "gender": profile.gender.rawValue,
            "age": profile.age as Any,
            "region": profile.region as Any
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
            print("🔬 URLSession request created with body: \(requestData)")
        } catch {
            print("🔬 Failed to serialize JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print("🔬 URLSession response received!")
            
            if let error = error {
                print("🔬 URLSession error: \(error)")
                if let urlError = error as? URLError {
                    print("🔬 URLError code: \(urlError.code)")
                }
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔬 URLSession status: \(httpResponse.statusCode)")
                print("🔬 URLSession headers: \(httpResponse.allHeaderFields)")
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("🔬 URLSession response data: \(responseString)")
            }
        }
        
        print("🔬 Starting URLSession task...")
        task.resume()
    }
    
    private func checkWiFiConnectivity() -> String {
        let reachability = NetworkReachabilityManager()
        guard let isReachable = reachability?.isReachable else {
            return "Unknown"
        }
        
        if isReachable {
            if reachability?.isReachableOnCellular == true {
                return "Cellular"
            } else if reachability?.isReachableOnEthernetOrWiFi == true {
                return "WiFi/Ethernet"
            } else {
                return "Connected (Unknown Type)"
            }
        } else {
            return "Not Connected"
        }
    }
    
    // MARK: - API Registration
    
    private func registerWithAPI(deviceId: String, profile: UserProfile) {
        let baseURL = "http://192.168.0.8:3000/api"
        
        // Basic network check
        print("🌐 Starting network test...")
        print("🌐 Device network info:")
        print("   WiFi accessible: \(checkWiFiConnectivity())")
        
        // First, try a simple connectivity test
        print("🏥 Attempting health check to: http://192.168.0.8:3000/health")
        AF.request("http://192.168.0.8:3000/health")
            .response { response in
                print("🏥 Health check complete!")
                print("🏥 Response: \(response.response?.statusCode ?? -1)")
                print("🏥 Data: \(response.data?.count ?? 0) bytes")
                if let error = response.error {
                    print("🏥 Health check error: \(error)")
                    print("🏥 Error localized: \(error.localizedDescription)")
                    if let afError = error as? AFError {
                        print("🏥 AFError details: \(afError)")
                    }
                } else {
                    print("🏥 Health check SUCCESS - network is working!")
                }
            }
        
        let parameters: [String: Any] = [
            "deviceId": deviceId,
            "nickname": profile.nickname,
            "gender": profile.gender.rawValue,
            "age": profile.age as Any,
            "region": profile.region as Any
        ]
        
        print("📡 Attempting API registration to: \(baseURL)/register")
        print("📝 Parameters: \(parameters)")
        print("📱 Device info: \(UIDevice.current.name) - \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
        
        print("📡 Creating Alamofire request...")
        print("📡 URL: \(baseURL)/register")
        print("📡 Method: POST")
        print("📡 Parameters: \(parameters)")
        print("📡 Headers will include: Content-Type: application/json")
        
        // Create session with timeout
        let session = Session.default
        session.sessionConfiguration.timeoutIntervalForRequest = 30
        session.sessionConfiguration.timeoutIntervalForResource = 60
        
        print("📡 Session timeout configured: 30s request, 60s resource")
        
        let request = session.request("\(baseURL)/register",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default)
            .validate()
        
        print("📡 Request created, sending...")
        print("📡 Request object: \(request)")
        
        // Add request interceptor for debugging
        request.cURLDescription { curl in
            print("📡 cURL equivalent: \(curl)")
        }
        
        // Add a timeout fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            print("⏰ 15 second timeout reached - checking if request completed")
        }
        
        request.responseDecodable(of: AuthenticationResponse.self) { [weak self] response in
                print("📨📨📨 RESPONSE RECEIVED 📨📨📨")
                print("📨 Response status code: \(response.response?.statusCode ?? -1)")
                print("📨 Response headers: \(response.response?.allHeaderFields ?? [:])")
                
                // Print request details for debugging
                if let request = response.request {
                    print("📨 Actual request URL: \(request.url?.absoluteString ?? "nil")")
                    print("📨 Request method: \(request.httpMethod ?? "nil")")
                    print("📨 Request headers: \(request.allHTTPHeaderFields ?? [:])")
                }
                
                // Print raw response data for debugging
                if let data = response.data, let rawResponse = String(data: data, encoding: .utf8) {
                    print("📨 Raw response: \(rawResponse)")
                } else {
                    print("📨 No response data received")
                }
                
                // Print detailed error information
                if let error = response.error {
                    print("📨 Error details:")
                    print("   Domain: \(error.localizedDescription)")
                    if let afError = error as? AFError {
                        print("   AFError: \(afError)")
                        print("   Underlying error: \(afError.underlyingError?.localizedDescription ?? "none")")
                    }
                    if let urlError = error as? URLError {
                        print("   URLError code: \(urlError.code)")
                        print("   URLError description: \(urlError.localizedDescription)")
                    }
                }
                
                DispatchQueue.main.async {
                    self?.startButton.setLoading(false)
                    
                    switch response.result {
                    case .success(let authResponse):
                        if authResponse.success {
                            print("✅ API Registration successful: \(authResponse)")
                            // Save user data to UserDefaults
                            if let userData = authResponse.data {
                                UserDefaults.standard.set(userData.userId, forKey: "user_id")
                            }
                            self?.saveProfileToUserDefaults(profile: profile)
                            self?.completeOnboarding()
                        } else {
                            print("❌ API Registration failed: \(authResponse)")
                            self?.showAlert(message: "登録に失敗しました。もう一度お試しください。")
                        }
                    case .failure(let error):
                        print("❌ API Registration error: \(error)")
                        print("❌ Error description: \(error.localizedDescription)")
                        
                        if let afError = error as? AFError {
                            print("❌ AFError: \(afError)")
                            if case .responseValidationFailed(let reason) = afError {
                                print("❌ Validation failed reason: \(reason)")
                            }
                        }
                        
                        // Fallback to local storage on network error
                        self?.handleAPIFailure(deviceId: deviceId, profile: profile)
                    }
                }
            }
    }
    
    private func handleAPIFailure(deviceId: String, profile: UserProfile) {
        print("🔄🔄🔄 API FAILED - ENTERING OFFLINE MODE 🔄🔄🔄")
        print("🔄 This means the network request to server failed")
        print("🔄 Device ID: \(deviceId)")
        print("🔄 Profile: \(profile)")
        
        let testUserId = "offline_user_" + deviceId.prefix(8)
        UserDefaults.standard.set(testUserId, forKey: "user_id")
        saveProfileToUserDefaults(profile: profile)
        
        // Show warning but continue
        let alert = UIAlertController(
            title: "オフラインモード",
            message: "ネットワーク接続がないため、オフラインで登録しました。詳細はXcodeコンソールを確認してください。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.completeOnboarding()
        })
        present(alert, animated: true)
    }
    
    private func saveProfileToUserDefaults(profile: UserProfile) {
        UserDefaults.standard.set(profile.nickname, forKey: "user_nickname")
        UserDefaults.standard.set(profile.gender.rawValue, forKey: "user_gender")
        if let age = profile.age {
            UserDefaults.standard.set(age, forKey: "user_age")
        }
        if let region = profile.region {
            UserDefaults.standard.set(region, forKey: "user_region")
        }
        
        print("💾 Saved complete profile to UserDefaults:")
        print("   Nickname: \(profile.nickname)")
        print("   Gender: \(profile.gender.rawValue)")
        print("   Age: \(profile.age ?? 0)")
        print("   Region: \(profile.region ?? "未設定")")
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
        // Mark onboarding as completed
        // TODO: Re-enable AuthService when available
        // AuthService.shared.completeOnboarding()
        
        print("✅ Registration successful - switching to main interface")
        
        // Switch to main interface
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.switchToMainInterface()
        } else {
            print("❌ SceneDelegate not found - cannot switch interface")
            // Fallback: show success message
            let alert = UIAlertController(
                title: "✅ 登録成功",
                message: "登録が完了しました。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
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