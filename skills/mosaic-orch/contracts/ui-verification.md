---
name: ui-verification
description: UI視覚検証の出力契約
---

# Output Contract: ui-verification

## 期待形式
"## UI Verification" 見出しの下にスクリーンショット情報と比較結果。

## パース規則（エンジンが抽出）
- screenshots: "- screenshots:" 直後のテキスト（配列として解析）
- comparison_result: "- comparison_result:" 直後のテキスト。正規表現 /^(pass|warn|fail|ask_user)$/

## 検証項目
- screenshots が空でないこと（必須）
- comparison_result が "pass", "warn", "fail", "ask_user" のいずれかであること（必須）
