---
name: duplicate-check
description: 重複チェックの出力契約
---

# Output Contract: duplicate-check

## 期待形式
"## Duplicate Check" 見出しの下に重複有無とリスト。

## パース規則（エンジンが抽出）
- has_duplicate: "- has_duplicate:" 直後のテキスト。正規表現 /^(true|false)$/
- existing_prs: "- existing_prs:" 直後のテキスト（配列として解析、空の場合は空配列）
- recommendation: "- recommendation:" 直後のテキスト。正規表現 /^(proceed|ask_user)$/

## 検証項目
- has_duplicate が "true" または "false" であること（必須）
- recommendation が "proceed" または "ask_user" であること（必須）
- has_duplicate が true の場合、existing_prs が空でないこと（必須）
