# KOEMO トラブルシューティングガイド

## 1. 概要

### 1.1 目的
本文書は、KOEMOアプリケーションで発生する可能性のある問題の診断方法と解決手順を提供します。

### 1.2 対象者
- 開発チーム
- 運用チーム
- カスタマーサポート
- テクニカルサポート

### 1.3 緊急度分類
- **P1 (Critical)**: サービス全体停止、重大なセキュリティ問題
- **P2 (High)**: 主要機能の障害、パフォーマンス著しい低下
- **P3 (Medium)**: 一部機能の障害、軽微なパフォーマンス問題
- **P4 (Low)**: UI/UXの問題、軽微なバグ

## 2. 一般的な診断手順

### 2.1 問題の特定
```bash
# 1. サービス状態確認
curl -I https://api.koemo.app/health

# 2. ログ確認
aws logs tail /ecs/koemo-backend --follow

# 3. メトリクス確認
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --start-time $(date -d "1 hour ago" -u +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average
```

### 2.2 情報収集チェックリスト
- [ ] 問題発生時刻
- [ ] 影響範囲（全体/一部のユーザー）
- [ ] エラーメッセージ
- [ ] 再現手順
- [ ] 環境情報（iOS版、ユーザー数など）

## 3. iOS アプリの問題

### 3.1 アプリが起動しない

#### 3.1.1 症状
- アプリがクラッシュする
- 起動画面で止まる
- デバイスで起動しない

#### 3.1.2 原因と対処法

**原因1: メモリ不足**
```bash
# Xcode Memory Debugger で確認
# Product > Profile > Leaks を実行

# 対処法
- 画像リソースの最適化
- 使用していないオブジェクトの解放
- メモリリークの修正
```

**原因2: 証明書問題**
```bash
# 証明書状態確認
security find-identity -v -p codesigning

# 対処法
1. Xcode > Preferences > Accounts で Apple ID 確認
2. Provisioning Profile の更新
3. Code Signing 設定の確認
```

**原因3: 依存関係の問題**
```bash
# CocoaPods 再インストール
pod deintegrate
pod cache clean --all
pod install

# 対処法
1. Podfile.lock の削除
2. Pods/ フォルダの削除
3. pod install の再実行
```

### 3.2 通話接続ができない

#### 3.2.1 症状
- マッチングはするが通話が始まらない
- 音声が聞こえない
- 通話が切断される

#### 3.2.2 診断手順
```swift
// WebRTC 接続状態確認
func diagnoseWebRTCConnection() {
    guard let peerConnection = self.peerConnection else {
        print("❌ PeerConnection is nil")
        return
    }
    
    print("📊 PeerConnection State: \(peerConnection.connectionState)")
    print("📊 ICE Connection State: \(peerConnection.iceConnectionState)")
    print("📊 ICE Gathering State: \(peerConnection.iceGatheringState)")
    
    // Statistics 取得
    peerConnection.statistics { report in
        for stat in report.statistics {
            print("📈 Stats: \(stat.type) - \(stat.values)")
        }
    }
}
```

#### 3.2.3 解決手順

**手順1: マイク権限確認**
```swift
import AVFoundation

func checkMicrophonePermission() {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted:
        print("✅ Microphone permission granted")
    case .denied:
        print("❌ Microphone permission denied")
        // 設定画面への誘導
        DispatchQueue.main.async {
            self.showPermissionAlert()
        }
    case .undetermined:
        print("❓ Microphone permission undetermined")
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            // パーミッション要求
        }
    @unknown default:
        break
    }
}
```

**手順2: ネットワーク接続確認**
```swift
import Network

class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                print("✅ Network connection available")
                print("📡 Interface: \(path.availableInterfaces)")
            } else {
                print("❌ Network connection unavailable")
            }
        }
        monitor.start(queue: queue)
    }
}
```

**手順3: SkyWay トークン確認**
```swift
func validateSkyWayToken() {
    guard let token = skyWayToken else {
        print("❌ SkyWay token is nil")
        return
    }
    
    // JWT デコード
    let parts = token.components(separatedBy: ".")
    guard parts.count == 3,
          let payloadData = Data(base64Encoded: parts[1]) else {
        print("❌ Invalid JWT token format")
        return
    }
    
    do {
        let payload = try JSONSerialization.jsonObject(with: payloadData)
        print("✅ SkyWay token payload: \(payload)")
    } catch {
        print("❌ Failed to decode JWT: \(error)")
    }
}
```

