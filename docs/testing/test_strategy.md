# KOEMO テスト戦略・テスト仕様書

## 1. 概要

### 1.1 目的
本文書は、KOEMOアプリケーションの品質保証を目的とした包括的なテスト戦略と実装方針を定義します。

### 1.2 スコープ
- iOSクライアントアプリケーション
- Node.jsバックエンドAPI
- WebRTC音声通話機能
- リアルタイム通信（WebSocket）
- データベース操作
- セキュリティ機能

### 1.3 テスト原則
- **エフェメラル特性の検証**: 24時間自動削除機能
- **リアルタイム通信の信頼性**: WebRTC/WebSocket通信
- **匿名性の保護**: プライバシー保護機能
- **スケーラビリティ**: 高負荷時の動作確認

## 2. テスト戦略

### 2.1 テストピラミッド

```
        E2E Tests (5%)
      ┌─────────────────┐
     │  統合テスト (15%) │
    └───────────────────┘
   │    単体テスト (80%)   │
  └─────────────────────┘
```

### 2.2 テストレベル定義

#### 2.2.1 単体テスト (Unit Tests)
- **目的**: 個別の関数・メソッドの動作検証
- **範囲**: 80% 以上のカバレッジ
- **実行頻度**: 各コミット時

#### 2.2.2 統合テスト (Integration Tests)  
- **目的**: モジュール間の連携検証
- **範囲**: API、データベース、外部サービス連携
- **実行頻度**: プルリクエスト時

#### 2.2.3 E2Eテスト (End-to-End Tests)
- **目的**: ユーザーシナリオ全体の動作検証
- **範囲**: 重要なユーザーフロー
- **実行頻度**: リリース前

## 3. iOS アプリテスト

### 3.1 単体テスト

#### 3.1.1 テストフレームワーク
```swift
import XCTest
import Quick
import Nimble
@testable import KOEMO
```

#### 3.1.2 ViewModelテスト例
```swift
class HomeViewModelTests: QuickSpec {
    override func spec() {
        describe("HomeViewModel") {
            var viewModel: HomeViewModel!
            
            beforeEach {
                viewModel = HomeViewModel()
            }
            
            context("通話開始") {
                it("チケットが十分な場合、マッチングを開始する") {
                    // Given
                    viewModel.ticketBalance = 5
                    
                    // When
                    viewModel.startCall(useTicket: true)
                    
                    // Then
                    expect(viewModel.state).to(equal(.matching))
                }
                
                it("チケット不足の場合、エラーを表示する") {
                    // Given
                    viewModel.ticketBalance = 0
                    
                    // When
                    viewModel.startCall(useTicket: true)
                    
                    // Then
                    expect(viewModel.error).toNot(beNil())
                }
            }
        }
    }
}
```

#### 3.1.3 WebRTCManagerテスト
```swift
class WebRTCManagerTests: XCTestCase {
    var webRTCManager: WebRTCManager!
    
    override func setUp() {
        super.setUp()
        webRTCManager = WebRTCManager()
    }
    
    func testPeerConnectionCreation() {
        // Given
        let expectation = XCTestExpectation(description: "Peer connection created")
        
        // When
        webRTCManager.createPeerConnection { success in
            // Then
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLocalStreamSetup() {
        // Given
        let expectation = XCTestExpectation(description: "Local stream setup")
        
        // When
        webRTCManager.setupLocalStream { stream in
            // Then
            XCTAssertNotNil(stream)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}
```

### 3.2 UIテスト

#### 3.2.1 基本UI操作テスト
```swift
class KOEMOUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testCallButtonTap() throws {
        // Given
        let callButton = app.buttons["通話開始"]
        
        // When
        callButton.tap()
        
        // Then
        XCTAssertTrue(app.staticTexts["マッチング中..."].waitForExistence(timeout: 5))
    }
    
    func testProfileDisclosure() throws {
        // Given - 通話中状態を模擬
        app.launchArguments.append("--uitesting-call-active")
        app.launch()
        
        // When - 30秒待機
        let ageLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '歳'")).firstMatch
        
        // Then
        XCTAssertTrue(ageLabel.waitForExistence(timeout: 30))
    }
}
```

