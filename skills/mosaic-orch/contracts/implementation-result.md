---
name: implementation-result
description: 実装結果の出力契約
---

# Output Contract: implementation-result

## 期待形式
"## Implementation Result" 見出しの下に変更ファイル一覧とテスト結果。

## パース規則（エンジンが抽出）
- files_changed: "- files_changed:" 直後のテキスト（配列として解析）
- test_results: "- test_results:" 直後のテキスト（複数行の場合あり）
- build_status: "- build_status:" 直後のテキスト。正規表現 /^(pass|fail)$/
- self_assessment: "- self_assessment:" 直後のテキスト

## 検証項目
- files_changed が空でないこと（必須）
- test_results が空でないこと（必須 — テスト実行なしは不合格）
- build_status が "pass" または "fail" であること（必須）
- self_assessment が空でないこと（必須）