### 3.3 プロフィール開示が正常に動作しない

#### 3.3.1 症状
- 時間経過してもプロフィールが表示されない
- 間違ったタイミングで情報が表示される

#### 3.3.2 対処法
```swift
class ProfileDisclosureManager {
    private var callStartTime: Date?
    private var disclosureTimer: Timer?
    
    func startCall() {
        callStartTime = Date()
        scheduleProfileDisclosure()
    }
    
    private func scheduleProfileDisclosure() {
        disclosureTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateProfileDisclosure()
        }
    }
    
    private func updateProfileDisclosure() {
        guard let startTime = callStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let level = ProfileDisclosureLevel(duration: duration)
        
        print("🕐 Call duration: \(duration)s, Disclosure level: \(level)")
        updateUI(with: level)
    }
}
```

### 3.4 メモリリーク

#### 3.4.1 検出方法
```bash
# Xcode Instruments で検出
1. Product > Profile
2. Leaks テンプレートを選択
3. アプリを操作して通話を複数回実行
4. リークが発生した箇所を特定
```

#### 3.4.2 よくあるリーク箇所
```swift
// ❌ 悪い例: delegate の循環参照
class CallViewController {
    var webRTCManager: WebRTCManager?
    
    override func viewDidLoad() {
        webRTCManager = WebRTCManager()
        webRTCManager?.delegate = self // 強参照
    }
}

// ✅ 良い例: weak delegate
protocol WebRTCManagerDelegate: AnyObject {
    func didReceiveRemoteStream(_ stream: RTCMediaStream)
}

class WebRTCManager {
    weak var delegate: WebRTCManagerDelegate?
}
```

## 4. バックエンド API の問題

### 4.1 API レスポンスタイムアウト

#### 4.1.1 症状
- API 呼び出しが応答しない
- 504 Gateway Timeout エラー
- 接続タイムアウト

#### 4.1.2 診断コマンド
```bash
# API エンドポイントの応答時間測定
curl -w "@curl-format.txt" -o /dev/null -s https://api.koemo.app/health

# curl-format.txt の内容
time_namelookup:  %{time_namelookup}\n
time_connect:     %{time_connect}\n
time_appconnect:  %{time_appconnect}\n
time_pretransfer: %{time_pretransfer}\n
time_redirect:    %{time_redirect}\n
time_starttransfer: %{time_starttransfer}\n
time_total:       %{time_total}\n
```

#### 4.1.3 解決手順

**手順1: ECS タスクの状態確認**
```bash
# 実行中タスクの確認
aws ecs list-tasks --cluster koemo-production --service-name koemo-backend-service

# タスクの詳細確認
aws ecs describe-tasks --cluster koemo-production --tasks TASK_ARN
```

**手順2: アプリケーションログ確認**
```bash
# 最新のエラーログ確認
aws logs filter-log-events \
    --log-group-name /ecs/koemo-backend \
    --start-time $(date -d "1 hour ago" +%s)000 \
    --filter-pattern "ERROR"

# 特定の時間帯のログ確認
aws logs filter-log-events \
    --log-group-name /ecs/koemo-backend \
    --start-time 1640995200000 \
    --end-time 1640998800000
```

**手順3: データベース接続確認**
```bash
# MongoDB Atlas 接続テスト
mongosh "$MONGODB_URI" --eval "
    db.runCommand({ping: 1});
    db.stats();
    db.currentOp();
"
```

### 4.2 マッチングが機能しない

#### 4.2.1 症状
- マッチングリクエストに応答がない
- 同じユーザーとマッチングする
- マッチングタイムアウトが頻発

