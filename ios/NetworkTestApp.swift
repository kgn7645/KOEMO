import UIKit
import Alamofire

class NetworkTestViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let button = UIButton(type: .system)
        button.setTitle("ネットワークテスト", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(testNetwork), for: .touchUpInside)
        
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func testNetwork() {
        print("🚀🚀🚀 NETWORK TEST STARTED 🚀🚀🚀")
        
        // Test with URLSession first
        testWithURLSession()
        
        // Test with Alamofire
        testWithAlamofire()
    }
    
    func testWithURLSession() {
        print("🔬 Testing with URLSession...")
        
        guard let url = URL(string: "http://192.168.0.8:3000/health") else {
            print("🔬 Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            print("🔬 URLSession response received!")
            
            if let error = error {
                print("🔬 URLSession error: \(error)")
                if let urlError = error as? URLError {
                    print("🔬 URLError code: \(urlError.code)")
                    print("🔬 URLError description: \(urlError.localizedDescription)")
                }
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔬 URLSession status: \(httpResponse.statusCode)")
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("🔬 URLSession response: \(responseString)")
            }
        }
        
        print("🔬 Starting URLSession task...")
        task.resume()
    }
    
    func testWithAlamofire() {
        print("📡 Testing with Alamofire...")
        
        AF.request("http://192.168.0.8:3000/health")
            .response { response in
                print("📡 Alamofire response received!")
                print("📡 Status: \(response.response?.statusCode ?? -1)")
                
                if let error = response.error {
                    print("📡 Alamofire error: \(error)")
                    print("📡 Error description: \(error.localizedDescription)")
                }
                
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print("📡 Alamofire response: \(responseString)")
                }
            }
    }
}

// For testing in a simple app
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = NetworkTestViewController()
        window?.makeKeyAndVisible()
        return true
    }
}