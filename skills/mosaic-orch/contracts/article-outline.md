---
name: article-outline
description: 記事構成案の出力契約
---

# Output Contract: article-outline

## 期待形式
"## Sections" 見出しの下に、3〜6個のセクションが "### Section N:" 形式で並ぶ。
各セクションに aim, estimated_chars がある。

## パース規則（エンジンが抽出）
- sections: "### Section" で始まる見出しごとにブロックを分割し、配列化する。各ブロックから:
  - title: 見出しのコロン以降のテキスト
  - aim: "- aim:" 直後のテキスト
  - estimated_chars: "- estimated_chars:" 直後の数値

## 検証項目
- sections の件数が 3〜6 の範囲（必須）
- 各 section に title が空でないこと（必須）
- 各 section に aim が空でないこと（必須）
- 各 section に estimated_chars が正の数であること（必須）
