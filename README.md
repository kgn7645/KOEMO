# KOEMO (コエモ) - Random Voice Call App

KOEMOは、ワンタップでランダムな相手と音声通話ができるiOSアプリケーションです。

## 🚀 特徴

- **ワンタップ通話**: 簡単操作で即座に通話開始
- **完全匿名**: 実名や連絡先は不要
- **段階的プロフィール開示**: 通話時間に応じて相手情報が表示
- **エフェメラル設計**: 24時間で履歴自動削除
- **安心・安全**: 24時間監視とブロック機能

## 🏗️ アーキテクチャ

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│   iOS App   │────▶│   API Server    │────▶│   MongoDB    │
│   (Swift)   │     │   (Node.js)     │     │   Atlas      │
└─────────────┘     └─────────────────┘     └──────────────┘
       │                     │
       │                     │
       ▼                     ▼
┌─────────────┐     ┌─────────────────┐
│  SkyWay SDK │     │ WebSocket Server│
│   (WebRTC)  │     │   (Socket.io)   │
└─────────────┘     └─────────────────┘
```

## 📁 プロジェクト構造

```
KOEMO/
├── ios/                    # iOS アプリケーション
├── backend/                # Node.js バックエンド
├── shared/                 # 共通ファイル・設定
├── docs/                   # プロジェクトドキュメント
├── scripts/                # 開発・デプロイスクリプト
└── infrastructure/         # インフラ設定（Terraform等）
```

## 🛠️ 開発環境

### 必要なツール
- Xcode 15.0+
- Node.js 18+
- CocoaPods
- MongoDB Atlas アカウント
- SkyWay アカウント

### セットアップ
詳細な環境構築手順は [docs/setup/development_setup.md](docs/setup/development_setup.md) を参照してください。

```bash
# リポジトリクローン
git clone https://github.com/yourcompany/koemo.git
cd koemo

# バックエンド環境構築
cd backend
npm install
cp .env.example .env
npm run dev

# iOS環境構築
cd ../ios
pod install
open KOEMO.xcworkspace
```

## 🧪 テスト実行

```bash
# バックエンドテスト
cd backend
npm test

# iOS テスト
cd ios
xcodebuild test -workspace KOEMO.xcworkspace -scheme KOEMO -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📚 ドキュメント

- [技術仕様書](docs/specifications/technical_specification.md)
- [API仕様書](docs/api/api_specification.md)
- [セキュリティ要件書](docs/security/security_requirements.md)
- [テスト戦略](docs/testing/test_strategy.md)
- [デプロイメント手順](docs/deployment/deployment_guide.md)
- [ユーザーマニュアル](docs/user_manual.md)

## 🚀 デプロイ

### 開発環境
```bash
# バックエンド起動
cd backend && npm run dev

# iOS シミュレータで実行
cd ios && open KOEMO.xcworkspace
```

### 本番環境
CI/CDパイプライン（GitHub Actions）により自動デプロイされます。

## 🤝 コントリビューション

1. Issue を作成して問題や改善案を報告
2. Feature ブランチを作成
3. 変更をコミット
4. Pull Request を作成

## 📄 ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 🆘 サポート

- [トラブルシューティングガイド](docs/troubleshooting/troubleshooting_guide.md)
- [GitHub Issues](https://github.com/yourcompany/koemo/issues)
- Email: support@koemo.app

---

© 2024 KOEMO Development Team