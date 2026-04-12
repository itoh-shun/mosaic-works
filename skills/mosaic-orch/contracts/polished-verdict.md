---
name: polished-verdict
description: 修正後の台本 + 自己採点の出力契約
---

# Output Contract: polished-verdict

## 期待形式
"## Script" に修正後台本。"## Grade" に自己採点。
"## Evidence" に根拠。"## Suggestions" に残存改善余地。

## パース規則（エンジンが抽出）
- script: "## Script" から "## Grade" までのテキスト
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- evidence: "## Evidence" から "## Suggestions" までのテキスト
- suggestions: "## Suggestions" から末尾まで、箇条書きを配列化

## 検証項目
- script が空でないこと（必須）
- script が 500 文字以上であること（必須）
- grade が正規表現にマッチすること（必須）
- evidence が空でないこと（必須）
