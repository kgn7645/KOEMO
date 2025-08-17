# KOEMO API仕様書

## 1. 概要

### 1.1 ベースURL
```
Production: https://api.koemo.app/v1
Development: http://localhost:3000/v1
```

### 1.2 認証方式
- Bearer Token認証
- デバイスIDベースの自動トークン発行

### 1.3 共通ヘッダー
```http
Authorization: Bearer {access_token}
Content-Type: application/json
X-Device-ID: {device_uuid}
X-App-Version: {app_version}
```

### 1.4 共通レスポンス形式
```json
{
    "success": true,
    "data": {},
    "error": null,
    "timestamp": "2024-01-01T00:00:00Z"
}
```

### 1.5 エラーレスポンス
```json
{
    "success": false,
    "data": null,
    "error": {
        "code": "ERROR_CODE",
        "message": "エラーメッセージ",
        "details": {}
    },
    "timestamp": "2024-01-01T00:00:00Z"
}
```

## 2. エンドポイント一覧

### 2.1 認証・ユーザー管理

#### POST /auth/register
匿名ユーザー登録

**Request:**
```json
{
    "deviceId": "device-uuid",
    "nickname": "ユーザー名",
    "gender": "male",
    "age": 25,
    "region": "Tokyo"
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "userId": "user-uuid",
        "accessToken": "jwt-token",
        "refreshToken": "refresh-token",
        "profile": {
            "nickname": "ユーザー名",
            "gender": "male",
            "age": 25,
            "region": "Tokyo"
        }
    }
}
```

#### POST /auth/refresh
トークンリフレッシュ

**Request:**
```json
{
    "refreshToken": "refresh-token"
}
```

#### GET /users/profile
自分のプロフィール取得

**Response:**
```json
{
    "success": true,
    "data": {
        "userId": "user-uuid",
        "nickname": "ユーザー名",
        "gender": "male",
        "age": 25,
        "region": "Tokyo",
        "ticketBalance": 5,
        "createdAt": "2024-01-01T00:00:00Z"
    }
}
```

#### PUT /users/profile
プロフィール更新

**Request:**
```json
{
    "nickname": "新しい名前",
    "age": 26,
    "region": "Osaka"
}
```

### 2.2 マッチング・通話

#### POST /calls/request
通話リクエスト（マッチング開始）

**Request:**
```json
{
    "useTicket": false
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "status": "waiting",
        "requestId": "request-uuid",
        "estimatedWaitTime": 5
    }
}
```

#### WebSocket /ws/matching
マッチングWebSocket接続

**Events:**

1. **match_found** - マッチング成立
```json
{
    "event": "match_found",
    "data": {
        "matchId": "match-uuid",
        "partnerId": "partner-uuid",
        "partnerProfile": {
            "nickname": "相手の名前"
        },
        "timeoutAt": "2024-01-01T00:00:30Z"
    }
}
```

2. **match_confirmed** - 双方承認
```json
{
    "event": "match_confirmed",
    "data": {
        "callId": "call-uuid",
        "signalData": {
            "peerId": "skyway-peer-id",
            "token": "skyway-token"
        }
    }
}
```

3. **match_cancelled** - マッチングキャンセル
```json
{
    "event": "match_cancelled",
    "data": {
        "reason": "partner_rejected"
    }
}
```

#### POST /calls/{callId}/accept
通話承認

**Response:**
```json
{
    "success": true,
    "data": {
        "callId": "call-uuid",
        "status": "connecting"
    }
}
```

#### POST /calls/{callId}/reject
通話拒否

#### POST /calls/{callId}/end
通話終了

**Request:**
```json
{
    "duration": 180
}
```

#### GET /calls/history
通話履歴取得（24時間以内）

**Response:**
```json
{
    "success": true,
    "data": {
        "calls": [
            {
                "callId": "call-uuid",
                "partnerId": "partner-uuid",
                "partnerProfile": {
                    "nickname": "相手の名前",
                    "age": 25,
                    "region": "Tokyo"
                },
                "startedAt": "2024-01-01T00:00:00Z",
                "duration": 180,
                "canMessage": true
            }
        ]
    }
}
```

### 2.3 メッセージング

#### POST /messages/send
メッセージ送信

