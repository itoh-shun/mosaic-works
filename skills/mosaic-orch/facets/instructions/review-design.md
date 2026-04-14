---
name: review-design
description: 5軸AI設計レビュー（完全性/ファイル設計/スコープ/実現可能性/依存整合性）
---

# 指示: 設計レビュー

design stage の出力を5つの観点からレビューし、品質不足の場合は差し戻してください。

## 情報の優先順位

| 優先度 | ソース |
|--------|--------|
| 最優先 | タスク指示書（workflow.inputs.task） |
| 次点 | design stage の出力 |
| 参考 | 実際のソースコード |

## レビュー手順

### 準備: タスク指示書の要件抽出

タスク指示書を読み、要件を個別に列挙する。曖昧な要件は「ユーザーが当然期待する動作」として具体化する。

### 軸1: 完全性（Completeness）

**チェック内容**: 抽出した全要件が acceptance_criteria に反映されているか。

1. タスク指示書の各要件を acceptance_criteria と照合する
2. 1件でも未反映の要件があれば NEEDS_REVISION
3. acceptance_criteria が「適切に動作する」のような曖昧な記述のみの場合も NEEDS_REVISION

### 軸2: ファイル設計（File Design）

**チェック内容**: file_structure が健全か。

1. 各ファイルが 1 モジュール 1 責務を守っているか
2. 既存ファイルの変更が妥当か（実際にファイルを Read して確認）
3. 新規ファイルのパスが既存のディレクトリ構造規約に沿っているか
4. 200-400行で収まる設計か（巨大ファイルの計画がないか）

### 軸3: スコープ（Scope）

**チェック内容**: scope_boundaries が適切か。

1. in_scope がタスク指示書の範囲内か（指示外の改善が含まれていないか）
2. out_of_scope が明示されているか
3. deletion_policy が明確か
4. file_structure に in_scope 外のファイル変更が含まれていないか

### 軸4: 実現可能性（Feasibility）

**チェック内容**: implementation_guidelines が具体的で技術的に正しいか。

1. 使用ライブラリが package.json / build.gradle に存在するか（または追加計画があるか）
2. 技術選定に矛盾がないか
3. ガイドラインが「適切に実装する」のような抽象的な記述でないか
4. エラーハンドリング・データフローの方針が示されているか

### 軸5: 依存整合性（Dependencies）

**チェック内容**: file_structure の依存方向が正しいか。

1. 上位層 → 下位層の依存方向が守られているか
2. 循環依存がないか
3. FE → BE の依存がある場合、Wave 分割で対応可能か

## 重要な制約

- **あなたの出力はレビューレポートのみ。** ファイルの作成・変更は行わないこと
- NEEDS_REVISION の場合、具体的な修正指示を findings に含めること
- APPROVE のハードルを下げないこと。「概ね良い」は APPROVE の根拠にならない

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

## Design Review
- verdict: APPROVE | NEEDS_REVISION
- score: {S|A+|A|B|C}

## Axes
- completeness: {grade} — {根拠の要約}
- file_design: {grade} — {根拠の要約}
- scope: {grade} — {根拠の要約}
- feasibility: {grade} — {根拠の要約}
- dependencies: {grade} — {根拠の要約}

## Findings
### Finding 1
- finding_id: DR-{axis}-{number}
- axis: completeness | file_design | scope | feasibility | dependencies
- severity: critical | important | suggestion
- detail: {具体的な指摘}
- recommendation: {修正の方向性}

（finding がない場合は「なし」と記載）
