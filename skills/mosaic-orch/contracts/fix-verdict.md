---
name: fix-verdict
description: レビュー修正後の自己採点契約
---

# Output Contract: fix-verdict

## 期待形式
"## Grade" 見出しの直下に S/A+/A/B/C のいずれか。
"## Evidence" に修正内容と自己採点の根拠。"## Fixed Files" に修正ファイル一覧。

## パース規則（エンジンが抽出）
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- evidence: "## Evidence" から "## Fixed Files" までのテキスト
- fixed_files: "## Fixed Files" セクション内の箇条書きを配列化。各行からファイルパスを抽出

## 検証項目
- grade が正規表現にマッチすること（必須）
- evidence が空でないこと（必須）
- fixed_files が空でないこと（必須）
