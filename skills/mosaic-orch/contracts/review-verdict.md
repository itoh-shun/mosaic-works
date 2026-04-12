---
name: review-verdict
description: 多角レビューの総合判定
---

# Output Contract: review-verdict

## 期待形式
"## Grade" 見出しの直下に S/A+/A/B/C のいずれか。
"## Evidence" に根拠。"## Suggestions" に改善提案。

## パース規則（エンジンが抽出）
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- evidence: "## Evidence" から "## Suggestions" までのテキスト
- suggestions: "## Suggestions" から末尾まで、箇条書きを配列化

## 検証項目
- grade が正規表現にマッチすること（必須）
- evidence が空でないこと（必須）
- suggestions の件数が 0〜5 の範囲（推奨）
