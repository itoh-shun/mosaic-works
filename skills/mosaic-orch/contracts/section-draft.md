---
name: section-draft
description: セクション原稿の出力契約
---

# Output Contract: section-draft

## 期待形式
"## Content" 見出しの下にセクション本文が続く。

## パース規則（エンジンが抽出）
- content: "## Content" から次の "##" 見出しまたはファイル末尾までのテキスト

## 検証項目
- content が空でないこと（必須）
- content が 500 文字以上であること（必須）
