# 📱 iOS実機テスト接続手順

## 問題：iPhoneからローカルサーバーに接続できない

### 解決策1: Wi-Fi接続確認
1. **Mac と iPhone が同じWi-Fiネットワークに接続されているか確認**
2. **iPhone Safari で以下にアクセス:**
   - http://192.168.0.8:3000/mobile_test.html
   - http://192.168.0.8:3000/network_debug.html

### 解決策2: Mac側でホットスポット作成
1. **システム設定 > 一般 > 共有 > インターネット共有**
2. **"共有する接続経路": Wi-Fi を選択**
3. **"相手のコンピュータでの使用ポート": iPhone USB を選択**
4. **インターネット共有を有効にする**

### 解決策3: ngrok使用（外部トンネル）
```bash
# ngrokインストール (Homebrew使用)
brew install ngrok

# ローカルサーバーを外部公開
ngrok http 3000
```

### 解決策4: iOS Simulatorでの代替テスト
Xcodeで以下のシミュレーターを使用：
- iPhone 15 (iOS 18.6)
- ローカルホスト接続: http://127.0.0.1:3000

### 解決策5: HTTPSサーバーセットアップ
iOSがHTTPS要求している可能性のため、HTTPS対応:

```javascript
// Express with HTTPS
const https = require('https');
const fs = require('fs');

// 自己署名証明書生成
// openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

## 推奨テスト順序：
1. ✅ ブラウザテスト (Mac) - 既に動作確認済み
2. 🔄 iPhone Wi-Fi接続テスト
3. 📱 iOS Simulatorテスト  
4. 🌐 ngrok外部公開テスト
5. 🔒 HTTPS対応テスト

## 現在の設定:
- **サーバーIP**: 192.168.0.8:3000
- **テストページ**: /mobile_test.html, /network_debug.html
- **WebSocket**: ws://192.168.0.8:3000/signaling
- **iOS Info.plist**: HTTP許可設定済み