### 3.3 パフォーマンステスト

#### 3.3.1 メモリリークテスト
```swift
class PerformanceTests: XCTestCase {
    func testCallViewControllerMemoryLeak() {
        measure {
            for _ in 0..<100 {
                let callVC = CallViewController()
                callVC.loadViewIfNeeded()
                // メモリ解放確認
            }
        }
    }
    
    func testWebRTCConnectionPerformance() {
        measure {
            let webRTC = WebRTCManager()
            webRTC.createPeerConnection { _ in }
        }
    }
}
```

## 4. バックエンド API テスト

### 4.1 単体テスト

#### 4.1.1 テストフレームワーク設定
```javascript
// jest.config.js
module.exports = {
  testEnvironment: 'node',
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/index.js'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};
```

#### 4.1.2 認証サービステスト
```javascript
const AuthService = require('../src/services/AuthService');
const jwt = require('jsonwebtoken');

describe('AuthService', () => {
  describe('generateToken', () => {
    it('有効なJWTトークンを生成する', () => {
      // Given
      const userId = 'test-user-id';
      
      // When
      const token = AuthService.generateToken(userId);
      
      // Then
      expect(token).toBeDefined();
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      expect(decoded.userId).toBe(userId);
    });
    
    it('有効期限が正しく設定される', () => {
      // Given
      const userId = 'test-user-id';
      
      // When
      const token = AuthService.generateToken(userId);
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Then
      expect(decoded.exp).toBeGreaterThan(Date.now() / 1000);
    });
  });
});
```

#### 4.1.3 マッチングサービステスト
```javascript
const MatchingService = require('../src/services/MatchingService');

describe('MatchingService', () => {
  let matchingService;
  
  beforeEach(() => {
    matchingService = new MatchingService();
  });
  
  describe('findMatch', () => {
    it('待機中ユーザーとマッチングする', async () => {
      // Given
      const user1 = 'user-1';
      const user2 = 'user-2';
      await matchingService.addToWaitingPool(user2);
      
      // When
      const match = await matchingService.findMatch(user1);
      
      // Then
      expect(match).toBeDefined();
      expect(match.users).toContain(user1);
      expect(match.users).toContain(user2);
    });
    
    it('自分以外のユーザーとマッチングする', async () => {
      // Given
      const user1 = 'user-1';
      await matchingService.addToWaitingPool(user1);
      
      // When
      const match = await matchingService.findMatch(user1);
      
      // Then
      expect(match).toBeNull();
    });
  });
});
```

### 4.2 統合テスト

#### 4.2.1 API統合テスト
```javascript
const request = require('supertest');
const app = require('../src/app');

describe('API Integration Tests', () => {
  let authToken;
  
  beforeAll(async () => {
    // テストユーザーでログイン
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        deviceId: 'test-device',
        nickname: 'テストユーザー',
        gender: 'male',
        age: 25
      });
    
    authToken = response.body.data.accessToken;
  });
  
  describe('通話リクエスト', () => {
    it('正常な通話リクエストを処理する', async () => {
      // When
      const response = await request(app)
        .post('/api/calls/request')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ useTicket: false });
      
      // Then
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe('waiting');
    });
    
    it('無効なトークンを拒否する', async () => {
      // When
      const response = await request(app)
        .post('/api/calls/request')
        .set('Authorization', 'Bearer invalid-token')
        .send({ useTicket: false });
      
      // Then
      expect(response.status).toBe(401);
    });
  });
});
```

#### 4.2.2 WebSocket統合テスト
```javascript
const Client = require('socket.io-client');
const server = require('../src/server');

describe('WebSocket Integration', () => {
  let clientSocket;
  let serverSocket;
  
  beforeAll((done) => {
    server.listen(() => {
      const port = server.address().port;
      clientSocket = new Client(`http://localhost:${port}`);
      
      server.on('connection', (socket) => {
        serverSocket = socket;
      });
      
      clientSocket.on('connect', done);
    });
  });
  
  afterAll(() => {
    server.close();
    clientSocket.close();
  });
  
  test('マッチング通知を受信する', (done) => {
    // Given
    clientSocket.on('match_found', (data) => {
      // Then
      expect(data.matchId).toBeDefined();
      expect(data.partnerId).toBeDefined();
      done();
    });
    
    // When
    serverSocket.emit('match_found', {
      matchId: 'test-match',
      partnerId: 'test-partner'
    });
  });
});
```

### 4.3 データベーステスト

#### 4.3.1 MongoDB テストセットアップ
```javascript
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongoServer;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const mongoUri = mongoServer.getUri();
  await mongoose.connect(mongoUri);
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

beforeEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});
```

#### 4.3.2 TTL機能テスト
```javascript
const Message = require('../src/models/Message');

describe('メッセージTTL機能', () => {
  it('24時間後にメッセージが自動削除される', async () => {
    // Given
    const message = new Message({
      callId: 'test-call',
      senderId: 'user-1',
      receiverId: 'user-2',
      content: { text: 'テストメッセージ' },
      expiresAt: new Date(Date.now() + 100) // 100ms後に削除
    });
    
    await message.save();
    
    // When - 削除まで待機
    await new Promise(resolve => setTimeout(resolve, 200));
    
    // Then
    const foundMessage = await Message.findById(message._id);
    expect(foundMessage).toBeNull();
  });
});
```

## 5. E2E テスト

### 5.1 重要ユーザーシナリオ

#### 5.1.1 通話フロー全体テスト
```javascript
// Detox E2E テスト (React Native風に記述)
describe('通話フロー', () => {
  beforeEach(async () => {
    await device.reloadReactNative();
  });
  
  it('ユーザーが通話を開始し、相手と会話できる', async () => {
    // Given - ホーム画面
    await expect(element(by.id('call-button'))).toBeVisible();
    
    // When - 通話開始
    await element(by.id('call-button')).tap();
    
    // Then - マッチング画面
    await expect(element(by.text('マッチング中...'))).toBeVisible();
    
    // When - マッチング成立（モック）
    await waitFor(element(by.text('マッチしました！')))
      .toBeVisible()
      .withTimeout(5000);
    
    // When - 通話承認
    await element(by.id('accept-call-button')).tap();
    
    // Then - 通話画面
    await expect(element(by.id('call-screen'))).toBeVisible();
    await expect(element(by.id('mute-button'))).toBeVisible();
    await expect(element(by.id('speaker-button'))).toBeVisible();
    
    // When - 通話終了
    await element(by.id('end-call-button')).tap();
    
    // Then - 履歴画面
    await expect(element(by.id('call-history'))).toBeVisible();
  });
});
```

#### 5.1.2 段階的プロフィール開示テスト
```javascript
describe('プロフィール段階開示', () => {
  it('通話時間に応じてプロフィールが表示される', async () => {
    // Given - 通話中状態をセットアップ
    await mockCallState('active');
    
    // Then - 初期状態（ニックネームのみ）
    await expect(element(by.id('partner-nickname'))).toBeVisible();
    await expect(element(by.id('partner-age'))).not.toBeVisible();
    
    // When - 30秒経過
    await mockCallDuration(30);
    
    // Then - 年齢表示
    await expect(element(by.id('partner-age'))).toBeVisible();
    await expect(element(by.id('partner-region'))).not.toBeVisible();
    
    // When - 60秒経過
    await mockCallDuration(60);
    
    // Then - 地域表示
    await expect(element(by.id('partner-region'))).toBeVisible();
  });
});
```

### 5.2 負荷テスト

#### 5.2.1 同時接続テスト
```javascript
const WebSocket = require('ws');

