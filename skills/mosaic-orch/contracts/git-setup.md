---
name: git-setup
description: Gitブランチセットアップの出力契約
---

# Output Contract: git-setup

## 期待形式
"## Git Setup" 見出しの下にIssue番号とブランチ名。

## パース規則（エンジンが抽出）
- issue_number: "- issue_number:" 直後のテキスト（数値）
- branch_name: "- branch_name:" 直後のテキスト
- base_branch: "- base_branch:" 直後のテキスト
- stacked_branches: "- stacked_branches:" 直後のテキスト（配列として解析、空の場合は空配列）

## 検証項目
- issue_number が正の整数であること（必須）
- branch_name が空でないこと（必須）
- base_branch が空でないこと（必須）
