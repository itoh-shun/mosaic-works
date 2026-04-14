# Planning Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevate mosaic-orch's planning capability to TAKT-parity by rewriting design/plan instructions+contracts and adding AI design-review and plan-review stages.

**Architecture:** Rewrite 4 existing files (design-spec.md, design-result.md, plan-tasks.md, plan-result.md) with TAKT-quality depth, create 4 new files (review-design.md, design-review-result.md, review-plan.md, plan-review-result.md), and update dev-orchestration.yaml from 15 to 17 stages with two new loop monitors.

**Tech Stack:** Markdown instructions, Markdown output contracts, YAML workflow definitions

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Rewrite | `facets/instructions/design-spec.md` | Enhanced design instruction with file-level planning, scope discipline, implementation guidelines |
| Rewrite | `contracts/design-result.md` | Enhanced contract with file_structure, design_patterns, scope_boundaries, acceptance_criteria |
| Create | `facets/instructions/review-design.md` | 5-axis AI design review instruction |
| Create | `contracts/design-review-result.md` | Design review verdict + findings with finding_id |
| Rewrite | `facets/instructions/plan-tasks.md` | Enhanced plan instruction with per-subtask file assignments, testing strategy |
| Rewrite | `contracts/plan-result.md` | Enhanced contract with files_create, files_modify, testing_strategy, acceptance_criteria |
| Create | `facets/instructions/review-plan.md` | 4-axis plan review instruction (supervisor-like) |
| Create | `contracts/plan-review-result.md` | Plan review verdict + requirements traceability |
| Modify | `workflows/dev-orchestration.yaml` | 15→17 stages, 2 new loop monitors |

---

### Task 1: Rewrite design-spec instruction + design-result contract

**Files:**
- Rewrite: `facets/instructions/design-spec.md`
- Rewrite: `contracts/design-result.md`

- [ ] **Step 1: Rewrite design-spec.md**

Write the complete file:

```markdown
---
name: design-spec
description: コードベース診断、要件分析、ファイルレベル設計、スコープ規律、実装ガイドラインの指示
---

# 指示: 設計仕様

与えられたタスクに対して、コードベース診断・要件分析・ファイルレベルのアーキテクチャ設計を行ってください。

## 情報の優先順位（厳守）

| 優先度 | ソース |
|--------|--------|
| 最優先 | タスク指示書・参照資料 |
| 次点 | 実際のソースコード（現在の実装） |
| 参考 | その他のドキュメント |

**推測禁止**: 名前・値・振る舞いは必ずコードで確認する。「不明」で止まらず、ツールで調査して解決する。

## 手順

### Step 0: 既存コードベース診断（実施必須）

タスクの分析に入る前に、プロジェクトの現状を診断してください。以下をツールで調査し、結果を分析に活かすこと:

1. **プロジェクト構造**: `ls`, `Glob` で主要ディレクトリとファイル構造を把握する
2. **パッケージ構成**: `package.json`, `build.gradle`, `pom.xml` 等を読み、使用フレームワーク・ライブラリを特定する
3. **既存テストパターン**: テストファイルを `Glob("**/*.test.*", "**/*.spec.*", "**/test/**")` で探し、テストフレームワーク・テスト構造を把握する
4. **既存API規約**: ルーティング定義やコントローラを探し、命名規約・レスポンス形式を把握する（該当する場合のみ）
5. **ディレクトリ命名規約**: 既存の命名パターン（camelCase / kebab-case / PascalCase）を確認する

**重要**: 診断結果は全て実際のファイル読み取りに基づくこと。記憶や推測に頼らない。

### Step 1: 要件分析

以下の項目を分析してください:
1. **影響レイヤー**: FE / BE / 両方 / 非エンジニアリング
2. **タスク種別**: 新機能 / バグ修正 / リファクタリング / テスト / ドキュメント / コンテンツ
3. **スコープ**: 変更の範囲と影響を受けるコンポーネント
4. **制約事項**: パフォーマンス要件、互換性要件、技術的制約

### Step 2: ファイル構成設計

**全ての変更対象ファイルを列挙する。** 1モジュール1責務、200-400行目安。

1. 新規作成するファイルとその責務を決定する
2. 変更する既存ファイルとその変更範囲を特定する
3. 既存ファイルに構造上の問題があれば、タスクスコープ内でのリファクタリングを含める
4. **1ファイルが1つの責務のみを持つこと**を確認する

### Step 3: 設計パターン決定

1. 採用する設計パターンとその適用箇所を決定する
2. 既存パターンとの整合性を確認する
3. 新規パターン導入の場合、その理由を明記する

### Step 4: 実装ガイドライン策定

後続の implement stage が設計判断に迷わないための具体指針を策定する:
- 使用するライブラリとその使い方
- エラーハンドリングの方針
- データフローの方針
- 命名規約の方針

### Step 5: スコープ規律の確認

**タスク指示書に明記された作業のみを計画する。暗黙の「改善」を含めない。**

- in_scope: タスクに必要な作業のみ
- out_of_scope: 関連するが今回は対象外の作業を明示する
- deletion_policy: 今回の変更で新たに未使用になったコードのみ削除可。既存機能は明示的指示がない限り削除しない

### Step 6: 受入基準の定義

タスクの完了を判定するための具体的なチェックリストを作成する:
- 各基準は検証可能（実行して確認できる）であること
- 曖昧な基準（「適切に動作する」等）は不可
- 後続の plan-review stage がこの基準を使って要件×計画の照合を行う

## 重要な制約

- **あなたの出力は設計レポートのみ。** ファイルの作成・変更・コーディングは一切行わないこと
- 実装の詳細（具体的なコード）は後続の implement stage が担当する
- 以下の出力フォーマット以外の出力は却下される（Output Contract で検証される）

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

以下の形式で**のみ**出力してください:

## Codebase Context
- framework: {使用フレームワーク名とバージョン}
- test_framework: {テストフレームワーク名、未導入なら "none"}
- directory_convention: {既存の命名規約}
- api_convention: {API命名規約、該当なしなら "N/A"}
- notable_patterns: {特筆すべき既存パターン}

## Requirements
- impact_layer: FE | BE | both | non-engineering
- task_type: feature | bugfix | refactor | test | docs | content
- has_fe: true | false
- scope: {変更スコープの要約}
- constraints: {制約事項のリスト}

## Architecture
- approach: {設計アプローチの要約}
- pattern_reuse: true | false
- risks: {リスクと軽減策}
- dependencies: {依存関係の整理}

## File Structure
| Action | Path | Responsibility |
|--------|------|----------------|
| create | {ファイルパス} | {責務の1行説明} |
| modify | {ファイルパス} | {変更内容の1行説明} |

## Design Patterns
- pattern: {パターン名}
  apply_to: {適用箇所}
  reason: {採用理由}

## Implementation Guidelines
- {ガイドライン1}
- {ガイドライン2}

## Scope Boundaries
- in_scope: {対象作業のリスト}
- out_of_scope: {対象外作業のリスト}
- deletion_policy: {削除方針}

## Acceptance Criteria
- [ ] {検証可能な基準1}
- [ ] {検証可能な基準2}

## Open Questions
- {不明点1}（あれば。なければ「なし」）
```