describe('負荷テスト', () => {
  it('100人同時接続に耐える', async () => {
    const connections = [];
    const promises = [];
    
    // 100個の同時接続を作成
    for (let i = 0; i < 100; i++) {
      const promise = new Promise((resolve, reject) => {
        const ws = new WebSocket('ws://localhost:3000');
        
        ws.on('open', () => {
          connections.push(ws);
          resolve();
        });
        
        ws.on('error', reject);
      });
      
      promises.push(promise);
    }
    
    // すべての接続が確立されることを確認
    await Promise.all(promises);
    expect(connections).toHaveLength(100);
    
    // 接続をクリーンアップ
    connections.forEach(ws => ws.close());
  });
});
```

## 6. テスト実行環境

### 6.1 CI/CD パイプライン

#### 6.1.1 GitHub Actions 設定
```yaml
name: Test Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    
    services:
      mongodb:
        image: mongo:7.0
        ports:
          - 27017:27017
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: backend/package-lock.json
    
    - name: Install dependencies
      run: |
        cd backend
        npm ci
    
    - name: Run unit tests
      run: |
        cd backend
        npm run test:unit
    
    - name: Run integration tests
      run: |
        cd backend
        npm run test:integration
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3

  ios-tests:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Install dependencies
      run: |
        cd ios
        pod install
    
    - name: Run unit tests
      run: |
        cd ios
        xcodebuild test \
          -workspace KOEMO.xcworkspace \
          -scheme KOEMO \
          -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 6.2 テストデータ管理

#### 6.2.1 テストデータセット
```javascript
// tests/fixtures/users.js
module.exports = {
  validUser: {
    deviceId: 'test-device-001',
    nickname: 'テストユーザー',
    gender: 'male',
    age: 25,
    region: 'Tokyo'
  },
  
  minorUser: {
    deviceId: 'test-device-002',
    nickname: '未成年',
    gender: 'female',
    age: 17,
    region: 'Osaka'
  },
  
  bannedUser: {
    deviceId: 'test-device-003',
    nickname: 'BANユーザー',
    gender: 'male',
    age: 30,
    flags: { isBlocked: true }
  }
};
```

#### 6.2.2 モックサービス
```javascript
// tests/mocks/SkyWayMock.js
class SkyWayMock {
  constructor() {
    this.connections = new Map();
  }
  
  connect(peerId) {
    return Promise.resolve({
      id: peerId,
      open: true
    });
  }
  
  call(targetId, stream) {
    return Promise.resolve({
      remoteStream: new MockMediaStream(),
      on: jest.fn()
    });
  }
}

module.exports = SkyWayMock;
```

## 7. テスト品質指標

### 7.1 コードカバレッジ目標
- **単体テスト**: 80% 以上
- **統合テスト**: 主要APIエンドポイント 100%
- **E2Eテスト**: 重要ユーザーフロー 100%

### 7.2 パフォーマンス指標
- **API レスポンス**: 平均 200ms 以下
- **マッチング時間**: 平均 3秒 以下
- **通話接続時間**: 平均 5秒 以下
- **メモリ使用量**: iOS アプリ 100MB 以下

### 7.3 品質ゲート
```yaml
quality_gates:
  code_coverage:
    minimum: 80%
  
  performance:
    api_response_time: 200ms
    matching_time: 3s
    call_connection_time: 5s
  
  security:
    vulnerability_scan: pass
    dependency_check: pass
  
  accessibility:
    voiceover_support: pass
    dynamic_type: pass
```

## 8. テスト報告

### 8.1 テスト結果レポート
```javascript
// 自動生成されるテストレポート例
{
  "summary": {
    "total": 1250,
    "passed": 1235,
    "failed": 10,
    "skipped": 5,
    "coverage": "85.2%"
  },
  "categories": {
    "unit": { "passed": 950, "failed": 5 },
    "integration": { "passed": 180, "failed": 3 },
    "e2e": { "passed": 105, "failed": 2 }
  },
  "performance": {
    "api_avg_response": "145ms",
    "matching_avg_time": "2.8s",
    "call_connection_avg": "4.2s"
  }
}
```

### 8.2 不具合分類
- **P1 (Critical)**: サービス停止、セキュリティ脆弱性
- **P2 (High)**: 主要機能の障害
- **P3 (Medium)**: 軽微な機能障害
- **P4 (Low)**: UI/UXの改善点

## 9. テストメンテナンス

### 9.1 定期見直し
- **週次**: テスト実行結果レビュー
- **月次**: テストカバレッジ分析
- **四半期**: テスト戦略見直し

### 9.2 テストコード品質
- DRY原則の適用
- 可読性の向上
- 実行速度の最適化
- フレーク（不安定）テストの排除

---

本テスト戦略に従って、KOEMOアプリケーションの品質を継続的に保証し、ユーザーに安全で信頼できるサービスを提供します。