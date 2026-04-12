---
name: save-result
description: レビュー結果保存の出力契約
---

# Output Contract: save-result

## 期待形式
"## Save Result" 見出しの下に保存先パスと更新情報。

## パース規則（エンジンが抽出）
- review_path: "- review_path:" 直後のテキスト
- log_path: "- log_path:" 直後のテキスト（空の場合あり）
- error_patterns_updated: "- error_patterns_updated:" 直後のテキスト。正規表現 /^(true|false)$/

## 検証項目
- review_path が空でないこと（必須）
- error_patterns_updated が "true" または "false" であること（必須）
