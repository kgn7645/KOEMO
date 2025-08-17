# KOEMO 開発環境構築手順書

## 1. 概要

本文書は、KOEMOプロジェクトの開発環境をセットアップするための包括的な手順書です。iOS開発とNode.jsバックエンド開発の両方の環境構築について説明します。

## 2. 前提条件

### 2.1 ハードウェア要件
- **Mac**: macOS 13.0 (Ventura) 以上
- **メモリ**: 16GB以上推奨
- **ストレージ**: 100GB以上の空き容量
- **CPU**: Intel Core i5 / Apple M1以上

### 2.2 アカウント要件
- Apple Developer Account（iOS開発用）
- GitHub アカウント
- MongoDB Atlas アカウント（クラウドDB用）
- SkyWay アカウント（WebRTC SDK用）

## 3. 基本ツールのインストール

### 3.1 Homebrew インストール
```bash
# Homebrewのインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# パス設定（Apple Silicon Mac の場合）
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### 3.2 Git インストール・設定
```bash
# Gitインストール
brew install git

# Git設定
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global init.defaultBranch main
```

### 3.3 基本開発ツール
```bash
# 必須ツール
brew install curl wget
brew install jq        # JSON処理ツール
brew install tree      # ディレクトリ構造表示
```

## 4. iOS 開発環境

### 4.1 Xcode インストール
```bash
# Xcodeをインストール（App Storeまたは）
# https://developer.apple.com/xcode/

# コマンドラインツールのインストール
xcode-select --install

# Xcodeバージョン確認
xcode-select -p
```

### 4.2 iOS Simulator 設定
```bash
# 利用可能なシミュレータ一覧
xcrun simctl list devices

# iOS 17.0 シミュレータの作成
xcrun simctl create "iPhone 15" "iPhone 15" "iOS 17.0"
```

### 4.3 CocoaPods インストール
```bash
# Ruby環境確認
ruby --version

# CocoaPodsインストール
sudo gem install cocoapods

# CocoaPods設定
pod setup
```

### 4.4 iOS プロジェクト初期化
```bash
# プロジェクトディレクトリ作成
mkdir -p KOEMO/ios
cd KOEMO/ios

# Xcodeプロジェクト作成（Xcode GUIで作成）
# File > New > Project
# iOS > App
# Product Name: KOEMO
# Bundle Identifier: com.yourcompany.koemo
# Language: Swift
# Interface: UIKit
# Use Core Data: No

# Podfile作成
cat > Podfile << 'EOF'
platform :ios, '15.0'

target 'KOEMO' do
  use_frameworks!
  
  # WebRTC SDK
  pod 'SkyWay', '~> 4.0'
  
  # Networking
  pod 'Alamofire', '~> 5.8'
  
  # JSON Parsing
  pod 'SwiftyJSON', '~> 5.0'
  
  # Socket.IO
  pod 'Socket.IO-Client-Swift', '~> 16.0'
  
  # UI Components
  pod 'SnapKit', '~> 5.6'
  
  target 'KOEMOTests' do
    inherit! :search_paths
    pod 'Quick', '~> 7.0'
    pod 'Nimble', '~> 12.0'
  end
end
EOF

# Pod依存関係インストール
pod install

# Workspaceを開く
open KOEMO.xcworkspace
```

## 5. Node.js バックエンド環境

### 5.1 Node.js インストール
```bash
# Node Version Manager (nvm) インストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# シェル再起動
source ~/.zshrc

# Node.js 18 LTS インストール
nvm install 18
nvm use 18
nvm alias default 18

# バージョン確認
node --version
npm --version
```

### 5.2 バックエンドプロジェクト初期化
```bash
# プロジェクトディレクトリ作成
mkdir -p KOEMO/backend
cd KOEMO/backend

# package.json 初期化
npm init -y

# 必要なパッケージインストール
cat > package.json << 'EOF'
{
  "name": "koemo-backend",
  "version": "1.0.0",
  "description": "KOEMO Backend Server",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest",
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix"
  },
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.4",
    "mongoose": "^8.0.3",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "dotenv": "^16.3.1",
    "express-rate-limit": "^7.1.5",
    "express-validator": "^7.0.1",
    "winston": "^3.11.0",
    "node-cron": "^3.0.3"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0",
    "supertest": "^6.3.3",
    "eslint": "^8.55.0",
    "eslint-config-prettier": "^9.1.0",
    "prettier": "^3.1.1",
    "@types/node": "^20.10.5"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# パッケージインストール
