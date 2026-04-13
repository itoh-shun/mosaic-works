---
name: full-article
description: 完成記事の出力契約
---

# Output Contract: full-article

## 期待形式
"## Article" 見出しの下に完成した技術記事が続く。

## パース規則（エンジンが抽出）
- article: "## Article" から次の "##" 見出しまたはファイル末尾までのテキスト

## 検証項目
- article が空でないこと（必須）
- article が 2000 文字以上であること（必須）
