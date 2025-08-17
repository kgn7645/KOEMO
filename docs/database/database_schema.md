# KOEMO データベース設計書

## 1. 概要

### 1.1 データベース選定
- **MongoDB** - NoSQLデータベース
- 柔軟なスキーマでアジャイル開発に適合
- リアルタイムデータの高速処理
- TTLインデックスによる自動削除機能

### 1.2 データベース構成
```
koemo_production/
├── users              # ユーザー情報
├── calls              # 通話履歴
├── messages           # メッセージ
├── matches            # マッチング履歴
├── tickets            # チケット取引
├── reports            # 通報情報
├── blocked_users      # ブロックリスト
└── system_logs        # システムログ
```

## 2. コレクション詳細

### 2.1 users コレクション

**目的**: ユーザー基本情報の管理

```javascript
{
  "_id": ObjectId("..."),
  "userId": "uuid-v4",              // ユニークID
  "deviceId": "device-unique-id",   // デバイス識別子
  "profile": {
    "nickname": "ユーザー名",        // 1-20文字
    "gender": "male",               // male|female|other
    "age": 25,                      // 18以上
    "region": "Tokyo"               // 都道府県
  },
  "status": {
    "current": "online",            // online|offline|calling|matching
    "lastActiveAt": ISODate()
  },
  "tickets": {
    "balance": 5,                   // 現在のチケット数
    "freeCallsToday": 3,           // 本日の無料通話回数
    "lastFreeCallAt": ISODate()
  },
  "stats": {
    "totalCalls": 150,
    "totalCallDuration": 18000,     // 秒
    "averageCallDuration": 120,
    "longestCall": 600
  },
  "settings": {
    "notifications": true,
    "soundEnabled": true
  },
  "flags": {
    "isBlocked": false,
    "blockReason": null,
    "reportCount": 0
  },
  "createdAt": ISODate(),
  "updatedAt": ISODate()
}
```

**インデックス**:
```javascript
db.users.createIndex({ "userId": 1 }, { unique: true })
db.users.createIndex({ "deviceId": 1 }, { unique: true })
db.users.createIndex({ "status.current": 1 })
db.users.createIndex({ "flags.isBlocked": 1 })
```

### 2.2 calls コレクション

**目的**: 通話履歴の記録（24時間で自動削除）

```javascript
{
  "_id": ObjectId("..."),
  "callId": "uuid-v4",
  "participants": {
    "caller": {
      "userId": "user-id-1",
      "nickname": "太郎",
      "profileRevealLevel": 3      // 開示レベル
    },
    "callee": {
      "userId": "user-id-2", 
      "nickname": "花子",
      "profileRevealLevel": 2
    }
  },
  "timeline": {
    "matchedAt": ISODate(),        // マッチング時刻
    "startedAt": ISODate(),        // 通話開始
    "endedAt": ISODate(),          // 通話終了
    "duration": 180                // 通話時間（秒）
  },
  "status": "ended",               // pending|connecting|active|ended
  "endReason": "user_hangup",      // user_hangup|network_error|timeout
  "quality": {
    "connectionType": "webrtc",
    "avgLatency": 45,              // ms
    "packetLoss": 0.1              // %
  },
  "flags": {
    "wasReported": false,
    "hadTechnicalIssue": false
  },
  "expiresAt": ISODate()           // createdAt + 24時間
}
```

**インデックス**:
```javascript
db.calls.createIndex({ "callId": 1 }, { unique: true })
db.calls.createIndex({ "participants.caller.userId": 1 })
db.calls.createIndex({ "participants.callee.userId": 1 })
db.calls.createIndex({ "expiresAt": 1 }, { expireAfterSeconds: 0 }) // TTL
```

### 2.3 messages コレクション

**目的**: チャットメッセージ（24時間で自動削除）

```javascript
{
  "_id": ObjectId("..."),
  "messageId": "uuid-v4",
  "callId": "call-uuid",           // 関連する通話
  "sender": {
    "userId": "user-id-1",
    "nickname": "太郎"
  },
  "receiver": {
    "userId": "user-id-2",
    "nickname": "花子"
  },
  "content": {
    "text": "楽しかったです！",
    "type": "text"                 // text|emoji|system
  },
  "status": {
    "sent": true,
    "delivered": true,
    "deliveredAt": ISODate()
  },
  "createdAt": ISODate(),
  "expiresAt": ISODate()           // createdAt + 24時間
}
```

**インデックス**:
```javascript
db.messages.createIndex({ "callId": 1, "createdAt": -1 })
db.messages.createIndex({ "sender.userId": 1 })
db.messages.createIndex({ "receiver.userId": 1 })
db.messages.createIndex({ "expiresAt": 1 }, { expireAfterSeconds: 0 }) // TTL
```

### 2.4 matches コレクション

**目的**: マッチング処理の記録

```javascript
{
  "_id": ObjectId("..."),
  "matchId": "uuid-v4",
  "users": [
    {
      "userId": "user-id-1",
      "joinedAt": ISODate(),
      "response": "accepted"       // waiting|accepted|rejected
    },
    {
      "userId": "user-id-2",
      "joinedAt": ISODate(),
      "response": "accepted"
    }
  ],
  "status": "completed",           // pending|completed|cancelled
  "matchingTime": 3.2,            // マッチングにかかった時間（秒）
  "algorithm": {
    "version": "1.0",
    "factors": {
      "random": 0.7,
      "compatibility": 0.3
    }
  },
  "createdAt": ISODate()
}
```

**インデックス**:
```javascript
db.matches.createIndex({ "matchId": 1 }, { unique: true })
db.matches.createIndex({ "users.userId": 1 })
db.matches.createIndex({ "status": 1, "createdAt": -1 })
```