- [ ] **Step 2: Rewrite design-result.md**

Write the complete file:

```markdown
---
name: design-result
description: 設計仕様の出力契約（ファイル構成・スコープ規律・受入基準を含む）
---

# Output Contract: design-result

## 期待形式
"## Codebase Context" にプロジェクト診断結果、"## Requirements" に要件分析、"## Architecture" にアーキテクチャ設計、"## File Structure" にファイル構成テーブル、"## Design Patterns" に設計パターン、"## Implementation Guidelines" に実装指針、"## Scope Boundaries" にスコープ規律、"## Acceptance Criteria" に受入基準。

## パース規則（エンジンが抽出）
- codebase_context: "## Codebase Context" セクション全体のテキスト（後続 stage への参照用）
- impact_layer: "## Requirements" セクション内の "- impact_layer:" 直後のテキスト。正規表現 /^(FE|BE|both|non-engineering)$/
- task_type: "- task_type:" 直後のテキスト。正規表現 /^(feature|bugfix|refactor|test|docs|content)$/
- has_fe: "- has_fe:" 直後のテキスト。正規表現 /^(true|false)$/
- scope: "- scope:" 直後のテキスト
- constraints: "- constraints:" 直後のテキスト
- approach: "## Architecture" セクション内の "- approach:" 直後のテキスト
- pattern_reuse: "- pattern_reuse:" 直後のテキスト。正規表現 /^(true|false)$/
- risks: "- risks:" 直後のテキスト
- dependencies: "- dependencies:" 直後のテキスト
- file_structure: "## File Structure" セクション内のテーブル行をパース。各行から:
  - action: 第1カラム（create | modify）
  - path: 第2カラム（ファイルパス）
  - responsibility: 第3カラム（責務説明）
- design_patterns: "## Design Patterns" セクション内の "- pattern:" で始まるブロックを配列化。各ブロックから:
  - pattern: "- pattern:" 直後のテキスト
  - apply_to: "apply_to:" 直後のテキスト
  - reason: "reason:" 直後のテキスト
- implementation_guidelines: "## Implementation Guidelines" セクション全体のテキスト
- scope_boundaries: "## Scope Boundaries" セクション内から:
  - in_scope: "- in_scope:" 直後のテキスト
  - out_of_scope: "- out_of_scope:" 直後のテキスト
  - deletion_policy: "- deletion_policy:" 直後のテキスト
- acceptance_criteria: "## Acceptance Criteria" セクション内の "- [ ]" で始まる各行を配列化
- open_questions: "## Open Questions" セクション内の "- " で始まる各行を配列化（「なし」のみの場合は空配列）

## 検証項目
- codebase_context が空でないこと（必須）
- impact_layer が "FE", "BE", "both", "non-engineering" のいずれかであること（必須）
- task_type が "feature", "bugfix", "refactor", "test", "docs", "content" のいずれかであること（必須）
- has_fe が "true" または "false" であること（必須）
- scope が空でないこと（必須）
- approach が空でないこと（必須）
- file_structure の件数が 1 以上であること（必須）
- implementation_guidelines が空でないこと（必須）
- scope_boundaries の in_scope が空でないこと（必須）
- acceptance_criteria の件数が 1 以上であること（必須）
```