#### 4.2.2 診断手順
```javascript
// マッチングキューの状態確認
const matchingDiagnostics = {
    async checkWaitingPool() {
        const waitingUsers = await db.collection('matching_queue').find({
            status: 'waiting',
            createdAt: { $gte: new Date(Date.now() - 300000) } // 5分以内
        }).toArray();
        
        console.log(`Waiting users: ${waitingUsers.length}`);
        return waitingUsers;
    },
    
    async checkRecentMatches() {
        const recentMatches = await db.collection('matches').find({
            createdAt: { $gte: new Date(Date.now() - 3600000) } // 1時間以内
        }).toArray();
        
        console.log(`Recent matches: ${recentMatches.length}`);
        return recentMatches;
    },
    
    async checkBlockedUsers(userId) {
        const blocked = await db.collection('blocked_users').find({
            $or: [
                { blockerId: userId },
                { blockedId: userId }
            ]
        }).toArray();
        
        console.log(`Blocked relationships: ${blocked.length}`);
        return blocked;
    }
};
```

#### 4.2.3 解決手順

**手順1: Redis 接続確認**
```bash
# Redis 接続テスト
redis-cli -h redis-cluster.xxx.cache.amazonaws.com ping

# キュー状態確認
redis-cli -h redis-cluster.xxx.cache.amazonaws.com llen matching_queue
```

**手順2: マッチングサービス再起動**
```bash
# ECS サービスの強制デプロイ
aws ecs update-service \
    --cluster koemo-production \
    --service koemo-backend-service \
    --force-new-deployment
```

### 4.3 WebSocket 接続問題

#### 4.3.1 症状
- WebSocket 接続が確立されない
- 接続がすぐに切断される
- メッセージが送受信されない

#### 4.3.2 診断手順
```javascript
// WebSocket 接続診断
class WebSocketDiagnostics {
    constructor(url) {
        this.url = url;
        this.ws = null;
        this.connectionAttempts = 0;
        this.maxAttempts = 5;
    }
    
    async testConnection() {
        return new Promise((resolve, reject) => {
            this.ws = new WebSocket(this.url);
            
            const timeout = setTimeout(() => {
                this.ws.close();
                reject(new Error('Connection timeout'));
            }, 10000);
            
            this.ws.onopen = () => {
                clearTimeout(timeout);
                console.log('✅ WebSocket connected');
                resolve(true);
            };
            
            this.ws.onerror = (error) => {
                clearTimeout(timeout);
                console.log('❌ WebSocket error:', error);
                reject(error);
            };
            
            this.ws.onclose = (event) => {
                console.log(`🔌 WebSocket closed: ${event.code} ${event.reason}`);
            };
        });
    }
    
    testEcho() {
        if (this.ws?.readyState === WebSocket.OPEN) {
            const testMessage = { type: 'ping', timestamp: Date.now() };
            this.ws.send(JSON.stringify(testMessage));
            
            this.ws.onmessage = (event) => {
                const response = JSON.parse(event.data);
                console.log('📨 Echo response:', response);
            };
        }
    }
}
```

#### 4.3.3 解決手順

**手順1: ALB 設定確認**
```bash
# WebSocket サポート確認
aws elbv2 describe-load-balancers \
    --load-balancer-arns arn:aws:elasticloadbalancing:...

# ターゲットグループの health check
aws elbv2 describe-target-health \
    --target-group-arn arn:aws:elasticloadbalancing:...
```

**手順2: セキュリティグループ確認**
```bash
# インバウンドルール確認
aws ec2 describe-security-groups \
    --group-ids sg-xxx \
    --query 'SecurityGroups[0].IpPermissions'
```

### 4.4 データベース接続エラー

#### 4.4.1 症状
- MongoDB 接続タイムアウト
- Connection pool exhausted
- Authentication failed

#### 4.4.2 診断手順
```javascript
// MongoDB 接続診断
const mongoose = require('mongoose');

class DatabaseDiagnostics {
    static async checkConnection() {
        try {
            const conn = await mongoose.connect(process.env.MONGODB_URI, {
                serverSelectionTimeoutMS: 5000,
                socketTimeoutMS: 45000,
            });
            
            console.log('✅ MongoDB connected');
            
            // 基本操作テスト
            const result = await conn.connection.db.admin().ping();
            console.log('📊 Ping result:', result);
            
            // 接続プール状態
            const poolInfo = conn.connection.db.serverConfig.s.pool;
            console.log('🏊 Pool info:', {
                totalConnections: poolInfo.totalConnections,
                availableConnections: poolInfo.availableConnections,
                checkedOutConnections: poolInfo.checkedOutConnections
            });
            
            return true;
        } catch (error) {
            console.error('❌ MongoDB connection failed:', error);
            return false;
        }
    }
    
    static async checkCollections() {
        try {
            const collections = await mongoose.connection.db.listCollections().toArray();
            console.log('📚 Available collections:', collections.map(c => c.name));
            return collections;
        } catch (error) {
            console.error('❌ Failed to list collections:', error);
            return [];
        }
    }
}
```

