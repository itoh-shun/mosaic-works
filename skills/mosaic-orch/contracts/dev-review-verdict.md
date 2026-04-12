---
name: dev-review-verdict
description: 5軸コードレビューの総合判定契約
---

# Output Contract: dev-review-verdict

## 期待形式
"## Grade" 見出しの直下に S/A+/A/B/C のいずれか。
"## Axes" に5軸の個別評価。"## Evidence" に根拠。"## Issues" に修正必須項目。"## Suggestions" に改善提案。

## パース規則（エンジンが抽出）
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- axes: "## Axes" セクション内の各行を解析:
  - performance: "- performance:" 直後の最初の単語、正規表現 /^(S|A\+|A|B|C)/
  - naming: "- naming:" 直後の最初の単語
  - testing: "- testing:" 直後の最初の単語
  - security: "- security:" 直後の最初の単語
  - design: "- design:" 直後の最初の単語
- evidence: "## Evidence" から "## Issues" までのテキスト
- issues: "## Issues" から "## Suggestions" までのテキスト、箇条書きを配列化
- suggestions: "## Suggestions" から末尾まで、箇条書きを配列化

## 検証項目
- grade が正規表現にマッチすること（必須）
- axes の5軸すべてが存在し、正規表現にマッチすること（必須）
- evidence が空でないこと（必須）
- grade が A+ 未満の場合、issues が空でないこと（必須）
