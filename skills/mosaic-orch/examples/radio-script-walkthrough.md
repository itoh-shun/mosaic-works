# Radio Script Workflow — ウォークスルー

## 概要

`radio-script` workflow は、お題からラジオ台本を5段階で生成する:

1. **plan** (task) — お題をコーナー構成に分解
2. **draft** (fan_out) — 各コーナーを並列に台本化
3. **assemble** (fan_in) — 全コーナーを1つの番組台本に統合
4. **review** (task) — clarity/humor/pace/accuracy の4軸で多角レビュー
5. **polish** (task, conditional loop) — A未満なら修正+自己採点、A以上まで最大3回

## 使い方

```
/mosaic-orch radio-script 4月の桜と花見文化について
```

## Dry-run

```
/mosaic-orch radio-script --dry-run テスト
```

生成されるファイル:
- `.mosaic-orch/runs/DRYRUN-{timestamp}-radio-script/stages/*/prompt.md`

## 期待される動作

### Stage: plan
- Persona: radio-planner
- Knowledge: broadcast-format
- Output: 3〜5個の Corner 定義（corner-plan contract）

### Stage: draft (fan_out)
- plan の corners 配列の長さ分だけ並列実行
- 各コーナーに radio-writer persona + tone-casual policy
- Output: 各コーナーの台本（corner-draft contract）

### Stage: assemble (fan_in)
- draft の全出力を "## 統合対象" として統合
- editor persona が1つの番組台本に仕上げる
- Output: 完成台本（full-script contract）

### Stage: review
- reviewer persona + 4 rubrics
- Output: grade + evidence + suggestions（review-verdict contract）

### Stage: polish (conditional)
- review の grade が A 未満のときのみ実行
- 修正 + 自己採点を最大3回ループ
- Output: 修正台本 + 自己採点（polished-verdict contract）

## SoC の確認ポイント

- 各 Stage は独立したサブエージェントで実行される（コンテキスト分離）
- Rubric は review と polish で再利用される（facet の合成可能性）
- Policy（tone-casual）は draft にだけ注入される（Stageごとのfacet選択）
- 各 contract が Stage 境界を型で守っている