#### 4.4.3 解決手順

**手順1: 接続文字列確認**
```bash
# 環境変数確認
aws secretsmanager get-secret-value \
    --secret-id koemo/mongodb \
    --query SecretString \
    --output text
```

**手順2: ネットワーク接続確認**
```bash
# MongoDB Atlas への到達性確認
nslookup cluster0.xxx.mongodb.net
telnet cluster0.xxx.mongodb.net 27017
```

## 5. パフォーマンス問題

### 5.1 高負荷時の対応

#### 5.1.1 症状
- API レスポンスが遅い
- CPU/メモリ使用率が高い
- タスクが頻繁に再起動される

#### 5.1.2 パフォーマンス監視
```bash
# CPU/メモリ使用率確認
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=koemo-backend-service \
    --start-time $(date -d "1 hour ago" -u +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average,Maximum

# リクエスト数確認
aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name RequestCount \
    --start-time $(date -d "1 hour ago" -u +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Sum
```

#### 5.1.3 対処手順

**手順1: スケールアウト**
```bash
# ECS サービスのタスク数増加
aws ecs update-service \
    --cluster koemo-production \
    --service koemo-backend-service \
    --desired-count 5
```

**手順2: データベース最適化**
```javascript
// 重いクエリの特定
db.setProfilingLevel(2, { slowms: 100 });

// プロファイル結果確認
db.system.profile.find().limit(5).sort({ ts: -1 }).pretty();

// インデックス使用状況確認
db.users.find({ "status.current": "online" }).explain("executionStats");
```

### 5.2 メモリリーク

#### 5.2.1 検出方法
```javascript
// Node.js メモリ使用量監視
function monitorMemory() {
    setInterval(() => {
        const used = process.memoryUsage();
        console.log('Memory usage:', {
            rss: Math.round(used.rss / 1024 / 1024) + ' MB',
            heapTotal: Math.round(used.heapTotal / 1024 / 1024) + ' MB',
            heapUsed: Math.round(used.heapUsed / 1024 / 1024) + ' MB',
            external: Math.round(used.external / 1024 / 1024) + ' MB'
        });
    }, 30000);
}
```

#### 5.2.2 対処法
```javascript
// WebSocket 接続のクリーンアップ
class ConnectionManager {
    constructor() {
        this.connections = new Map();
        this.cleanupInterval = setInterval(() => {
            this.cleanupStaleConnections();
        }, 60000);
    }
    
    cleanupStaleConnections() {
        const now = Date.now();
        for (const [id, conn] of this.connections) {
            if (now - conn.lastActivity > 300000) { // 5分
                console.log(`Cleaning up stale connection: ${id}`);
                conn.socket.disconnect(true);
                this.connections.delete(id);
            }
        }
    }
    
    destroy() {
        clearInterval(this.cleanupInterval);
        for (const [id, conn] of this.connections) {
            conn.socket.disconnect(true);
        }
        this.connections.clear();
    }
}
```

## 6. セキュリティ問題

### 6.1 不正アクセス検知

#### 6.1.1 症状
- 異常なトラフィック増加
- 不正なAPI呼び出し
- 認証エラーの大量発生

#### 6.1.2 検知手順
```bash
# 異常なIPアドレスの特定
aws logs insights start-query \
    --log-group-name /ecs/koemo-backend \
    --start-time $(date -d "1 hour ago" +%s) \
    --end-time $(date +%s) \
    --query-string '
        fields @timestamp, ip, userAgent, statusCode
        | filter statusCode >= 400
        | stats count() by ip
        | sort count desc
        | limit 20
    '
```

#### 6.1.3 対処手順

**手順1: WAF ルール追加**
```bash
# 不正IPをブロック
aws wafv2 update-ip-set \
    --scope CLOUDFRONT \
    --id xxx \
    --addresses "192.168.1.1/32,10.0.0.1/32"
```