- [ ] **Step 3: Verify frontmatter**

Run: `head -3 facets/instructions/design-spec.md && echo "---" && head -3 contracts/design-result.md`
Expected: Correct name/description in both files

- [ ] **Step 4: Commit**

```bash
git add facets/instructions/design-spec.md contracts/design-result.md
git commit -m "feat(mosaic-orch): rewrite design stage — file-level planning, scope discipline, acceptance criteria"
```

---

### Task 2: Create design-review instruction + contract

**Files:**
- Create: `facets/instructions/review-design.md`
- Create: `contracts/design-review-result.md`

- [ ] **Step 1: Create review-design.md**

Write the complete file:

```markdown
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
```

- [ ] **Step 2: Create design-review-result.md**

Write the complete file:

```markdown
---
name: design-review-result
description: AI設計レビューの判定契約（verdict + 5軸評価 + findings）
---

# Output Contract: design-review-result

## 期待形式
"## Design Review" 見出しの下に verdict と score。"## Axes" に5軸の個別評価。"## Findings" に指摘事項。

## パース規則（エンジンが抽出）
- verdict: "## Design Review" セクション内の "- verdict:" 直後のテキスト。正規表現 /^(APPROVE|NEEDS_REVISION)$/
- score: "- score:" 直後のテキスト。正規表現 /^(S|A\+|A|B|C)$/
- axes: "## Axes" セクション内の各行を解析:
  - completeness: "- completeness:" 直後の最初の単語、正規表現 /^(S|A\+|A|B|C)/
  - file_design: "- file_design:" 直後の最初の単語
  - scope: "- scope:" 直後の最初の単語
  - feasibility: "- feasibility:" 直後の最初の単語
  - dependencies: "- dependencies:" 直後の最初の単語
- findings: "## Findings" セクション内の "### Finding" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - finding_id: "- finding_id:" 直後のテキスト
  - axis: "- axis:" 直後のテキスト
  - severity: "- severity:" 直後のテキスト。正規表現 /^(critical|important|suggestion)$/
  - detail: "- detail:" 直後のテキスト
  - recommendation: "- recommendation:" 直後のテキスト
  「なし」のみの場合は空配列

## 検証項目
- verdict が "APPROVE" または "NEEDS_REVISION" であること（必須）
- score が S/A+/A/B/C のいずれかであること（必須）
- axes の5軸すべてが存在し、正規表現にマッチすること（必須）
- verdict が "NEEDS_REVISION" の場合、findings の件数が 1 以上であること（必須）
- findings の各 finding に severity が critical/important/suggestion のいずれかであること
```

- [ ] **Step 3: Commit**

```bash
git add facets/instructions/review-design.md contracts/design-review-result.md
git commit -m "feat(mosaic-orch): add 5-axis AI design review stage"
```

---

### Task 3: Rewrite plan-tasks instruction + plan-result contract

**Files:**
- Rewrite: `facets/instructions/plan-tasks.md`
- Rewrite: `contracts/plan-result.md`

- [ ] **Step 1: Rewrite plan-tasks.md**

Write the complete file:

```markdown
---
name: plan-tasks
description: 設計仕様に基づくサブタスク分解、ファイル割り当て、テスト戦略、受入基準分配の指示
---

# 指示: タスク計画

承認済みの設計仕様に基づき、サブタスク分解・担当者選定・ファイル割り当て・テスト戦略・Wave振り分けを行ってください。

## 入力

- **タスク指示書** (workflow.inputs.task): ユーザーの元の要求
- **設計仕様** (design stage出力): コードベースコンテキスト、ファイル構成、設計パターン、実装ガイドライン、スコープ規律、受入基準

## 手順

### Step 1: サブタスク分解判定

設計仕様の要件・アーキテクチャに基づき、分解方式を決定する:

| 条件 | 分解方式 | 実行方式 |
|---|---|---|
| 単一レイヤー・単一関心事 | 分解しない | 1メンバー（fan_out要素数1） |
| BE+FE横断・相互依存なし | 並列分解 | Wave1で並列 |
| BE+FE横断・FEがBEに依存 | Wave分解 | Wave1: BE → Wave2: FE |
| 混合（独立+依存が混在） | Wave分解 | Wave1: 独立タスク並列 → Wave2: 依存タスク |

### Step 2: persona/instruction 選定

各サブタスクの種別に応じて以下のテーブルから選定する:

| タスク種別 | persona | instruction |
|---|---|---|
| BE新機能・修正 | backend-lead | implement-backend |
| BE複雑ドメイン | backend-domain | implement-backend |
| FE新機能・修正 | frontend-lead | implement-frontend |
| FEコンポーネント | frontend-component | implement-frontend |
| 設計判断が必要 | architect | implement-general |
| テスト追加 | tester | implement-general |
| E2Eテスト | e2e-tester | implement-e2e |
| コンテンツ制作 | content-creator | implement-general |

### Step 3: ファイル割り当て

design stage の File Structure テーブルを参照し、各サブタスクにファイルを割り当てる。

**制約:**
- **1ファイルが複数サブタスクにまたがらない**（衝突防止）
- File Structure に含まれないファイルを割り当てない（スコープクリープ防止）
- 全ての File Structure エントリがいずれかのサブタスクに割り当てられること

### Step 4: スキル選定

Knowledge の skill-catalog を参照し、各サブタスクに必要なスキル名を2〜4個選定する。
ユーザーの環境にインストール済みのスキルのみ選定すること（skill-catalog に載っているものが対象）。

### Step 4.5: MCP検出と割り当て

Knowledge の mcp-catalog を参照し、利用可能なMCPツールを検出する:
1. ToolSearch で `"mcp__"` を検索し、利用可能なMCPプレフィックスを特定する
2. 各サブタスクに適切なMCPを割り当てる（0〜2個）
3. MCP未検出の場合は割り当てない（mcpsフィールドを省略）

### Step 5: テスト戦略の策定

各サブタスクに対して、**何をどうテストするか**を具体的に定義する:
- ユニットテスト: どのモジュール/関数をテストするか
- 統合テスト: どのAPIエンドポイント/フローをテストするか
- 「テストを書く」ではなく「何をどうテストするか」を記述する

### Step 6: 受入基準の分配

design stage の Acceptance Criteria を各サブタスクに分配する。

**制約:**
- **全ての Acceptance Criteria がいずれかのサブタスクにマッピングされること**（漏れ防止）
- 1つの criteria が複数サブタスクに割り当てられてもよい（共同責任の場合）

### Step 7: FEサブタスクのデザイン要件定義（has_fe=trueの場合）

FE サブタスクがある場合、**Wave 2 の最初のサブタスク**（FE基盤構築）に以下を含める:
- CSS変数によるデザイントークン定義（色、スペーシング、フォント）
- `prefers-color-scheme: dark` 対応のダークモードトークン
- モバイルブレークポイント定義（375px / 768px）
- サイドバーのモバイル対応方針（非表示 or ハンバーガー）

### Step 8: Wave振り分け + 複雑度見積もり

- 依存関係のないサブタスクを Wave 1 にまとめる
- 依存関係のあるサブタスクを Wave 2 に配置する
- Wave 2 が不要な場合は has_wave2: false とする
- 各サブタスクに estimated_complexity (small/medium/large) を付与する

## 重要な制約

- **あなたの出力は計画レポートのみ。** ファイルの作成・変更・コーディングは一切行わないこと
- 設計仕様で承認された方針に従うこと。設計を変更する場合はその理由を明記すること
- design stage の File Structure に含まれないファイルを計画に含めない
- 以下の出力フォーマット以外の出力は却下される（Output Contract で検証される）

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

以下の形式で**のみ**出力してください:

## Analysis
- mode: parallel | wave
- has_wave2: true | false
- has_fe: true | false

## Wave 1 Subtasks
### Subtask 1
- persona: {persona名}
- instruction: {instruction名}
- description: {サブタスク内容の1行説明}
- files_create: [{新規作成ファイルパス}]
- files_modify: [{変更ファイルパス}]
- skills: [{スキル名1}, {スキル名2}]
- mcps: [{MCP名: 説明}]（利用可能なMCPがある場合のみ）
- testing_strategy: {何をどうテストするか}
- acceptance_criteria: [{この subtask が担う受入基準}]
- estimated_complexity: small | medium | large

### Subtask 2
...

## Wave 2 Subtasks
### Subtask 1
...

## Criteria Coverage
| # | Acceptance Criteria | Subtask | Status |
|---|-------------------|---------|--------|
| 1 | {基準1} | Wave1-Subtask1 | covered |
| 2 | {基準2} | Wave2-Subtask1 | covered |
```

- [ ] **Step 2: Rewrite plan-result.md**

Write the complete file:

```markdown
---
name: plan-result
description: タスク計画の出力契約（ファイル割り当て・テスト戦略・受入基準を含む）
---

# Output Contract: plan-result

## 期待形式
"## Analysis" 見出しの下にモード情報、"## Wave 1 Subtasks" と "## Wave 2 Subtasks" にサブタスク一覧、"## Criteria Coverage" に受入基準カバレッジテーブル。

## パース規則（エンジンが抽出）
- mode: "## Analysis" セクション内の "- mode:" 直後のテキスト。正規表現 /^(parallel|wave)$/
- has_wave2: "- has_wave2:" 直後のテキスト。正規表現 /^(true|false)$/
- has_fe: "- has_fe:" 直後のテキスト。正規表現 /^(true|false)$/
- wave1_subtasks: "## Wave 1 Subtasks" セクション内の "### Subtask" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - persona: "- persona:" 直後のテキスト
  - instruction: "- instruction:" 直後のテキスト
  - description: "- description:" 直後のテキスト
  - files_create: "- files_create:" 直後のテキスト（配列として解析）
  - files_modify: "- files_modify:" 直後のテキスト（配列として解析）
  - skills: "- skills:" 直後のテキスト（配列として解析）
  - mcps: "- mcps:" 直後のテキスト（配列として解析、空の場合は空配列）
  - testing_strategy: "- testing_strategy:" 直後のテキスト
  - acceptance_criteria: "- acceptance_criteria:" 直後のテキスト（配列として解析）
  - estimated_complexity: "- estimated_complexity:" 直後のテキスト。正規表現 /^(small|medium|large)$/
- wave2_subtasks: "## Wave 2 Subtasks" セクション内を同様に解析。セクションがない場合は空配列
- criteria_coverage: "## Criteria Coverage" セクション全体のテキスト

## 検証項目
- mode が "parallel" または "wave" であること（必須）
- has_wave2 が "true" または "false" であること（必須）
- has_fe が "true" または "false" であること（必須）
- wave1_subtasks の件数が 1 以上であること（必須）
- 各 subtask に persona が空でないこと（必須）
- 各 subtask に instruction が空でないこと（必須）
- 各 subtask に files_create または files_modify が 1 件以上あること（必須）
- 各 subtask に testing_strategy が空でないこと（必須）
- 各 subtask に estimated_complexity が small/medium/large のいずれかであること（必須）
- has_wave2 が true の場合、wave2_subtasks の件数が 1 以上であること（必須）
- criteria_coverage が空でないこと（必須）
```

- [ ] **Step 3: Commit**

```bash
git add facets/instructions/plan-tasks.md contracts/plan-result.md
git commit -m "feat(mosaic-orch): rewrite plan stage — per-subtask file assignments, testing strategy, acceptance criteria"
```

---

### Task 4: Create plan-review instruction + contract

**Files:**
- Create: `facets/instructions/review-plan.md`
- Create: `contracts/plan-review-result.md`

- [ ] **Step 1: Create review-plan.md**

Write the complete file:

```markdown
---
name: review-plan
description: 4軸計画検証（要件カバレッジ/ファイル衝突/スコープクリープ/Wave依存整合）
---

# 指示: 計画レビュー

plan stage の出力を design stage の設計仕様と照合し、計画の妥当性を検証してください。

## 役割

あなたは最終検証者です。「正しいものを作る計画になっているか」を検証します。
- 計画の承認ハードルを下げないこと
- 「概ね良い」は APPROVE の根拠にならない
- NEEDS_REVISION の場合、具体的な修正指示を含めること

## レビュー手順

### 軸1: 要件カバレッジ（Requirements Coverage）

design stage の Acceptance Criteria が全て plan の subtask に割り当てられているかを照合する。

1. design.output.acceptance_criteria の各項目を列挙する
2. plan の Criteria Coverage テーブルと照合する
3. **未割り当て（UNCOVERED）の criteria が 1 件でもあれば NEEDS_REVISION**
4. 各 criteria の subtask マッピングが妥当か確認する

### 軸2: ファイル衝突（File Conflicts）

同一ファイルが複数 subtask に割り当てられていないかを検証する。

1. 全 subtask の files_create と files_modify を収集する
2. ファイルパスの重複を検出する
3. **衝突が 1 件でもあれば NEEDS_REVISION**

### 軸3: スコープクリープ（Scope Creep）

subtask のファイル割り当てが design の File Structure の範囲内かを検証する。

1. 全 subtask の files_create と files_modify を収集する
2. design.output.file_structure のパス一覧と照合する
3. **design にないファイルが計画に含まれていれば NEEDS_REVISION**
4. 例外: テストファイル（*.test.*, *.spec.*）は File Structure に明記されていなくても許容する

### 軸4: Wave依存整合（Wave Dependencies）

Wave2 subtask が Wave1 の成果物に正しく依存しているかを検証する。

1. Wave2 subtask の files_modify が Wave1 subtask の files_create に含まれるファイルを参照していないか確認する（Wave1 がまだ作成していないファイルに依存していないか）
2. Wave1 subtask 間で暗黙の依存関係がないか確認する（並列実行可能か）
3. **Wave 順序の矛盾が 1 件でもあれば NEEDS_REVISION**

## 重要な制約

- **あなたの出力はレビューレポートのみ。** ファイルの作成・変更は行わないこと
- 実際のソースコードを Read して検証に使ってよい（ファイル存在確認等）

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

## Plan Review
- verdict: APPROVE | NEEDS_REVISION
- criteria_coverage: {covered}/{total} ({percentage}%)

## Requirements Traceability
| # | Acceptance Criteria | Subtask | Status |
|---|-------------------|---------|--------|
| 1 | {基準} | {Wave-Subtask} | covered | UNCOVERED |

## File Conflict Check
- conflicts_found: true | false
- conflicts: [{file}: {subtask1, subtask2}]（衝突がない場合は「なし」）

## Scope Check
- unplanned_files_found: true | false
- unplanned_files: [{file}: {subtask}, reason: {理由}]（なければ「なし」）

## Wave Dependency Check
- dependency_issues_found: true | false
- dependency_issues: [{issue}]（なければ「なし」）

## Findings
### Finding 1
- finding_id: PR-{axis}-{number}
- axis: coverage | conflict | scope | dependency
- severity: critical | important
- detail: {具体的な指摘}
- recommendation: {修正の方向性}

（finding がない場合は「なし」と記載）
```

