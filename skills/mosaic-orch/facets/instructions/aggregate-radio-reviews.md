---
name: aggregate-radio-reviews
description: 6名レビュー結果を集約し、最低grade・修正要否・統合findingsを出力する
---

# 指示: ラジオレビュー集約

6 名のレビュー結果（fan_outの各出力）を集約し、修正の要否と全レビュー指摘の統合リストを生成してください。

## 手順

### Step 1: 各レビュアーの grade を抽出
- Reviewer 1〜6 の `grade` フィールドを取得
- S=6, A+=5, A=4, B+=3, B=2, C=1 として数値化

### Step 2: 最低grade と平均grade を算出
- `min_grade`: 6 名中の最低 grade（例: 5名がA+で1名がBなら min=B）
- `avg_grade`: 数値化した grade の平均を再度 grade 文字列に丸める（5.5 → A+, 4.5 → A+, 4.0 → A など）

### Step 3: 修正要否判定
- `should_polish`: 以下のいずれかに該当する場合 true
  - min_grade が B+ 以下
  - avg_grade が A 未満
- それ以外は false（save に進む）

### Step 4: 統合findings
- 全レビュアーの suggestions を集約し、優先度順に並べる
- 重複する指摘はマージし、「N 名が同様の指摘」と注記
- 各 finding に reviewer_names: [野沢修一, 河野理沙, ...] を付与

### Step 5: 最終台本の参照を維持
- `final_script`: 現在の台本（assemble.output または最後の polish 後の台本）をそのまま受け渡す

## 出力フォーマット（厳守）

## Aggregated Review
- min_grade: {S|A+|A|B+|B|C}
- avg_grade: {S|A+|A|B+|B|C}
- should_polish: {true|false}
- reviewers_a_plus_or_above: {数}
- reviewers_b_or_below: {数}

## Findings (優先度順)
### Finding 1
- description: {統合された指摘}
- reviewer_names: [野沢修一, 黒田誠]
- suggested_fix: {書き換え案またはアクション}
- priority: {high|medium|low}

### Finding 2
...

## Final Script
{現在の台本本文をそのまま貼り付け}