**手順2: レート制限強化**
```javascript
// Express Rate Limit 設定
const rateLimit = require('express-rate-limit');

const strictLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15分
    max: 10, // 最大10リクエスト
    message: 'Too many requests',
    standardHeaders: true,
    legacyHeaders: false,
});

app.use('/api/calls/request', strictLimiter);
```

### 6.2 データ漏洩対応

#### 6.2.1 検知手順
```bash
# 異常なデータアクセスパターン確認
aws logs insights start-query \
    --log-group-name /ecs/koemo-backend \
    --query-string '
        fields @timestamp, userId, action, ip
        | filter action like /data_access/
        | stats count() by userId, ip
        | sort count desc
    '
```

#### 6.2.2 緊急対応手順
1. **即座にサービス停止**
2. **影響範囲の特定**
3. **証拠保全**
4. **関係機関への報告**
5. **ユーザーへの通知**

## 7. 復旧手順

### 7.1 サービス全体障害からの復旧

#### 7.1.1 緊急復旧手順
```bash
#!/bin/bash
# emergency-recovery.sh

echo "🚨 Starting emergency recovery procedure..."

# 1. 健全性チェック
echo "1. Health check..."
if curl -f https://api.koemo.app/health > /dev/null 2>&1; then
    echo "✅ Service is responding"
    exit 0
fi

# 2. ECS サービス確認
echo "2. Checking ECS service..."
RUNNING_COUNT=$(aws ecs describe-services \
    --cluster koemo-production \
    --services koemo-backend-service \
    --query 'services[0].runningCount' \
    --output text)

if [ "$RUNNING_COUNT" = "0" ]; then
    echo "❌ No running tasks. Starting service..."
    aws ecs update-service \
        --cluster koemo-production \
        --service koemo-backend-service \
        --desired-count 3
fi

# 3. データベース接続確認
echo "3. Checking database connection..."
if ! mongosh "$MONGODB_URI" --eval "db.runCommand({ping: 1})" > /dev/null 2>&1; then
    echo "❌ Database connection failed"
    # フェイルオーバー手順を実行
fi

# 4. CloudFront キャッシュクリア
echo "4. Clearing CloudFront cache..."
aws cloudfront create-invalidation \
    --distribution-id E123456789 \
    --paths "/*"

echo "🔄 Recovery procedure completed"
```

### 7.2 データベース復旧

#### 7.2.1 MongoDB Atlas から復旧
```bash
# Point-in-Time Recovery
# MongoDB Atlas Console で実行
# 1. Clusters > Backup > Restore
# 2. 復旧ポイントを選択
# 3. 新しいクラスターに復旧

# 接続文字列の更新
aws secretsmanager update-secret \
    --secret-id koemo/mongodb \
    --secret-string "mongodb+srv://user:pass@new-cluster.mongodb.net/koemo"
```

### 7.3 ロールバック手順

#### 7.3.1 アプリケーションロールバック
```bash
#!/bin/bash
# rollback.sh

PREVIOUS_TASK_DEFINITION=$1

if [ -z "$PREVIOUS_TASK_DEFINITION" ]; then
    echo "Usage: $0 <previous-task-definition-arn>"
    exit 1
fi

echo "🔄 Rolling back to: $PREVIOUS_TASK_DEFINITION"

# ECS サービス更新
aws ecs update-service \
    --cluster koemo-production \
    --service koemo-backend-service \
    --task-definition $PREVIOUS_TASK_DEFINITION

# 安定化待ち
aws ecs wait services-stable \
    --cluster koemo-production \
    --services koemo-backend-service

echo "✅ Rollback completed"
```

## 8. 予防措置

### 8.1 監視強化

#### 8.1.1 カスタムメトリクス
```javascript
// アプリケーション固有メトリクス
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

class MetricsCollector {
    static async recordCallDuration(duration) {
        await cloudwatch.putMetricData({
            Namespace: 'KOEMO/Application',
            MetricData: [{
                MetricName: 'CallDuration',
                Value: duration,
                Unit: 'Seconds',
                Timestamp: new Date()
            }]
        }).promise();
    }
    
    static async recordMatchingTime(time) {
        await cloudwatch.putMetricData({
            Namespace: 'KOEMO/Application',
            MetricData: [{
                MetricName: 'MatchingTime',
                Value: time,
                Unit: 'Seconds'
            }]
        }).promise();
    }
}
```

