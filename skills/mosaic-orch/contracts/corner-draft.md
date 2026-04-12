---
name: corner-draft
description: コーナー原稿の出力契約
---

# Output Contract: corner-draft

## 期待形式
"## Script" 見出しの下に台本テキストが続く。

## パース規則（エンジンが抽出）
- script: "## Script" から次の "##" 見出しまたはファイル末尾までのテキスト

## 検証項目
- script が空でないこと（必須）
- script が 100 文字以上であること（必須）
