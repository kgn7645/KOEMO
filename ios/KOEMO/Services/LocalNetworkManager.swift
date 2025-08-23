import Foundation
import Network
import NetworkExtension

class LocalNetworkManager: NSObject {
    static let shared = LocalNetworkManager()
    
    private var browser: NWBrowser?
    private var listener: NWListener?
    private var isLocalNetworkPermissionGranted = false
    
    override init() {
        super.init()
    }
    
    /// iOS 14+ Local Network Permission を明示的にトリガーする
    func requestLocalNetworkPermission(completion: @escaping (Bool) -> Void) {
        print("🌐 Local Network Permission を要求中...")
        
        // Method 1: Bonjour Browser でローカルネットワーク許可をトリガー
        let parameters = NWParameters()
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        
        let browserDescriptor = NWBrowser.Descriptor.bonjour(type: "_http._tcp", domain: "local.")
        browser = NWBrowser(for: browserDescriptor, using: parameters)
        
        browser?.stateUpdateHandler = { state in
            print("🌐 Browser state: \(state)")
            switch state {
            case .ready:
                print("✅ Local Network Browser ready - permission likely granted")
                self.isLocalNetworkPermissionGranted = true
                DispatchQueue.main.async {
                    completion(true)
                }
            case .failed(let error):
                print("❌ Local Network Browser failed: \(error)")
                // Try alternative method
                self.tryAlternativeNetworkAccess(completion: completion)
            default:
                break
            }
        }
        
        browser?.browseResultsChangedHandler = { results, changes in
            print("🌐 Found \(results.count) local services")
            for result in results {
                print("  - \(result.endpoint)")
            }
        }
        
        browser?.start(queue: DispatchQueue.main)
        
        // タイムアウト処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if !self.isLocalNetworkPermissionGranted {
                print("⏰ Browser timeout - trying alternative method")
                self.tryAlternativeNetworkAccess(completion: completion)
            }
        }
    }
    
    private func tryAlternativeNetworkAccess(completion: @escaping (Bool) -> Void) {
        print("🔄 Alternative method: Direct UDP connection attempt")
        
        // Method 2: UDP Socket で直接アクセス試行
        let queue = DispatchQueue(label: "local-network-test")
        queue.async {
            let connection = NWConnection(
                host: NWEndpoint.Host("192.168.0.8"),
                port: NWEndpoint.Port(3000)!,
                using: .tcp
            )
            
            connection.stateUpdateHandler = { state in
                print("🔄 Direct connection state: \(state)")
                switch state {
                case .ready:
                    print("✅ Direct connection successful")
                    self.isLocalNetworkPermissionGranted = true
                    connection.cancel()
                    DispatchQueue.main.async {
                        completion(true)
                    }
                case .failed(let error):
                    print("❌ Direct connection failed: \(error)")
                    connection.cancel()
                    DispatchQueue.main.async {
                        completion(false)
                    }
                default:
                    break
                }
            }
            
            connection.start(queue: queue)
            
            // タイムアウト
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if connection.state != .ready {
                    print("⏰ Direct connection timeout")
                    connection.cancel()
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        }
    }
    
    /// ローカルネットワーク許可状態をチェック
    func checkLocalNetworkPermission() -> Bool {
        return isLocalNetworkPermissionGranted
    }
    
    /// リソースをクリーンアップ
    func cleanup() {
        browser?.cancel()
        listener?.cancel()
        browser = nil
        listener = nil
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - 手動許可プロンプト用のヘルパー
extension LocalNetworkManager {
    
    /// ユーザーに手動でLocal Network許可を求める
    func showLocalNetworkPermissionInstructions() -> String {
        return """
        ローカルネットワーク許可が必要です:
        
        1. 設定アプリを開く
        2. プライバシーとセキュリティ
        3. ローカルネットワーク
        4. KOEMO をオンにする
        
        または、アプリを再起動して許可ダイアログを表示してください。
        """
    }
}