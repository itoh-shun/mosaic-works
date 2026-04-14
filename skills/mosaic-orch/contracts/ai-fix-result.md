---
name: ai-fix-result
description: AI Review 指摘に対する修正実施結果の契約
---

# Output Contract: ai-fix-result

## 期待形式
"## AI Fix" 見出しの下に action と findings_addressed。"## Verified Files" に確認したファイル。"## Searches Executed" に実行した grep。"## Fixes Applied" に適用した修正。"## No Fix Needed" に修正不要判断。"## Test Summary" にテスト結果。

## パース規則（エンジンが抽出）
- action: "## AI Fix" セクション内の "- action:" 直後のテキスト。正規表現 /^(fixed|no_fix_needed|partial)$/
- findings_addressed: "- findings_addressed:" 直後のテキスト（"N/M" 形式）
- verified_files: "## Verified Files" セクション内の "- " で始まる各行を配列化
- searches_executed: "## Searches Executed" セクション内の "- " で始まる各行を配列化
- fixes_applied: "## Fixes Applied" セクション内の "### Fix" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - finding_id: "- finding_id:" 直後のテキスト
  - file: "- file:" 直後のテキスト
  - change: "- change:" 直後のテキスト
  - test_result: "- test_result:" 直後のテキスト
- no_fix_needed: "## No Fix Needed" セクション内の "### Finding" ブロックを配列化。各ブロックから:
  - finding_id: "- finding_id:" 直後のテキスト
  - reason: "- reason:" 直後のテキスト
  - evidence: "- evidence:" 直後のテキスト
- test_summary: "## Test Summary" セクション全体のテキスト

（各セクション「なし」のみの場合は空配列）

## 検証項目
- action が "fixed", "no_fix_needed", "partial" のいずれかであること（必須）
- findings_addressed が空でないこと（必須）
- verified_files の件数が 1 以上であること（必須 — ファイル確認なしの判断は無効）
- action が "fixed" の場合、fixes_applied の件数が 1 以上であること（必須）
- action が "no_fix_needed" の場合、no_fix_needed の件数が 1 以上であること（必須）
- action が "partial" の場合、fixes_applied と no_fix_needed の両方が 1 以上であること（必須）
- test_summary が空でないこと（必須）
