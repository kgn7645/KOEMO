# Railway デプロイ後の iOS アプリ更新手順

## 1. Railway URL の取得

Railway ダッシュボードで以下を確認：
- アプリURL: `https://[your-app-name].railway.app`
- 例: `https://koemo-backend-production.railway.app`

## 2. iOS アプリの更新

### WebSocketService.swift の更新

`ios/KOEMO/Services/WebSocketService.swift` の42行目を更新：

```swift
// 変更前
guard let url = URL(string: "ws://192.168.0.8:3000?token=\(token)") else {

// 変更後（実際のRailway URLに置き換え）
guard let url = URL(string: "wss://[your-app-name].railway.app?token=\(token)") else {
```

**重要な変更点:**
- `ws://` → `wss://` (SSL必須)
- `192.168.0.8:3000` → `[your-app-name].railway.app` (Railwayの実際のURL)

## 3. テスト手順

### サーバーの動作確認
```bash
# ブラウザで以下にアクセス
https://[your-app-name].railway.app/health

# 期待レスポンス
{"status":"OK","timestamp":"2024-01-XX...","uptime":123}
```

### WebSocket接続テスト
ブラウザの開発者ツールで：
```javascript
const ws = new WebSocket('wss://[your-app-name].railway.app?token=test123');
ws.onopen = () => console.log('✅ Connected');
ws.onmessage = (e) => console.log('📨 Message:', e.data);
ws.onerror = (e) => console.log('❌ Error:', e);
```

## 4. iOS アプリでのテスト

### 2台の iPhone/シミュレーターで
1. 両方のアプリでWebSocket接続成功を確認
2. 通話ボタンをタップしてマッチング開始
3. マッチング成功後、通話画面に遷移
4. 音声通話の開始を確認

### ログの確認
- iOS: Xcodeコンソールで `✅ WebSocket connected` を確認
- Railway: ダッシュボードでリアルタイムログを確認

## 5. トラブルシューティング

### WebSocket接続エラー
```
❌ WebSocket connection failed
```
- Railway URLが正しいか確認
- `wss://` (HTTPS) を使用しているか確認
- Railway アプリが起動しているか確認

### マッチングしない
```
⏰ Matching timeout
```
- 2台目のアプリが起動しているか確認
- Railway ログでマッチング処理を確認
- 同時に通話ボタンを押しているか確認

### 音声が聞こえない
```
🔇 No audio
```
- マイクの権限が許可されているか確認
- WebRTC接続が成功しているか確認
- 音量設定を確認

## 6. パフォーマンス監視

### Railway ダッシュボードで確認
- CPU 使用率
- メモリ使用率  
- ネットワーク通信量
- アクティブ接続数

### 無料枠の制限
- 月500時間まで
- 同時接続数に制限あり
- 1日約16時間まで使用可能

## 7. 次のステップ

### 成功時
- より多くのユーザーでテスト
- 通話品質の確認
- 障害時の動作確認

### 問題がある場合
- Railway ログの詳細確認
- WebRTC接続状態の詳細分析
- ネットワーク環境の確認

---

**デプロイ完了！** 🎉

これで全世界からアクセス可能な音声通話アプリが完成しました！