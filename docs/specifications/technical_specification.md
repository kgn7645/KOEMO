# KOEMO 技術仕様書

## 1. 概要

KOEMO（コエモ）は、ワンタップでランダムな相手と音声通話ができるiOSアプリケーションです。匿名性を保ちながら、通話時間に応じて段階的にプロフィール情報が開示される独自の仕組みを持っています。

### 1.1 主要機能
- ワンタップランダムマッチング
- WebRTCベースの音声通話
- 段階的プロフィール開示システム
- 24時間で自動削除されるエフェメラルチャット
- 広告/チケット制による収益化

### 1.2 技術スタック
- **Frontend**: iOS (Swift 5.9+)
- **Backend**: Node.js + Express
- **Database**: MongoDB
- **リアルタイム通信**: WebSocket (Socket.io)
- **音声通話**: WebRTC (SkyWay SDK)
- **プッシュ通知**: APNs (PushKit for VoIP)

## 2. システムアーキテクチャ

### 2.1 全体構成
```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│   iOS App   │────▶│   API Server    │────▶│   MongoDB    │
│   (Swift)   │     │   (Node.js)     │     │              │
└─────────────┘     └─────────────────┘     └──────────────┘
       │                     │
       │                     │
       ▼                     ▼
┌─────────────┐     ┌─────────────────┐
│  SkyWay SDK │     │ WebSocket Server│
│   (WebRTC)  │     │   (Socket.io)   │
└─────────────┘     └─────────────────┘
```

### 2.2 クライアント側アーキテクチャ

#### 2.2.1 レイヤー構成
- **Presentation Layer**: UIKit/SwiftUI
- **Business Logic Layer**: ViewModels, Services
- **Data Layer**: Repositories, Network Clients
- **Infrastructure Layer**: WebRTC, Push Notifications

#### 2.2.2 主要コンポーネント
```
KOEMOApp/
├── Presentation/
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── CallView.swift
│   │   ├── ChatView.swift
│   │   └── ProfileView.swift
│   └── ViewModels/
│       ├── HomeViewModel.swift
│       ├── CallViewModel.swift
│       └── ChatViewModel.swift
├── Domain/
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Call.swift
│   │   └── Message.swift
│   └── UseCases/
│       ├── MatchingUseCase.swift
│       └── CallUseCase.swift
├── Data/
│   ├── Repositories/
│   └── Network/
│       ├── APIClient.swift
│       └── WebSocketClient.swift
└── Infrastructure/
    ├── WebRTC/
    │   └── WebRTCManager.swift
    └── Push/
        └── PushNotificationManager.swift
```

### 2.3 サーバー側アーキテクチャ

#### 2.3.1 マイクロサービス構成
- **API Service**: RESTful API エンドポイント
- **Matching Service**: ユーザーマッチングロジック
- **Signaling Service**: WebRTCシグナリング
- **Notification Service**: プッシュ通知送信

## 3. 機能仕様

### 3.1 ユーザー管理

#### 3.1.1 匿名ユーザー登録
- デバイスIDベースの自動登録
- ニックネーム、性別、年齢の最小限情報
- メールアドレス不要

#### 3.1.2 プロフィール管理
```swift
struct UserProfile {
    let id: String          // UUID
    let deviceId: String    // 端末識別子
    let nickname: String    // ニックネーム
    let gender: Gender      // 性別
    let age: Int?          // 年齢（オプション）
    let region: String?    // 地域（オプション）
    let createdAt: Date
}
```

### 3.2 マッチングシステム

#### 3.2.1 マッチングアルゴリズム
```javascript
// 基本的なランダムマッチング
function findMatch(userId) {
    // 待機中ユーザープールから取得
    const waitingUsers = await getWaitingUsers();
    
    // 自分以外のユーザーからランダム選択
    const availableUsers = waitingUsers.filter(u => u.id !== userId);
    
    if (availableUsers.length > 0) {
        // ランダム選択（将来的には相性スコアで重み付け）
        const matchedUser = selectRandom(availableUsers);
        return matchedUser;
    }
    
    // 待機プールに追加
    await addToWaitingPool(userId);
    return null;
}
```

