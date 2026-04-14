---
name: ui-verification
description: マルチビューポート・マルチテーマUI視覚検証の出力契約
---

# Output Contract: ui-verification

## 期待形式
"## UI Verification" 見出しの下にスクリーンショット情報、各ビューポート判定、総合判定。

## パース規則（エンジンが抽出）
- screenshots_taken: "- screenshots_taken:" 直後のテキスト
- desktop_light: "- desktop_light:" 直後のテキスト。正規表現 /^(pass|warn|fail)$/
- desktop_dark: "- desktop_dark:" 直後のテキスト。正規表現 /^(pass|warn|fail)$/
- mobile_light: "- mobile_light:" 直後のテキスト。正規表現 /^(pass|warn|fail)$/
- mobile_dark: "- mobile_dark:" 直後のテキスト。正規表現 /^(pass|warn|fail)$/
- dark_mode_support: "- dark_mode_support:" 直後のテキスト。正規表現 /^(full|partial|none)$/
- responsive_support: "- responsive_support:" 直後のテキスト。正規表現 /^(full|partial|none)$/
- design_consistency: "- design_consistency:" 直後のテキスト。正規表現 /^(pass|warn|fail)$/
- overall: "- overall:" 直後のテキスト。正規表現 /^(pass|warn|fail)$/
- issues: "- issues:" 直後のテキスト（配列として解析）

## 検証項目
- screenshots_taken が空でないこと（必須 — スクリーンショット0枚は不合格）
- desktop_light が "pass", "warn", "fail" のいずれかであること（必須）
- desktop_dark が "pass", "warn", "fail" のいずれかであること（必須 — ダークモード検証スキップ不可）
- mobile_light が "pass", "warn", "fail" のいずれかであること（必須 — モバイル検証スキップ不可）
- mobile_dark が "pass", "warn", "fail" のいずれかであること（必須）
- dark_mode_support が "full", "partial", "none" のいずれかであること（必須）
- responsive_support が "full", "partial", "none" のいずれかであること（必須）
- overall が "pass", "warn", "fail" のいずれかであること（必須）
