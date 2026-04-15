---
name: polish-radio-script
description: 集約レビューに基づきラジオ台本を修正する指示
---

# 指示: ラジオ台本の修正

aggregate-radio-reviews が生成した findings に基づいて、現在の台本を修正してください。

## 手順

### Step 1: findings を優先度順に消化
- priority: high → 必ず修正
- priority: medium → 6名中3名以上が指摘していれば修正、それ以外は判断
- priority: low → 余裕があれば修正

### Step 2: 矛盾する指摘の調整
- 例: 「もっと笑い増やせ」（野沢）vs「余韻を大事に」（村上） が衝突する場合、番組ジャンル・想定リスナーから判断して片方を採用する
- 採用しない指摘は polish_notes に「{name}の指摘を見送り（理由）」と記載

### Step 3: 修正版を生成
- セリフ・構成・コーナー名・タイトル・エンディングまで含めて修正
- 元の台本の良い部分を破壊しないよう注意（過修正は減点要素）
- 1分≒300文字の尺感を維持

### Step 4: 自己評価
- 何を修正したか、何を見送ったか、なぜそう判断したかを polish_notes に記載

## 出力フォーマット（厳守）

## Polish Result
- polish_iteration: {何回目の polish か}
- findings_addressed: {対応した finding 数}
- findings_skipped: {見送った finding 数}

## Polish Notes
- {変更点1}: {何を、なぜ}
- {変更点2}: ...
- skipped: {見送った指摘と理由}

## Full Script
{修正後の完全な台本を貼り付け（コーナー名・セリフ・演出指示・エンディングまで全て）}