npm install

# TypeScript開発環境（オプション）
npm install -D typescript @types/express @types/socket.io
npx tsc --init
```

### 5.3 プロジェクト構造作成
```bash
# ディレクトリ構造作成
mkdir -p src/{controllers,models,routes,middleware,services,utils,config}
mkdir -p tests/{unit,integration}
mkdir -p logs

# 基本ファイル作成
cat > src/index.js << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.CLIENT_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Socket.io connection
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`KOEMO Backend running on port ${PORT}`);
});
EOF

# 環境変数ファイル
cat > .env.example << 'EOF'
# サーバー設定
PORT=3000
NODE_ENV=development

# データベース
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/koemo

# JWT設定
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=1h
REFRESH_TOKEN_SECRET=your-refresh-secret
REFRESH_TOKEN_EXPIRES_IN=30d

# WebRTC (SkyWay)
SKYWAY_API_KEY=your-skyway-api-key
SKYWAY_SECRET_KEY=your-skyway-secret

# Redis（セッション管理）
REDIS_URL=redis://localhost:6379

# ログ設定
LOG_LEVEL=debug
LOG_DIR=./logs

# Apple App Store
APPLE_APP_SECRET=your-app-secret

# プッシュ通知
APNS_KEY_ID=your-apns-key-id
APNS_TEAM_ID=your-team-id
APNS_AUTH_KEY=your-auth-key
EOF

cp .env.example .env
```

## 6. データベース環境

### 6.1 MongoDB Atlas 設定
```bash
# MongoDB Compass インストール（GUI管理ツール）
brew install --cask mongodb-compass

# MongoDB CLI ツールインストール
brew install mongosh

# 接続テスト
mongosh "mongodb+srv://your-connection-string"
```

### 6.2 Redis インストール（キャッシュ・セッション用）
```bash
# Redis インストール
brew install redis

# Redis 起動
brew services start redis

# Redis CLI テスト
redis-cli ping
```

## 7. 開発ツール

### 7.1 VS Code セットアップ
```bash
# VS Code インストール
brew install --cask visual-studio-code

# VS Code 拡張機能インストール
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension bradlc.vscode-tailwindcss
code --install-extension esbenp.prettier-vscode
code --install-extension ms-vscode.vscode-json
code --install-extension formulahendry.auto-rename-tag
code --install-extension ms-vscode.vscode-eslint
```

### 7.2 Postman インストール（API テスト用）
```bash
brew install --cask postman
```

### 7.3 Docker セットアップ（コンテナ開発用）
```bash
# Docker Desktop インストール
brew install --cask docker

# Docker Compose 設定ファイル
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: koemo-mongo
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password123
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

  redis:
    image: redis:7.2-alpine
    container_name: koemo-redis
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  backend:
    build: ./backend
    container_name: koemo-backend
    restart: always
    environment:
      NODE_ENV: development
      MONGODB_URI: mongodb://admin:password123@mongodb:27017/koemo?authSource=admin
      REDIS_URL: redis://redis:6379
    ports:
      - "3000:3000"
    depends_on:
      - mongodb
      - redis
    volumes:
      - ./backend:/app
      - /app/node_modules

volumes:
  mongo_data:
  redis_data:
EOF

# Docker Compose 起動
docker-compose up -d
```

## 8. 外部サービス設定

### 8.1 SkyWay アカウント設定
1. [SkyWay Console](https://console.ntt.com/skyway/) にアクセス
2. 新規アプリケーション作成
3. API Key と Secret Key を取得
4. `.env` ファイルに設定

### 8.2 Apple Developer 設定
1. [Apple Developer Portal](https://developer.apple.com/) にログイン
2. Certificates, Identifiers & Profiles で設定
3. App ID 作成（Bundle ID: com.yourcompany.koemo）
4. Development Certificate 作成
5. Provisioning Profile 作成

### 8.3 MongoDB Atlas 設定
1. [MongoDB Atlas](https://cloud.mongodb.com/) にログイン
2. 新規クラスター作成
3. データベースユーザー作成
4. ネットワークアクセス設定
5. 接続文字列を取得

## 9. 開発環境確認

### 9.1 iOS 開発環境テスト
```bash
cd ios
# プロジェクトビルド
xcodebuild -workspace KOEMO.xcworkspace -scheme KOEMO -sdk iphonesimulator

