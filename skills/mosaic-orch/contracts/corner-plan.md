---
name: corner-plan
description: コーナー企画の出力契約
---

# Output Contract: corner-plan

## 期待形式
"## Corners" 見出しの下に、3〜5個のコーナーが "### Corner N:" 形式で並ぶ。
各コーナーに theme, duration_min, description がある。

## パース規則（エンジンが抽出）
- corners: "### Corner" で始まる見出しごとにブロックを分割し、配列化する。各ブロックから:
  - name: 見出しのコロン以降のテキスト
  - theme: "- theme:" 直後のテキスト
  - duration_min: "- duration_min:" 直後の数値
  - description: "- description:" 直後のテキスト

## 検証項目
- corners の件数が 3〜5 の範囲（必須）
- 各 corner に theme が空でないこと（必須）
- 各 corner に duration_min が正の数であること（必須）
