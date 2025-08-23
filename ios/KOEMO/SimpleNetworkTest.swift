import UIKit
import Alamofire

// Simple network test that can be run from existing app
class SimpleNetworkTest {
    static func runTest() {
        print("🚀🚀🚀 SIMPLE NETWORK TEST STARTED 🚀🚀🚀")
        print("Device: \(UIDevice.current.name)")
        print("iOS: \(UIDevice.current.systemVersion)")
        print("Network: Attempting to connect to 192.168.0.8:3000")
        
        // Test 1: URLSession Health Check
        testHealthWithURLSession()
        
        // Test 2: URLSession Registration
        testRegistrationWithURLSession()
        
        // Test 3: Alamofire Health Check
        testHealthWithAlamofire()
        
        // Test 4: Alamofire Registration
        testRegistrationWithAlamofire()
    }
    
    static func testHealthWithURLSession() {
        print("\n🔬 TEST 1: URLSession Health Check")
        
        guard let url = URL(string: "http://192.168.0.8:3000/health") else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                print("🔬 URLSession Health Response:")
                
                if let error = error {
                    print("❌ Error: \(error)")
                    if let urlError = error as? URLError {
                        print("❌ URLError code: \(urlError.code.rawValue)")
                        print("❌ Description: \(urlError.localizedDescription)")
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Status: \(httpResponse.statusCode)")
                    print("✅ Headers: \(httpResponse.allHeaderFields)")
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("✅ Response: \(responseString)")
                } else {
                    print("❌ No response data")
                }
            }
        }
        
        task.resume()
    }
    
    static func testRegistrationWithURLSession() {
        print("\n🔬 TEST 2: URLSession Registration")
        
        guard let url = URL(string: "http://192.168.0.8:3000/api/register") else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let testData: [String: Any] = [
            "deviceId": "test-ios-device",
            "nickname": "テストユーザー",
            "gender": "male",
            "age": 25
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testData)
        } catch {
            print("❌ JSON serialization error: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                print("🔬 URLSession Registration Response:")
                
                if let error = error {
                    print("❌ Error: \(error)")
                    if let urlError = error as? URLError {
                        print("❌ URLError code: \(urlError.code.rawValue)")
                        print("❌ Description: \(urlError.localizedDescription)")
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Status: \(httpResponse.statusCode)")
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("✅ Response: \(responseString)")
                } else {
                    print("❌ No response data")
                }
            }
        }
        
        task.resume()
    }
    
    static func testHealthWithAlamofire() {
        print("\n📡 TEST 3: Alamofire Health Check")
        
        AF.request("http://192.168.0.8:3000/health")
            .response { response in
                print("📡 Alamofire Health Response:")
                print("✅ Status: \(response.response?.statusCode ?? -1)")
                
                if let error = response.error {
                    print("❌ Error: \(error)")
                    print("❌ Description: \(error.localizedDescription)")
                    if let afError = error as? AFError {
                        print("❌ AFError: \(afError)")
                    }
                }
                
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print("✅ Response: \(responseString)")
                }
            }
    }
    
    static func testRegistrationWithAlamofire() {
        print("\n📡 TEST 4: Alamofire Registration")
        
        let parameters: [String: Any] = [
            "deviceId": "alamofire-ios-device",
            "nickname": "Alamofireテスト",
            "gender": "female",
            "age": 22
        ]
        
        AF.request("http://192.168.0.8:3000/api/register",
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default)
            .response { response in
                print("📡 Alamofire Registration Response:")
                print("✅ Status: \(response.response?.statusCode ?? -1)")
                
                if let error = response.error {
                    print("❌ Error: \(error)")
                    print("❌ Description: \(error.localizedDescription)")
                    if let afError = error as? AFError {
                        print("❌ AFError: \(afError)")
                    }
                }
                
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print("✅ Response: \(responseString)")
                }
                
                print("🏁 ALL TESTS COMPLETED")
            }
    }
}