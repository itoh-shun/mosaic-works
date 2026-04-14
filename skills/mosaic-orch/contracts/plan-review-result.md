---
name: plan-review-result
description: 計画検証の判定契約（verdict + 要件追跡 + 衝突検出 + スコープチェック）
---

# Output Contract: plan-review-result

## 期待形式
"## Plan Review" 見出しの下に verdict と criteria_coverage。"## Requirements Traceability" に要件追跡テーブル。"## File Conflict Check" にファイル衝突結果。"## Scope Check" にスコープチェック結果。"## Wave Dependency Check" にWave依存チェック結果。"## Findings" に指摘事項。

## パース規則（エンジンが抽出）
- verdict: "## Plan Review" セクション内の "- verdict:" 直後のテキスト。正規表現 /^(APPROVE|NEEDS_REVISION)$/
- criteria_coverage: "- criteria_coverage:" 直後のテキスト
- conflicts_found: "## File Conflict Check" セクション内の "- conflicts_found:" 直後のテキスト。正規表現 /^(true|false)$/
- unplanned_files_found: "## Scope Check" セクション内の "- unplanned_files_found:" 直後のテキスト。正規表現 /^(true|false)$/
- dependency_issues_found: "## Wave Dependency Check" セクション内の "- dependency_issues_found:" 直後のテキスト。正規表現 /^(true|false)$/
- findings: "## Findings" セクション内の "### Finding" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - finding_id: "- finding_id:" 直後のテキスト
  - axis: "- axis:" 直後のテキスト
  - severity: "- severity:" 直後のテキスト。正規表現 /^(critical|important)$/
  - detail: "- detail:" 直後のテキスト
  - recommendation: "- recommendation:" 直後のテキスト
  「なし」のみの場合は空配列

## 検証項目
- verdict が "APPROVE" または "NEEDS_REVISION" であること（必須）
- criteria_coverage が空でないこと（必須）
- conflicts_found が "true" または "false" であること（必須）
- unplanned_files_found が "true" または "false" であること（必須）
- dependency_issues_found が "true" または "false" であること（必須）
- verdict が "NEEDS_REVISION" の場合、findings の件数が 1 以上であること（必須）
