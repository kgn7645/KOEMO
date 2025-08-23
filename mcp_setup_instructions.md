# MCPサーバー設定手順

## Claude Desktopへの設定追加

Claude DesktopにMCPサーバーを追加するには、以下の手順を実行してください：

### 1. Claude Desktopの設定ファイルを開く

```bash
# macOSの場合
~/Library/Application Support/Claude/claude_desktop_config.json
```

### 2. xcodeproj-mcp-serverの設定を追加

設定ファイルに以下の内容を追加します：

```json
{
  "mcpServers": {
    "xcodeproj": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-v",
        "${cwd}:/workspace",
        "ghcr.io/giginet/xcodeproj-mcp-server",
        "/workspace"
      ]
    }
  }
}
```

### 3. Claude Desktopを再起動

設定を反映させるために、Claude Desktopアプリケーションを完全に終了してから再起動してください。

### 4. 動作確認

Claude Desktopで以下のコマンドを実行して、MCPサーバーが正しく認識されているか確認：

```
claude mcp list
```

## 注意事項

- Dockerが起動していることを確認してください
- プロジェクトディレクトリで作業する際は、必ず`/workspace`パスを使用してください
- 相対パスでXcodeプロジェクトを参照する必要があります

## トラブルシューティング

もし設定が反映されない場合：
1. Claude Desktopを完全に終了（Cmd+Q）
2. 設定ファイルのJSONフォーマットが正しいか確認
3. Dockerデーモンが起動しているか確認