- [ ] **Step 2: Create plan-review-result.md**

Write the complete file:

```markdown
---
name: plan-review-result
description: 計画検証の判定契約（verdict + 要件追跡 + 衝突検出 + スコープチェック）
---

# Output Contract: plan-review-result

## 期待形式
"## Plan Review" 見出しの下に verdict と criteria_coverage。"## Requirements Traceability" に要件追跡テーブル。"## File Conflict Check" にファイル衝突結果。"## Scope Check" にスコープチェック結果。"## Wave Dependency Check" にWave依存チェック結果。"## Findings" に指摘事項。

## パース規則（エンジンが抽出）
- verdict: "## Plan Review" セクション内の "- verdict:" 直後のテキスト。正規表現 /^(APPROVE|NEEDS_REVISION)$/
- criteria_coverage: "- criteria_coverage:" 直後のテキスト
- conflicts_found: "## File Conflict Check" セクション内の "- conflicts_found:" 直後のテキスト。正規表現 /^(true|false)$/
- unplanned_files_found: "## Scope Check" セクション内の "- unplanned_files_found:" 直後のテキスト。正規表現 /^(true|false)$/
- dependency_issues_found: "## Wave Dependency Check" セクション内の "- dependency_issues_found:" 直後のテキスト。正規表現 /^(true|false)$/
- findings: "## Findings" セクション内の "### Finding" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - finding_id: "- finding_id:" 直後のテキスト
  - axis: "- axis:" 直後のテキスト
  - severity: "- severity:" 直後のテキスト。正規表現 /^(critical|important)$/
  - detail: "- detail:" 直後のテキスト
  - recommendation: "- recommendation:" 直後のテキスト
  「なし」のみの場合は空配列

## 検証項目
- verdict が "APPROVE" または "NEEDS_REVISION" であること（必須）
- criteria_coverage が空でないこと（必須）
- conflicts_found が "true" または "false" であること（必須）
- unplanned_files_found が "true" または "false" であること（必須）
- dependency_issues_found が "true" または "false" であること（必須）
- verdict が "NEEDS_REVISION" の場合、findings の件数が 1 以上であること（必須）
```

- [ ] **Step 3: Commit**

```bash
git add facets/instructions/review-plan.md contracts/plan-review-result.md
git commit -m "feat(mosaic-orch): add 4-axis plan review stage (supervisor-like validation)"
```

---

### Task 5: Update dev-orchestration.yaml (15→17 stages)

**Files:**
- Modify: `workflows/dev-orchestration.yaml`

- [ ] **Step 1: Read current YAML**

Read `workflows/dev-orchestration.yaml` to confirm current state.

- [ ] **Step 2: Write the complete updated YAML**

The new workflow inserts design-review (after design) and plan-review (after plan), adds 2 loop monitors, and updates the plan stage input to include design-review output awareness. Full YAML:

