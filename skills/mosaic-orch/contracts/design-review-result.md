---
name: design-review-result
description: AI設計レビューの判定契約（verdict + 5軸評価 + findings）
---

# Output Contract: design-review-result

## 期待形式
"## Design Review" 見出しの下に verdict と score。"## Axes" に5軸の個別評価。"## Findings" に指摘事項。

## パース規則（エンジンが抽出）
- verdict: "## Design Review" セクション内の "- verdict:" 直後のテキスト。正規表現 /^(APPROVE|NEEDS_REVISION)$/
- score: "- score:" 直後のテキスト。正規表現 /^(S|A\+|A|B|C)$/
- axes: "## Axes" セクション内の各行を解析:
  - completeness: "- completeness:" 直後の最初の単語、正規表現 /^(S|A\+|A|B|C)/
  - file_design: "- file_design:" 直後の最初の単語
  - scope: "- scope:" 直後の最初の単語
  - feasibility: "- feasibility:" 直後の最初の単語
  - dependencies: "- dependencies:" 直後の最初の単語
- findings: "## Findings" セクション内の "### Finding" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - finding_id: "- finding_id:" 直後のテキスト
  - axis: "- axis:" 直後のテキスト
  - severity: "- severity:" 直後のテキスト。正規表現 /^(critical|important|suggestion)$/
  - detail: "- detail:" 直後のテキスト
  - recommendation: "- recommendation:" 直後のテキスト
  「なし」のみの場合は空配列

## 検証項目
- verdict が "APPROVE" または "NEEDS_REVISION" であること（必須）
- score が S/A+/A/B/C のいずれかであること（必須）
- axes の5軸すべてが存在し、正規表現にマッチすること（必須）
- verdict が "NEEDS_REVISION" の場合、findings の件数が 1 以上であること（必須）
- findings の各 finding に severity が critical/important/suggestion のいずれかであること