# シミュレータでビルド・実行
xcodebuild -workspace KOEMO.xcworkspace -scheme KOEMO -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 9.2 Backend 環境テスト
```bash
cd backend

# 開発サーバー起動
npm run dev

# 別ターミナルでAPIテスト
curl http://localhost:3000/health

# テスト実行
npm test
```

### 9.3 フルスタック連携テスト
```bash
# バックエンド起動
cd backend && npm run dev

# iOSアプリからAPI接続確認
# Xcodeでアプリ実行し、ネットワーク通信をテスト
```

## 10. 開発ワークフロー

### 10.1 Git ワークフロー
```bash
# 機能ブランチ作成
git checkout -b feature/user-registration

# 変更をコミット
git add .
git commit -m "feat: implement user registration API"

# プッシュ
git push origin feature/user-registration

# プルリクエスト作成（GitHub Web UI）
```

### 10.2 デバッグ設定
```bash
# Node.js デバッグ設定
cat > .vscode/launch.json << 'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Backend",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/backend/src/index.js",
      "env": {
        "NODE_ENV": "development"
      },
      "console": "integratedTerminal",
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
EOF
```

## 11. トラブルシューティング

### 11.1 よくある問題

#### iOS 関連
```bash
# CocoaPods キャッシュクリア
pod cache clean --all
pod install --clean-install

# Xcode DerivedData クリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# iOS Simulator リセット
xcrun simctl erase all
```

#### Node.js 関連
```bash
# node_modules クリア
rm -rf node_modules package-lock.json
npm install

# npm キャッシュクリア
npm cache clean --force

# Node.js バージョン確認・切り替え
nvm list
nvm use 18
```

#### MongoDB 関連
```bash
# MongoDB 接続テスト
mongosh "your-connection-string" --eval "db.runCommand({ping: 1})"

# ローカル MongoDB 起動
brew services restart mongodb-community
```

### 11.2 パフォーマンス最適化
```bash
# npm スクリプト最適化
npm run lint:fix    # コード修正
npm run test        # テスト実行
npm audit fix       # セキュリティ修正
```

## 12. 環境固有設定

### 12.1 開発環境 (.env.development)
```bash
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/koemo_dev
LOG_LEVEL=debug
```

### 12.2 テスト環境 (.env.test)
```bash
NODE_ENV=test
PORT=3001
MONGODB_URI=mongodb://localhost:27017/koemo_test
LOG_LEVEL=error
```

### 12.3 本番環境 (.env.production)
```bash
NODE_ENV=production
MONGODB_URI=mongodb+srv://...atlas.mongodb.net/koemo
LOG_LEVEL=warn
```

## 13. チェックリスト

### 13.1 初期セットアップ完了チェック
- [ ] Xcode インストール・プロジェクト作成完了
- [ ] CocoaPods 依存関係インストール完了
- [ ] Node.js プロジェクト初期化完了
- [ ] MongoDB Atlas 接続確認完了
- [ ] SkyWay アカウント設定完了
- [ ] iOS シミュレータでアプリ起動確認
- [ ] Backend サーバー起動確認
- [ ] API エンドポイント疎通確認

### 13.2 開発環境準備完了チェック
- [ ] Git 設定完了
- [ ] VS Code 拡張機能インストール完了
- [ ] Docker 環境構築完了
- [ ] デバッグ設定完了
- [ ] ESLint/Prettier 設定完了

## 14. 次のステップ

1. **機能実装開始**: 各機能の実装に着手
2. **CI/CD パイプライン構築**: GitHub Actions 設定
3. **テスト環境デプロイ**: AWS/Azure テスト環境構築
4. **セキュリティ設定**: 本番環境のセキュリティ強化

---

本手順書に従って環境構築を完了すると、KOEMOプロジェクトの開発を開始できます。問題が発生した場合は、トラブルシューティングセクションを参照してください。