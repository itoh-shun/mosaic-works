---
name: quality-result
description: 品質ゲートの出力契約
---

# Output Contract: quality-result

## 期待形式
"## Quality Result" 見出しの下にPRサイズとテスト存在とビルド結果。

## パース規則（エンジンが抽出）
- pr_size: "- pr_size:" 直後のテキスト（数値）
- pr_size_verdict: "- pr_size_verdict:" 直後のテキスト。正規表現 /^(S|M|L|XL)$/
- test_exists: "- test_exists:" 直後のテキスト。正規表現 /^(true|false)$/
- test_sufficient: "- test_sufficient:" 直後のテキスト。正規表現 /^(true|false)$/
- build_lint_ok: "- build_lint_ok:" 直後のテキスト。正規表現 /^(true|false)$/
- overall: "- overall:" 直後のテキスト。正規表現 /^(pass|fail)$/
- fail_reasons: "- fail_reasons:" 直後のテキスト（配列として解析）

## 検証項目
- pr_size_verdict が "S", "M", "L", "XL" のいずれかであること（必須）
- test_exists が "true" または "false" であること（必須）
- test_sufficient が "true" または "false" であること（必須）
- build_lint_ok が "true" または "false" であること（必須）
- overall が "pass" または "fail" であること（必須）
- overall が "fail" の場合、fail_reasons が空でないこと（必須 — 不合格理由なしの fail は不可）
