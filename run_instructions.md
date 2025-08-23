# KOEMOアプリ実行手順

## Expo版を実行する（推奨 - すぐに試せます）

1. **Expoサーバーが起動しています！**
   - ブラウザで http://localhost:8081 が開きます
   - Metro Bundlerが実行中です

2. **iOSシミュレーターで実行するには：**
   ```
   # ターミナルで 'i' キーを押す
   # または新しいターミナルで：
   cd KOEMO-expo
   npm run ios
   ```

3. **実機で実行するには：**
   - Expo Goアプリをインストール（App Store）
   - QRコードをスキャン

## ネイティブiOS版を実行する（より完成度が高い）

1. **依存関係をインストール：**
   ```bash
   cd ios
   pod install
   ```

2. **Xcodeで開く：**
   ```bash
   open KOEMO.xcworkspace
   ```

3. **実行：**
   - シミュレーターを選択（iPhone 15推奨）
   - Run ボタンまたは Cmd+R

## バックエンドサーバーも起動する場合

```bash
# 新しいターミナルで
cd backend
npm install
npm run dev
```

## 注意事項

- Expo版にはreact-domのバージョン警告が出ていますが、動作には問題ありません
- 完全な機能を使うにはバックエンドサーバーも必要です
- WebRTC通話機能はバックエンドとの連携が必要です