#### 3.2.2 マッチング状態管理
- `waiting`: 待機中
- `matched`: マッチング成立
- `confirmed`: 双方承認済み
- `calling`: 通話中
- `ended`: 通話終了

### 3.3 音声通話機能

#### 3.3.1 WebRTC実装
```swift
class WebRTCManager {
    private let skyway: SKWPeer
    
    func startCall(with peerId: String) {
        // SkyWay SDKを使用したP2P接続
        let options = SKWCallOption()
        let mediaConnection = skyway.call(withId: peerId, stream: localStream, options: options)
        
        mediaConnection.on(.STREAM) { stream in
            // リモートストリームの処理
            self.playRemoteAudio(stream)
        }
    }
}
```

#### 3.3.2 通話品質管理
- 自動ビットレート調整
- エコーキャンセレーション
- ノイズサプレッション

### 3.4 段階的プロフィール開示

#### 3.4.1 開示タイミング
```swift
enum ProfileDisclosureLevel: Int {
    case anonymous = 0      // 0秒: ニックネームのみ
    case basic = 30        // 30秒: 年齢追加
    case intermediate = 60 // 60秒: 地域追加
    case full = 180       // 180秒: 全情報
}
```

#### 3.4.2 UI更新処理
```swift
func updateProfileDisclosure(callDuration: TimeInterval) {
    switch callDuration {
    case 0..<30:
        showOnly(nickname: true)
    case 30..<60:
        show(nickname: true, age: true)
    case 60..<180:
        show(nickname: true, age: true, region: true)
    default:
        showFullProfile()
    }
}
```

### 3.5 エフェメラルチャット

#### 3.5.1 メッセージ自動削除
- 24時間後に自動削除
- TTLインデックスによるMongoDB自動削除

#### 3.5.2 メッセージ構造
```javascript
const messageSchema = {
    _id: ObjectId,
    callId: String,
    senderId: String,
    receiverId: String,
    content: String,
    createdAt: Date,
    expiresAt: Date // createdAt + 24 hours
};
```

## 4. データベース設計

### 4.1 コレクション構造

#### Users Collection
```json
{
    "_id": "uuid",
    "deviceId": "device-unique-id",
    "nickname": "ユーザー名",
    "gender": "male|female|other",
    "age": 25,
    "region": "Tokyo",
    "status": "online|offline|calling",
    "ticketBalance": 5,
    "createdAt": "2024-01-01T00:00:00Z",
    "lastActiveAt": "2024-01-01T00:00:00Z"
}
```

#### Calls Collection
```json
{
    "_id": "call-id",
    "caller": "user-id-1",
    "callee": "user-id-2",
    "status": "pending|accepted|rejected|ended",
    "startedAt": "2024-01-01T00:00:00Z",
    "endedAt": "2024-01-01T00:00:00Z",
    "duration": 180,
    "expiresAt": "2024-01-02T00:00:00Z"
}
```

## 5. セキュリティ要件

### 5.1 通信セキュリティ
- HTTPS/WSS必須
- WebRTC DTLS-SRTP暗号化
- APIトークン認証

### 5.2 プライバシー保護
- 個人情報最小限収集
- 24時間自動削除
- 通話録音禁止

### 5.3 不正利用対策
- 通報機能実装
- 自動スクリーンショット送信
- 24時間モニタリング

## 6. パフォーマンス要件

### 6.1 レスポンスタイム
- マッチング: < 3秒
- 通話接続: < 5秒
- API応答: < 200ms

### 6.2 同時接続数
- 目標: 10,000同時通話
- ピーク時: 50,000アクティブユーザー

## 7. 開発ツール

### 7.1 iOS開発
- Xcode 15.0+
- Swift 5.9+
- CocoaPods/Swift Package Manager

### 7.2 バックエンド開発
- Node.js 18+
- Docker/Docker Compose
- Jest (テスト)

### 7.3 監視・分析
- Firebase Analytics
- Crashlytics
- CloudWatch/Datadog