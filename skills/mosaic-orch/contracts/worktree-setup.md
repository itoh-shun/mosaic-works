---
name: worktree-setup
description: Worktreeセットアップの出力契約
---

# Output Contract: worktree-setup

## 期待形式
"## Worktree Setup" 見出しの下にworktreeパスとブランチ情報。

## パース規則（エンジンが抽出）
- worktree_path: "- worktree_path:" 直後のテキスト
- branch_name: "- branch_name:" 直後のテキスト
- base_sha: "- base_sha:" 直後のテキスト。正規表現 /^[0-9a-f]{7,40}$/
- deps_installed: "- deps_installed:" 直後のテキスト。正規表現 /^(true|false)$/

## 検証項目
- worktree_path が空でないこと（必須）
- branch_name が空でないこと（必須）
- base_sha が有効なgit SHAフォーマットであること（必須）
- deps_installed が "true" または "false" であること（必須）