### 2.5 tickets コレクション

**目的**: チケット購入・使用履歴

```javascript
{
  "_id": ObjectId("..."),
  "transactionId": "uuid-v4",
  "userId": "user-id",
  "type": "purchase",              // purchase|use|reward
  "amount": 5,                     // 枚数
  "payment": {
    "method": "apple_iap",         // apple_iap|reward_ad
    "productId": "ticket_5pack",
    "receipt": "...",              // App Store レシート
    "price": 480,                  // 円
    "currency": "JPY"
  },
  "balance": {
    "before": 2,
    "after": 7
  },
  "createdAt": ISODate()
}
```

**インデックス**:
```javascript
db.tickets.createIndex({ "userId": 1, "createdAt": -1 })
db.tickets.createIndex({ "transactionId": 1 }, { unique: true })
```

### 2.6 reports コレクション

**目的**: 通報情報の管理

```javascript
{
  "_id": ObjectId("..."),
  "reportId": "uuid-v4",
  "reporter": {
    "userId": "user-id-1",
    "deviceId": "device-id"
  },
  "reported": {
    "userId": "user-id-2",
    "nickname": "問題ユーザー"
  },
  "callId": "call-uuid",
  "reason": "inappropriate_behavior",  // inappropriate_behavior|harassment|spam|other
  "description": "不適切な発言がありました",
  "evidence": {
    "screenshot": "base64-image",       // スクリーンショット
    "timestamp": ISODate()             // 発生時刻
  },
  "status": "pending",                 // pending|reviewing|resolved|dismissed
  "resolution": {
    "action": null,                    // warning|temporary_ban|permanent_ban
    "moderator": null,
    "resolvedAt": null,
    "notes": null
  },
  "createdAt": ISODate()
}
```

**インデックス**:
```javascript
db.reports.createIndex({ "reported.userId": 1 })
db.reports.createIndex({ "status": 1, "createdAt": -1 })
db.reports.createIndex({ "reportId": 1 }, { unique: true })
```

### 2.7 blocked_users コレクション

**目的**: ユーザー間のブロック関係

```javascript
{
  "_id": ObjectId("..."),
  "blockerId": "user-id-1",       // ブロックした人
  "blockedId": "user-id-2",       // ブロックされた人
  "reason": "user_initiated",      // user_initiated|system_ban
  "createdAt": ISODate()
}
```

**インデックス**:
```javascript
db.blocked_users.createIndex({ "blockerId": 1, "blockedId": 1 }, { unique: true })
db.blocked_users.createIndex({ "blockedId": 1 })
```

### 2.8 system_logs コレクション

**目的**: システムイベントのログ

```javascript
{
  "_id": ObjectId("..."),
  "eventType": "user_registration",    // various event types
  "userId": "user-id",
  "metadata": {
    // イベント固有のデータ
  },
  "ip": "192.168.1.1",
  "userAgent": "KOEMO/1.0 iOS/17.0",
  "timestamp": ISODate()
}
```

**インデックス**:
```javascript
db.system_logs.createIndex({ "userId": 1, "timestamp": -1 })
db.system_logs.createIndex({ "eventType": 1, "timestamp": -1 })
db.system_logs.createIndex({ "timestamp": 1 }, { expireAfterSeconds: 2592000 }) // 30日後削除
```

## 3. データ管理ポリシー

### 3.1 自動削除（TTL）
- **calls**: 24時間後に自動削除
- **messages**: 24時間後に自動削除
- **system_logs**: 30日後に自動削除

### 3.2 バックアップ
- 日次バックアップ（ユーザー、チケット、通報）
- 通話・メッセージはバックアップ対象外

### 3.3 レプリケーション
```javascript
// レプリカセット構成
{
  "_id": "koemo-replica-set",
  "members": [
    { "_id": 0, "host": "mongo-primary:27017", "priority": 2 },
    { "_id": 1, "host": "mongo-secondary-1:27017", "priority": 1 },
    { "_id": 2, "host": "mongo-secondary-2:27017", "priority": 1 }
  ]
}
```

### 3.4 シャーディング（将来的な拡張）
```javascript
// ユーザー数10万人超えた場合
sh.enableSharding("koemo_production")
sh.shardCollection("koemo_production.users", { "userId": "hashed" })
sh.shardCollection("koemo_production.calls", { "callId": "hashed" })
```

## 4. パフォーマンス最適化

### 4.1 インデックス戦略
- 頻繁なクエリパターンに基づくインデックス設計
- 複合インデックスの活用
- インデックスサイズの監視

### 4.2 クエリ最適化
```javascript
// 効率的なマッチングクエリ
db.users.aggregate([
  { $match: { "status.current": "matching", "flags.isBlocked": false } },
  { $sample: { size: 1 } }  // ランダム選択
])
```

### 4.3 接続プーリング
```javascript
// Node.js接続設定
{
  maxPoolSize: 100,
  minPoolSize: 10,
  maxIdleTimeMS: 10000
}
```

## 5. セキュリティ設定

### 5.1 認証・認可
```javascript
// ユーザー作成
db.createUser({
  user: "koemo_app",
  pwd: "secure_password",
  roles: [
    { role: "readWrite", db: "koemo_production" }
  ]
})
```

### 5.2 ネットワークセキュリティ
- MongoDB接続はVPC内部のみ
- TLS/SSL暗号化必須
- IPホワイトリスト設定

### 5.3 監査ログ
```javascript
// 監査設定
{
  auditLog: {
    destination: "file",
    format: "JSON",
    path: "/var/log/mongodb/audit.json"
  }
}
```