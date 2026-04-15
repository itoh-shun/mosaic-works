---
name: collect-news
description: ラジオ台本素材としてニュース・トレンドをWebSearchで収集する指示
---

# 指示: ニュース・素材収集

与えられた Topic に関連するニュース・出来事・トレンドを WebSearch で収集し、ラジオ台本の素材となる候補を整理してください。

## 手順

### Step 1: Topic 解析
- Topic から想定読者・想定番組ジャンル（テック／カルチャー／時事／芸能）を推定する
- 検索キーワードを 3〜6 個生成する

### Step 2: WebSearch 実行
- WebSearch ツールで各キーワードを実行する（並列可、最大 5 クエリ）
- 各結果の上位 3 件のタイトル・要約・URL を控える

### Step 3: 素材選定
- 5〜8 個の素材候補に絞り込む
- 各素材について以下を1〜3行で整理:
  - 素材名（1行）
  - 概要（1〜2行）
  - ラジオでの料理ポイント（笑いに繋がる角度／驚き／共感／対立）
  - URL（出典）

### Step 4: 過去ネタとの重複チェック（ベストエフォート）
- もし `~/.mosaic-orch/runs/*-radio-writer/` の過去 run があれば、Glob で簡単に確認し、同一素材を除外する
- 過去 run がなければスキップする

## 出力フォーマット（厳守）

## Topic Analysis
- topic: {元Topic}
- assumed_genre: {推定番組ジャンル}
- target_audience: {想定リスナー像}

## Search Queries
- query_1: {キーワード}
- query_2: ...

## Selected Material
### Material 1
- name: {素材名}
- summary: {1〜2行}
- radio_angle: {ラジオでの料理ポイント}
- source_url: {URL}

### Material 2
...

## Notes
- excluded_due_to_duplication: {過去runとの重複で除外した素材があれば}
- additional_research_needed: {追加調査が必要な点があれば}