```yaml
name: dev-orchestration
version: "1"
description: 開発タスクを設計・計画・チーム分解・並列実装・5軸レビューで品質担保して納品する

inputs:
  - name: task
    type: string
    required: true

defaults:
  permission: acceptEdits

loop_monitors:
  - cycle: [design, design-review]
    threshold: 2
    judge:
      persona: architect
      instruction: |
        design → design-review のサイクルが {cycle_count} 回繰り返されました。
        設計が収束しているか判断してください。
        品質が着実に向上しているなら「PRODUCTIVE」、同じ指摘が繰り返されているなら「UNPRODUCTIVE」と回答してください。
      decisions:
        - contains: "PRODUCTIVE"
          goto: design
        - contains: "UNPRODUCTIVE"
          goto: plan
  - cycle: [plan, plan-review]
    threshold: 2
    judge:
      persona: architect
      instruction: |
        plan → plan-review のサイクルが {cycle_count} 回繰り返されました。
        計画が収束しているか判断してください。
        品質が着実に向上しているなら「PRODUCTIVE」、同じ指摘が繰り返されているなら「UNPRODUCTIVE」と回答してください。
      decisions:
        - contains: "PRODUCTIVE"
          goto: plan
        - contains: "UNPRODUCTIVE"
          goto: check-dup
  - cycle: [review, fix]
    threshold: 2
    judge:
      persona: architect
      instruction: |
        review → fix のサイクルが {cycle_count} 回繰り返されました。
        直近のレビュー指摘と修正内容を確認し、このループが生産的かどうか判断してください。
        品質が着実に向上しているなら「PRODUCTIVE」、同じ指摘が繰り返されているなら「UNPRODUCTIVE」と回答してください。
      decisions:
        - contains: "PRODUCTIVE"
          goto: review
        - contains: "UNPRODUCTIVE"
          goto: save-results

stages:
  # Stage 1: 設計仕様 — コードベース診断 + ファイルレベル設計 + スコープ規律 + 受入基準
  - id: design
    kind: task
    gate: approval
    facets:
      persona: architect
      knowledge: [team-roster, skill-catalog, mcp-catalog]
      instructions: [design-spec]
    input: ${workflow.inputs.task}
    output_contract: design-result
    permission: default

  # Stage 2: AI設計レビュー — 5軸検証（完全性/ファイル設計/スコープ/実現可能性/依存整合性）
  - id: design-review
    kind: task
    facets:
      persona: architect
      instructions: [review-design]
    input: |
      Task: ${workflow.inputs.task}
      Design: ${design.output}
    output_contract: design-review-result
    permission: default
    next:
      - when: ${design-review.output.verdict} == 'APPROVE'
        goto: plan
      - when: ${design-review.output.verdict} == 'NEEDS_REVISION'
        goto: design

  # Stage 3: タスク計画 — サブタスク分解 + ファイル割り当て + テスト戦略 + 受入基準分配
  - id: plan
    kind: task
    gate: approval
    facets:
      persona: architect
      knowledge: [team-roster, skill-catalog, mcp-catalog]
      instructions: [plan-tasks]
    input: |
      Task: ${workflow.inputs.task}
      Design: ${design.output}
    output_contract: plan-result
    permission: default

  # Stage 4: 計画検証 — 要件カバレッジ + ファイル衝突 + スコープクリープ + Wave依存整合
  - id: plan-review
    kind: task
    facets:
      persona: project-manager
      instructions: [review-plan]
    input: |
      Task: ${workflow.inputs.task}
      Design: ${design.output}
      Plan: ${plan.output}
    output_contract: plan-review-result
    permission: default
    next:
      - when: ${plan-review.output.verdict} == 'APPROVE'
        goto: check-dup
      - when: ${plan-review.output.verdict} == 'NEEDS_REVISION'
        goto: plan

  # Stage 5: 重複チェック
  - id: check-dup
    kind: task
    facets:
      persona: project-manager
      instructions: [check-duplicates]
    input: ${workflow.inputs.task}
    output_contract: duplicate-check

  # Stage 6: Issue + ブランチ作成
  - id: setup-git
    kind: task
    facets:
      persona: project-manager
      policies: [git-conventions]
      instructions: [setup-git-branch]
    input: |
      Task: ${workflow.inputs.task}
      Design: ${design.output}
    output_contract: git-setup

  # Stage 7: Worktree 作成 — 実装用の隔離環境を準備
  - id: setup-worktree
    kind: task
    facets:
      persona: project-manager
      instructions: [setup-worktree]
    input: |
      Branch: ${setup-git.output.branch_name}
      Design: ${design.output}
    output_contract: worktree-setup

  # Stage 8: Wave1 並列実装
  - id: implement-wave1
    kind: fan_out
    from: ${plan.output.wave1_subtasks}
    as: subtask
    facets:
      persona: ${subtask.persona}
      policies: [coding-standards, no-push, tdd]
      knowledge: [error-patterns]
      instructions: [${subtask.instruction}]
    skills: ${subtask.skills}
    mcps: ${subtask.mcps}
    input: |
      Task: ${subtask.description}
      Branch: ${setup-git.output.branch_name}
      Worktree: ${setup-worktree.output.worktree_path}
      Codebase Context: ${design.output.codebase_context}
      Files to Create: ${subtask.files_create}
      Files to Modify: ${subtask.files_modify}
      Testing Strategy: ${subtask.testing_strategy}
      Acceptance Criteria: ${subtask.acceptance_criteria}
      Implementation Guidelines: ${design.output.implementation_guidelines}
    output_contract: implementation-result

  # Stage 9: Wave1 統合
  - id: integrate-wave1
    kind: fan_in
    from: ${implement-wave1.outputs}
    facets:
      persona: integrator
      policies: [coding-standards]
      instructions: [merge-implementations]
    output_contract: integration-result

  # Stage 10: Wave2 並列実装（条件付き）
  - id: implement-wave2
    kind: fan_out
    when: ${plan.output.has_wave2} == 'true'
    from: ${plan.output.wave2_subtasks}
    as: subtask
    facets:
      persona: ${subtask.persona}
      policies: [coding-standards, no-push, tdd]
      knowledge: [error-patterns]
      instructions: [${subtask.instruction}]
    skills: ${subtask.skills}
    mcps: ${subtask.mcps}
    input: |
      Task: ${subtask.description}
      Branch: ${setup-git.output.branch_name}
      Worktree: ${setup-worktree.output.worktree_path}
      Wave1 Result: ${integrate-wave1.output}
      Codebase Context: ${design.output.codebase_context}
      Files to Create: ${subtask.files_create}
      Files to Modify: ${subtask.files_modify}
      Testing Strategy: ${subtask.testing_strategy}
      Acceptance Criteria: ${subtask.acceptance_criteria}
      Implementation Guidelines: ${design.output.implementation_guidelines}
    output_contract: implementation-result

  # Stage 11: Wave2 統合（条件付き）
  - id: integrate-wave2
    kind: fan_in
    when: ${plan.output.has_wave2} == 'true'
    from: ${implement-wave2.outputs}
    facets:
      persona: integrator
      policies: [coding-standards]
      instructions: [merge-implementations]
    output_contract: integration-result

  # Stage 12: 品質ゲート
  - id: quality-gate
    kind: task
    facets:
      persona: qa-engineer
      policies: [tdd]
      instructions: [run-quality-checks]
    input: |
      Design: ${design.output}
      Plan: ${plan.output}
      Implementation: ${integrate-wave1.output}
    output_contract: quality-result

  # Stage 13: 5軸コードレビュー
  - id: review
    kind: task
    facets:
      persona: code-reviewer
      rubrics: [performance, naming, testing, security, design]
      instructions: [code-review-5axis]
    input: |
      Design: ${design.output}
      Plan: ${plan.output}
      Quality Gate: ${quality-gate.output}
    output_contract: dev-review-verdict
    permission: default
    next:
      - when: ${review.output.grade} >= 'A+'
        goto: ui-verify

  # Stage 14: レビュー指摘の修正
  - id: fix
    kind: task
    facets:
      persona: ${plan.output.wave1_subtasks[0].persona}
      policies: [coding-standards, no-push]
      rubrics: [performance, naming, testing, security, design]
      instructions: [apply-fixes-and-self-assess]
    input: |
      Review Result: ${review.output}
    output_contract: fix-verdict
    next:
      - when: ${fix.output.grade} >= 'A+'
        goto: ui-verify
      - when: ${fix.output.grade} < 'A+'
        goto: review

  # Stage 15: UI視覚検証（FE変更時のみ）
  - id: ui-verify
    kind: task
    when: ${plan.output.has_fe} == 'true'
    facets:
      persona: qa-engineer
      instructions: [verify-ui-visual]
    skills: [usability-psychologist, web-design-guidelines, accessibility]
    input: |
      Design: ${design.output}
      検証対象: デスクトップ(light/dark) + モバイル(light/dark) の4パターン
    output_contract: ui-verification

  # Stage 16: レビュー結果保存 + ログ
  - id: save-results
    kind: task
    facets:
      persona: project-manager
      knowledge: [error-patterns]
      instructions: [save-review-and-log]
    input: |
      Task: ${workflow.inputs.task}
      Design: ${design.output}
      Plan: ${plan.output}
      Review: ${review.output}
    output_contract: save-result

  # Stage 17: push + PR作成 + 結果報告（ユーザー承認必須）
  - id: finalize
    kind: task
    gate: approval
    facets:
      persona: project-manager
      policies: [git-conventions]
      instructions: [push-pr-report]
    input: |
      Task: ${workflow.inputs.task}
      Design: ${design.output}
      Git Setup: ${setup-git.output}
      Review Grade: ${review.output.grade}
      Quality: ${quality-gate.output}
    output_contract: completion-report
```

