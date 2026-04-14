---
name: implementation-result
description: 実装結果の出力契約
---

# Output Contract: implementation-result

## 期待形式
"## Implementation Result" 見出しの下に変更ファイル一覧とテスト結果。

## パース規則（エンジンが抽出）
- files_changed: "- files_changed:" 直後のテキスト（配列として解析）
- test_results: "- test_results:" 直後のテキスト（複数行の場合あり。実行コマンドと出力を含む）
- test_count: "- test_count:" 直後の数値。正規表現 /^\d+$/
- build_status: "- build_status:" 直後のテキスト。正規表現 /^(pass|fail)$/
- build_command: "- build_command:" 直後のテキスト（実行したビルドコマンド）
- skills_used: "- skills_used:" 直後のテキスト（配列として解析）。実際に Skill tool で起動したスキル名のリスト
- self_assessment: "- self_assessment:" 直後のテキスト
- concerns: "- concerns:" 直後のテキスト（任意）

## 検証項目
- files_changed が空でないこと（必須）
- test_results が空でないこと（必須 — テスト実行なしは不合格）
- test_results に実行コマンド（`npm test`, `node --test`, `./gradlew test` 等）が含まれていること（必須 — 「テストを書いた」の自己申告不可。実行結果の貼り付けが必要）
- test_count が 1 以上であること（必須 — テスト件数0は不合格）
- build_status が "pass" であること（必須 — **fail のままコミットしてはならない**。fail の場合は ContractViolation として差し戻す）
- build_command が空でないこと（必須 — 実行したビルドコマンドを記録）
- skills_used が空でないこと（必須 — スキルが割り当てられている場合、最低1つは使用すること。使用スキル0件は ContractViolation として差し戻す。スキル未割り当ての stage では `[none]` と記載可）
- self_assessment が空でないこと（必須）
