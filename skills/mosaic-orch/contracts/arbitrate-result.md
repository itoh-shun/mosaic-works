---
name: arbitrate-result
description: ai-review vs ai-fix の仲裁判定契約
---

# Output Contract: arbitrate-result

## 期待形式
"## Arbitration" 見出しの下に verdict と summary。"## Verified Files" に独立検証したファイル。"## Judgments" に各 finding の判定。"## Required Actions" に追加修正項目。

## パース規則（エンジンが抽出）
- verdict: "## Arbitration" セクション内の "- verdict:" 直後のテキスト。正規表現 /^(ESCALATE_TO_FIX|APPROVE_FIXER)$/
- summary: "- summary:" 直後のテキスト
- verified_files: "## Verified Files" セクション内の "- " で始まる各行を配列化
- judgments: "## Judgments" セクション内の "### Judgment" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - finding_id: "- finding_id:" 直後のテキスト
  - reviewer_claim: "- reviewer_claim:" 直後のテキスト
  - fixer_claim: "- fixer_claim:" 直後のテキスト
  - decision: "- decision:" 直後のテキスト。正規表現 /^(reviewer_right|fixer_right|partial)$/
  - evidence: "- evidence:" 直後のテキスト
  - reasoning: "- reasoning:" 直後のテキスト
- required_actions: "## Required Actions" セクション内の "- " で始まる各行を配列化（「なし」のみの場合は空配列）

## 検証項目
- verdict が "ESCALATE_TO_FIX" または "APPROVE_FIXER" であること（必須）
- summary が空でないこと（必須）
- verified_files の件数が 1 以上であること（必須 — 独立検証なしの裁定は無効）
- judgments の件数が 1 以上であること（必須）
- 各 judgment に decision が reviewer_right/fixer_right/partial のいずれかであること（必須）
- verdict が "ESCALATE_TO_FIX" の場合、required_actions の件数が 1 以上であること（必須）