#### 8.1.2 アラート設定
```yaml
# CloudWatch Alarms
Alarms:
  HighErrorRate:
    MetricName: ErrorRate
    Threshold: 5
    ComparisonOperator: GreaterThanThreshold
    EvaluationPeriods: 2
    Actions:
      - SNS Topic: arn:aws:sns:region:account:koemo-alerts
      - Auto Scaling: Scale Out
  
  DatabaseConnectionFailed:
    MetricName: DatabaseConnections
    Threshold: 90
    ComparisonOperator: GreaterThanThreshold
    Actions:
      - Lambda Function: emergency-response
```

### 8.2 自動復旧

#### 8.2.1 Auto Scaling 設定
```yaml
Auto Scaling Policy:
  Target Tracking:
    - Metric: CPU Utilization
      Target: 70%
    - Metric: Memory Utilization
      Target: 80%
  
  Step Scaling:
    Scale Out:
      - CPU > 80%: +2 tasks
      - Error Rate > 5%: +1 task
    Scale In:
      - CPU < 30%: -1 task
```

#### 8.2.2 Circuit Breaker パターン
```javascript
class CircuitBreaker {
    constructor(options = {}) {
        this.failureThreshold = options.failureThreshold || 5;
        this.timeout = options.timeout || 60000;
        this.monitoringPeriod = options.monitoringPeriod || 10000;
        
        this.state = 'CLOSED';
        this.failureCount = 0;
        this.lastFailureTime = null;
    }
    
    async call(fn) {
        if (this.state === 'OPEN') {
            if (Date.now() - this.lastFailureTime >= this.timeout) {
                this.state = 'HALF_OPEN';
            } else {
                throw new Error('Circuit breaker is OPEN');
            }
        }
        
        try {
            const result = await fn();
            this.onSuccess();
            return result;
        } catch (error) {
            this.onFailure();
            throw error;
        }
    }
    
    onSuccess() {
        this.failureCount = 0;
        this.state = 'CLOSED';
    }
    
    onFailure() {
        this.failureCount++;
        this.lastFailureTime = Date.now();
        
        if (this.failureCount >= this.failureThreshold) {
            this.state = 'OPEN';
        }
    }
}
```

## 9. エスカレーション手順

### 9.1 緊急連絡先
```yaml
Contacts:
  P1 (Critical):
    - Technical Lead: +81-90-xxxx-xxxx
    - DevOps Engineer: +81-90-xxxx-xxxx
    - CTO: +81-90-xxxx-xxxx
  
  P2 (High):
    - Development Team: slack://koemo-dev
    - Operations Team: slack://koemo-ops
  
  External:
    - MongoDB Atlas Support: support.mongodb.com
    - AWS Support: console.aws.amazon.com/support
    - SkyWay Support: support.ntt.com
```

### 9.2 エスカレーションフロー
```
問題発生
    ↓
初動対応 (15分)
    ↓
問題解決？ → Yes → 解決
    ↓ No
チームリーダーへ報告 (30分)
    ↓
問題解決？ → Yes → 解決
    ↓ No
管理職・外部サポートへ報告 (60分)
    ↓
緊急対応体制の確立
```

## 10. 事後対応

### 10.1 ポストモーテム

#### 10.1.1 テンプレート
```markdown
# インシデント報告書

## 概要
- 発生日時:
- 影響時間:
- 影響範囲:
- 重要度:

## タイムライン
- HH:MM - 問題発生
- HH:MM - 検知・通知
- HH:MM - 初動対応開始
- HH:MM - 復旧完了

## 根本原因
- 技術的原因:
- プロセス的原因:

## 対処内容
- 即座の対処:
- 根本的な修正:

## 再発防止策
- 技術的改善:
- プロセス改善:
- 監視強化:

## 学んだ教訓
- 
```

### 10.2 改善実装

#### 10.2.1 改善チケット作成
```yaml
GitHub Issue Template:
  Title: "[POST-MORTEM] 改善項目: XXX"
  Labels: ["post-mortem", "improvement", "priority/high"]
  
  Content:
    - 背景と課題
    - 改善提案
    - 実装計画
    - 検証方法
    - 完了条件
```

---

本トラブルシューティングガイドを活用して、KOEMOアプリケーションの問題を迅速かつ効果的に解決し、サービスの安定性を維持してください。