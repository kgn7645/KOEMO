# iOS KOEMO アプリセットアップ手順

## 現在の状態
- ✅ Xcodeプロジェクトが開いています
- ⚠️ CocoaPodsの依存関係が未インストール

## 必要な手順

### 1. CocoaPodsをインストール (ターミナルで実行)
```bash
sudo gem install cocoapods
```

### 2. 依存関係をインストール
```bash
cd /Users/sou/Documents/AI_Driven_Dev/KOEMO/ios
pod install
```

### 3. ワークスペースを開く（重要！）
```bash
open KOEMO.xcworkspace
```
※ `.xcworkspace`を使用することが重要です（`.xcodeproj`ではなく）

## Xcodeでの実行手順

1. **スキーム選択**: 上部のツールバーで「KOEMO」スキームが選択されていることを確認
2. **デバイス選択**: iPhone 15 などのシミュレーターを選択
3. **実行**: ▶️ ボタンをクリックまたは Cmd+R

## 現在ビルドできない理由

CocoaPodsの依存関係（SkyWay、Alamofire等）がインストールされていないため、以下のようなエラーが表示される可能性があります：
- "No such module 'Alamofire'"
- "No such module 'SkyWay'"

## 暫定的な対処法（CocoaPodsなしで動作確認）

もしCocoaPodsをインストールできない場合は、依存関係を一時的にコメントアウトして基本的なUIだけ確認することも可能です。