**Request:**
```json
{
    "callId": "call-uuid",
    "recipientId": "recipient-uuid",
    "content": "メッセージ内容"
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "messageId": "message-uuid",
        "sentAt": "2024-01-01T00:00:00Z",
        "expiresAt": "2024-01-02T00:00:00Z"
    }
}
```

#### GET /messages/{callId}
メッセージ履歴取得

**Query Parameters:**
- `limit`: 取得件数（デフォルト: 50）
- `before`: このID以前のメッセージを取得

**Response:**
```json
{
    "success": true,
    "data": {
        "messages": [
            {
                "messageId": "message-uuid",
                "senderId": "sender-uuid",
                "content": "メッセージ内容",
                "sentAt": "2024-01-01T00:00:00Z"
            }
        ],
        "hasMore": false
    }
}
```

#### WebSocket /ws/messages
メッセージWebSocket接続

**Events:**

1. **message_received** - メッセージ受信
```json
{
    "event": "message_received",
    "data": {
        "messageId": "message-uuid",
        "callId": "call-uuid",
        "senderId": "sender-uuid",
        "content": "メッセージ内容",
        "sentAt": "2024-01-01T00:00:00Z"
    }
}
```

### 2.4 チケット・課金

#### GET /tickets/balance
チケット残高取得

**Response:**
```json
{
    "success": true,
    "data": {
        "balance": 5,
        "history": [
            {
                "type": "purchase",
                "amount": 5,
                "createdAt": "2024-01-01T00:00:00Z"
            }
        ]
    }
}
```

#### POST /tickets/purchase
チケット購入

**Request:**
```json
{
    "productId": "ticket_5pack",
    "receipt": "apple-receipt-data"
}
```

### 2.5 広告

#### POST /ads/complete
広告視聴完了

**Request:**
```json
{
    "adId": "ad-uuid",
    "watchedDuration": 30
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "reward": "call_ticket",
        "validUntil": "2024-01-01T01:00:00Z"
    }
}
```

### 2.6 通報・安全

#### POST /reports/create
ユーザー通報

**Request:**
```json
{
    "reportedUserId": "user-uuid",
    "callId": "call-uuid",
    "reason": "inappropriate_behavior",
    "description": "詳細説明",
    "screenshot": "base64-encoded-image"
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "reportId": "report-uuid",
        "status": "pending_review"
    }
}
```

#### POST /users/block
ユーザーブロック

**Request:**
```json
{
    "blockedUserId": "user-uuid"
}
```

## 3. WebRTCシグナリング

### 3.1 SkyWay Integration

#### POST /webrtc/token
SkyWay認証トークン取得

**Response:**
```json
{
    "success": true,
    "data": {
        "peerId": "koemo-user-uuid",
        "token": "skyway-auth-token",
        "ttl": 3600
    }
}
```

### 3.2 シグナリングフロー

```sequence
Client A -> Server: POST /calls/request
Server -> Client A: WebSocket: match_found
Client A -> Server: POST /calls/accept
Server -> Client B: WebSocket: match_confirmed
Client A -> SkyWay: Connect(peerId, token)
Client B -> SkyWay: Connect(peerId, token)
Client A <-> Client B: P2P Audio Stream
```

## 4. エラーコード

| コード | 説明 | HTTPステータス |
|--------|------|----------------|
| AUTH_INVALID_TOKEN | 無効なトークン | 401 |
| AUTH_EXPIRED_TOKEN | 期限切れトークン | 401 |
| USER_NOT_FOUND | ユーザーが見つかりません | 404 |
| MATCH_TIMEOUT | マッチングタイムアウト | 408 |
| CALL_ALREADY_ENDED | 通話は既に終了しています | 409 |
| INSUFFICIENT_TICKETS | チケット不足 | 402 |
| RATE_LIMIT_EXCEEDED | レート制限超過 | 429 |
| SERVER_ERROR | サーバーエラー | 500 |

## 5. レート制限

- 認証API: 10回/分
- 通話リクエスト: 5回/分
- メッセージ送信: 30回/分
- その他のAPI: 60回/分

## 6. セキュリティ

### 6.1 HTTPS/WSS必須
全ての通信はTLS暗号化必須

### 6.2 トークン有効期限
- アクセストークン: 1時間
- リフレッシュトークン: 30日

### 6.3 CORS設定
```javascript
{
    "origin": ["https://koemo.app"],
    "credentials": true
}
```