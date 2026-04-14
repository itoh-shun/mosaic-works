---
name: ai-review-result
description: AI アンチパターンレビューの判定契約（verdict + finding_id追跡）
---

# Output Contract: ai-review-result

## 期待形式
"## AI Review" 見出しの下に verdict。"## Summary" に1文要約。"## Checks" にチェック表。"## Findings (new)" / "(persists)" / "(resolved)" に指摘事項。

## パース規則（エンジンが抽出）
- verdict: "## AI Review" セクション内の "- verdict:" 直後のテキスト。正規表現 /^(APPROVE|REJECT)$/
- summary: "## Summary" セクション全体のテキスト
- findings_new: "## Findings (new)" セクション内の "### Finding" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - finding_id: "- finding_id:" 直後のテキスト。正規表現 /^AI-NEW-/
  - category: "- category:" 直後のテキスト。正規表現 /^(hallucinated_api|scope_creep|dead_code|fallback_abuse|context_mismatch|assumption|backward_compat)$/
  - location: "- location:" 直後のテキスト
  - problem: "- problem:" 直後のテキスト
  - fix: "- fix:" 直後のテキスト
- findings_persists: "## Findings (persists)" セクション内の "### Finding" ブロックを配列化。各ブロックから:
  - finding_id: 正規表現 /^AI-PERSIST-/
  - category, prev_evidence, current_evidence, problem, fix
- findings_resolved: "## Findings (resolved)" セクション内の "- finding_id:" 行を配列化。各行から finding_id（正規表現 /^AI-RESOLVED-/）と evidence

（各セクション「なし」のみの場合は空配列）

## 検証項目
- verdict が "APPROVE" または "REJECT" であること（必須）
- summary が空でないこと（必須）
- verdict が "REJECT" の場合、findings_new または findings_persists の件数合計が 1 以上であること（必須）
- findings_new の各 finding_id が /^AI-NEW-/ にマッチすること（必須）
- findings_persists の各 finding_id が /^AI-PERSIST-/ にマッチすること（必須）
- findings_resolved の各 finding_id が /^AI-RESOLVED-/ にマッチすること（必須）
- findings_new と findings_persists の各 finding に category が 7 種のいずれかであること（必須）
