---
name: full-script
description: 完成台本の出力契約
---

# Output Contract: full-script

## 期待形式
"## Script" 見出しの下に完成した番組台本が続く。

## パース規則（エンジンが抽出）
- script: "## Script" から次の "##" 見出しまたはファイル末尾までのテキスト

## 検証項目
- script が空でないこと（必須）
- script が 500 文字以上であること（必須）