- [ ] **Step 3: Validate stage count**

Run: `grep -c "^  - id:" workflows/dev-orchestration.yaml`
Expected: `17`

- [ ] **Step 4: Validate no remaining analyze references**

Run: `grep -n 'analyze' workflows/dev-orchestration.yaml`
Expected: No output

- [ ] **Step 5: Validate all facet and contract files exist**

Run:
```bash
for f in design-spec plan-tasks review-design review-plan setup-worktree; do
  test -f "facets/instructions/$f.md" && echo "OK: $f" || echo "MISSING: $f"
done
for c in design-result design-review-result plan-result plan-review-result worktree-setup; do
  test -f "contracts/$c.md" && echo "OK: $c" || echo "MISSING: $c"
done
```
Expected: All OK

- [ ] **Step 6: Validate loop monitor stage references**

Run: `grep -A1 'cycle:' workflows/dev-orchestration.yaml`
Expected: All stage IDs in cycles exist in the stages list

- [ ] **Step 7: Commit**

```bash
git add workflows/dev-orchestration.yaml
git commit -m "feat(mosaic-orch): 17-stage workflow with design-review and plan-review loops"
```

---

### Task 6: Sync + Final Validation

**Files:**
- All new/modified files synced to `~/.claude/skills/mosaic-orch/`

- [ ] **Step 1: Verify hardlink (no copy needed)**

Run: `stat --format='%i' workflows/dev-orchestration.yaml ~/.claude/skills/mosaic-orch/workflows/dev-orchestration.yaml`
Expected: Same inode (hardlinks, auto-synced)

- [ ] **Step 2: Full schema validation**

Run the regex-based V3-V16 validation script against the new YAML (same as the one used in the previous implementation round).

- [ ] **Step 3: Commit plan document**

```bash
git add docs/superpowers/plans/2026-04-14-planning-enhancement.md
git commit -m "docs(mosaic-orch): planning enhancement implementation plan"
```
