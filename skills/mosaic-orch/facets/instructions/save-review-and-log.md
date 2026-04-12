---
name: save-review-and-log
description: レビュー結果のJSON保存、error-patterns追記、通信ログの指示
---

# 指示: レビュー結果の保存とログ記録

レビュー結果を構造化保存し、エラーパターンを更新してください。

## 手順

### Step 1: レビュー結果のJSON保存

`.mosaic-orch/reviews/` ディレクトリにJSON形式で保存する:

```bash
mkdir -p .mosaic-orch/reviews
```

ファイル名: `{YYYY-MM-DD}-{slug}.json`

保存内容:
```json
{
  "date": "{YYYY-MM-DD}",
  "task": "{タスク内容}",
  "mode": "{parallel | wave | single}",
  "team": [
    { "persona": "{persona名}", "instruction": "{instruction名}", "wave": 1 }
  ],
  "skills_used": ["{スキル名}"],
  "review": {
    "grade": "{総合グレード}",
    "axes": {
      "performance": "{grade}",
      "naming": "{grade}",
      "testing": "{grade}",
      "security": "{grade}",
      "design": "{grade}"
    },
    "issues": ["{指摘事項}"],
    "iterations": "{修正ループ回数}"
  }
}
```

### Step 2: エラーパターン追記

レビューで新たに検出されたパターン（既存のerror-patternsに未記載のもの）があれば、Knowledge の error-patterns ファイルに追記する。

追記する情報:
- パターン名
- カテゴリ（パフォーマンス / 命名 / テスト / セキュリティ / 設計）
- 説明

### Step 3: 通信ログ（任意）

プロジェクトで通信ログの規約がある場合は従う。ない場合はスキップ。

## 出力フォーマット

## Save Result
- review_path: {レビューJSONのパス}
- log_path: {通信ログのパス（あれば）}
- error_patterns_updated: true | false
- new_patterns: [{パターン名}, ...]
