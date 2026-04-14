# dev-orchestration Workflow Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the monolithic `analyze` stage into explicit `design` and `plan` stages with approval gates, and add a `setup-worktree` stage for implementation isolation.

**Architecture:** The current 13-stage dev-orchestration workflow has a single `analyze` stage that handles both design decisions and task decomposition. This redesign separates concerns: `design` focuses on requirements understanding and architecture (read-only, approval-gated), `plan` focuses on subtask decomposition and wave allocation (read-only, approval-gated), and `setup-worktree` creates an isolated git worktree before implementation stages begin. Downstream variable references migrate from `${analyze.output.*}` to `${design.output.*}` or `${plan.output.*}`.

**Tech Stack:** YAML workflow definitions, Markdown facet instructions, Markdown output contracts

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `facets/instructions/design-spec.md` | Design stage instruction: codebase diagnosis, requirements analysis, architecture design |
| Create | `contracts/design-result.md` | Output contract for design stage |
| Create | `facets/instructions/plan-tasks.md` | Plan stage instruction: subtask decomposition, persona/skill/MCP selection, wave allocation |
| Create | `contracts/plan-result.md` | Output contract for plan stage |
| Create | `facets/instructions/setup-worktree.md` | Worktree creation instruction |
| Create | `contracts/worktree-setup.md` | Output contract for worktree setup |
| Modify | `workflows/dev-orchestration.yaml` | 13-stage -> 15-stage workflow with new stages and updated variable references |

Existing files NOT modified (backward compatibility): `facets/instructions/analyze-dev-task.md`, `contracts/task-analysis.md` remain for other workflows that may reference them.

---

### Task 1: Design Stage Instruction

**Files:**
- Create: `facets/instructions/design-spec.md`

- [ ] **Step 1: Create the design-spec instruction file**

```markdown
---
name: design-spec
description: コードベース診断、要件分析、アーキテクチャ設計の指示
---

# 指示: 設計仕様

与えられたタスクに対して、コードベース診断・要件分析・アーキテクチャ設計を行ってください。

## 手順

### Step 0: 既存コードベース診断（実施必須）

タスクの分析に入る前に、プロジェクトの現状を診断してください。以下をツールで調査し、結果を分析に活かすこと:

1. **プロジェクト構造**: `ls`, `Glob` で主要ディレクトリとファイル構造を把握する
2. **パッケージ構成**: `package.json`, `build.gradle`, `pom.xml` 等を読み、使用フレームワーク・ライブラリを特定する
3. **既存テストパターン**: テストファイルを `Glob("**/*.test.*", "**/*.spec.*", "**/test/**")` で探し、テストフレームワーク・テスト構造を把握する
4. **既存API規約**: ルーティング定義やコントローラを探し、命名規約・レスポンス形式を把握する（該当する場合のみ）
5. **ディレクトリ命名規約**: 既存の命名パターン（camelCase / kebab-case / PascalCase）を確認する

### Step 1: 要件分析

以下の項目を分析してください:
1. **影響レイヤー**: FE / BE / 両方 / 非エンジニアリング
2. **タスク種別**: 新機能 / バグ修正 / リファクタリング / テスト / ドキュメント / コンテンツ
3. **スコープ**: 変更の範囲と影響を受けるコンポーネント
4. **制約事項**: パフォーマンス要件、互換性要件、技術的制約

### Step 2: アーキテクチャ設計

1. **既存パターンとの整合性**: 既存のアーキテクチャパターンで対応可能か判断する
2. **設計方針**: 新規設計が必要な場合、アプローチを提案する
3. **リスク評価**: 技術的リスクと軽減策を特定する
4. **依存関係**: BE→FE依存、外部サービス依存などを整理する

## 重要な制約

- **あなたの出力は設計レポートのみ。** ファイルの作成・変更・コーディングは一切行わないこと
- 実装の詳細（具体的なコード、ファイル名の決定）は後続の plan stage が担当する
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
```

- [ ] **Step 2: Verify file exists and frontmatter is valid**

Run: `head -3 facets/instructions/design-spec.md`
Expected: `---`, `name: design-spec`, `description: ...`

- [ ] **Step 3: Commit**

```bash
git add facets/instructions/design-spec.md
git commit -m "feat(mosaic-orch): add design-spec instruction for design stage"
```

---

### Task 2: Design Stage Contract

**Files:**
- Create: `contracts/design-result.md`

- [ ] **Step 1: Create the design-result contract file**

```markdown
---
name: design-result
description: 設計仕様の出力契約
---

# Output Contract: design-result

## 期待形式
"## Codebase Context" 見出しの下にプロジェクト診断結果、"## Requirements" 見出しの下に要件分析、"## Architecture" 見出しの下にアーキテクチャ設計。

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

## 検証項目
- codebase_context が空でないこと（必須）
- impact_layer が "FE", "BE", "both", "non-engineering" のいずれかであること（必須）
- task_type が "feature", "bugfix", "refactor", "test", "docs", "content" のいずれかであること（必須）
- has_fe が "true" または "false" であること（必須）
- scope が空でないこと（必須）
- approach が空でないこと（必須）
```

- [ ] **Step 2: Commit**

```bash
git add contracts/design-result.md
git commit -m "feat(mosaic-orch): add design-result output contract"
```

---

### Task 3: Plan Stage Instruction

**Files:**
- Create: `facets/instructions/plan-tasks.md`

- [ ] **Step 1: Create the plan-tasks instruction file**

```markdown
---
name: plan-tasks
description: 設計仕様に基づくサブタスク分解、persona/instruction/skill/MCP選定、Wave振り分けの指示
---

# 指示: タスク計画

承認済みの設計仕様に基づき、サブタスク分解・担当者選定・Wave振り分けを行ってください。

## 入力

- **設計仕様** (design stage出力): コードベースコンテキスト、要件分析、アーキテクチャ設計

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

### Step 3: スキル選定

Knowledge の skill-catalog を参照し、各サブタスクに必要なスキル名を2〜4個選定する。
ユーザーの環境にインストール済みのスキルのみ選定すること（skill-catalog に載っているものが対象）。

### Step 3.5: MCP検出と割り当て

Knowledge の mcp-catalog を参照し、利用可能なMCPツールを検出する:
1. ToolSearch で `"mcp__"` を検索し、利用可能なMCPプレフィックスを特定する
2. 各サブタスクに適切なMCPを割り当てる（0〜2個）
3. MCP未検出の場合は割り当てない（mcpsフィールドを省略）
4. 割り当て結果は出力の各Subtaskの `mcps:` フィールドに記載する

### Step 4: FEサブタスクのデザイン要件定義（has_fe=trueの場合）

FE サブタスクがある場合、**Wave 2 の最初のサブタスク**（FE基盤構築）に以下を含める:
- CSS変数によるデザイントークン定義（色、スペーシング、フォント）
- `prefers-color-scheme: dark` 対応のダークモードトークン
- モバイルブレークポイント定義（375px / 768px）
- サイドバーのモバイル対応方針（非表示 or ハンバーガー）

### Step 5: Wave振り分け

- 依存関係のないサブタスクを Wave 1 にまとめる
- 依存関係のあるサブタスクを Wave 2 に配置する
- Wave 2 が不要な場合は has_wave2: false とする

## 重要な制約

- **あなたの出力は計画レポートのみ。** ファイルの作成・変更・コーディングは一切行わないこと
- 実装は後続の implement stage が担当する。あなたは「何を・誰が・どの順で」を決めるだけ
- 設計仕様で承認された方針に従うこと。設計を変更する場合はその理由を明記すること
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
- skills: [{スキル名1}, {スキル名2}]
- mcps: [{MCP名: 説明}]（利用可能なMCPがある場合のみ）

### Subtask 2
...

## Wave 2 Subtasks
### Subtask 1
- persona: {persona名}
- instruction: {instruction名}
- description: {サブタスク内容の1行説明}
- skills: [{スキル名1}, {スキル名2}]
- mcps: [{MCP名: 説明}]（利用可能なMCPがある場合のみ）
```

- [ ] **Step 2: Commit**

```bash
git add facets/instructions/plan-tasks.md
git commit -m "feat(mosaic-orch): add plan-tasks instruction for plan stage"
```

---

### Task 4: Plan Stage Contract

**Files:**
- Create: `contracts/plan-result.md`

- [ ] **Step 1: Create the plan-result contract file**

```markdown
---
name: plan-result
description: タスク計画の出力契約
---

# Output Contract: plan-result

## 期待形式
"## Analysis" 見出しの下にモード情報、"## Wave 1 Subtasks" と "## Wave 2 Subtasks" にサブタスク一覧。

## パース規則（エンジンが抽出）
- mode: "## Analysis" セクション内の "- mode:" 直後のテキスト。正規表現 /^(parallel|wave)$/
- has_wave2: "- has_wave2:" 直後のテキスト。正規表現 /^(true|false)$/
- has_fe: "- has_fe:" 直後のテキスト。正規表現 /^(true|false)$/
- wave1_subtasks: "## Wave 1 Subtasks" セクション内の "### Subtask" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - persona: "- persona:" 直後のテキスト
  - instruction: "- instruction:" 直後のテキスト
  - description: "- description:" 直後のテキスト
  - skills: "- skills:" 直後のテキスト（配列として解析）
  - mcps: "- mcps:" 直後のテキスト（配列として解析、空の場合は空配列）
- wave2_subtasks: "## Wave 2 Subtasks" セクション内を同様に解析。セクションがない場合は空配列

## 検証項目
- mode が "parallel" または "wave" であること（必須）
- has_wave2 が "true" または "false" であること（必須）
- has_fe が "true" または "false" であること（必須）
- wave1_subtasks の件数が 1 以上であること（必須）
- 各 subtask に persona が空でないこと（必須）
- 各 subtask に instruction が空でないこと（必須）
- has_wave2 が true の場合、wave2_subtasks の件数が 1 以上であること（必須）
```

- [ ] **Step 2: Commit**

```bash
git add contracts/plan-result.md
git commit -m "feat(mosaic-orch): add plan-result output contract"
```

---

### Task 5: Worktree Setup Instruction

**Files:**
- Create: `facets/instructions/setup-worktree.md`

- [ ] **Step 1: Create the setup-worktree instruction file**

```markdown
---
name: setup-worktree
description: 実装用git worktreeの作成と隔離環境のセットアップ指示
---

# 指示: Worktree セットアップ

実装フェーズに入る前に、git worktree を作成して隔離された作業環境を準備してください。

## 前提

- Git ブランチは setup-git stage で作成済み
- design/plan stage は main worktree（読み取り専用）で完了済み

## 手順

### Step 1: Worktree ディレクトリの決定

以下のパスに worktree を作成する:

```
.claude/worktrees/{branch-slug}
```

`{branch-slug}` はブランチ名から `/` を `-` に置換した文字列。

### Step 2: Worktree 作成

```bash
git worktree add .claude/worktrees/{branch-slug} {branch_name}
```

- `{branch_name}` は setup-git stage で作成されたブランチ名
- 既にworktreeが存在する場合はエラーになるため、事前に存在確認する

### Step 3: 依存関係のインストール

worktree ディレクトリに移動し、プロジェクトの依存関係をインストールする:

1. `package.json` が存在する場合: `npm install` または `yarn install`
2. `build.gradle` が存在する場合: `./gradlew build` は不要（IDE依存）
3. 依存関係ファイルがない場合: スキップ

### Step 4: Base SHA の記録

```bash
git rev-parse HEAD
```

resume 時のworktree検証に使用するため、base SHA を記録する。

## 重要な制約

- worktree パスは `.claude/worktrees/` 配下に限定すること
- main worktree のファイルを変更しないこと
- `git pull` や `git checkout` を main worktree で実行しないこと

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

以下の形式で**のみ**出力してください:

## Worktree Setup
- worktree_path: {worktreeの絶対パス}
- branch_name: {ブランチ名}
- base_sha: {ベースコミットのSHA}
- deps_installed: true | false
```

- [ ] **Step 2: Commit**

```bash
git add facets/instructions/setup-worktree.md
git commit -m "feat(mosaic-orch): add setup-worktree instruction"
```

---

### Task 6: Worktree Setup Contract

**Files:**
- Create: `contracts/worktree-setup.md`

- [ ] **Step 1: Create the worktree-setup contract file**

```markdown
---
name: worktree-setup
description: Worktreeセットアップの出力契約
---

# Output Contract: worktree-setup

## 期待形式
"## Worktree Setup" 見出しの下にworktreeパスとブランチ情報。

## パース規則（エンジンが抽出）
- worktree_path: "- worktree_path:" 直後のテキスト
- branch_name: "- branch_name:" 直後のテキスト
- base_sha: "- base_sha:" 直後のテキスト。正規表現 /^[0-9a-f]{7,40}$/
- deps_installed: "- deps_installed:" 直後のテキスト。正規表現 /^(true|false)$/

## 検証項目
- worktree_path が空でないこと（必須）
- branch_name が空でないこと（必須）
- base_sha が有効なgit SHAフォーマットであること（必須）
- deps_installed が "true" または "false" であること（必須）
```

- [ ] **Step 2: Commit**

```bash
git add contracts/worktree-setup.md
git commit -m "feat(mosaic-orch): add worktree-setup output contract"
```

---

### Task 7: Update dev-orchestration.yaml

This is the core change. The workflow goes from 13 stages to 15 stages. All `${analyze.output.*}` references are updated to `${design.output.*}` or `${plan.output.*}`.

**Files:**
- Modify: `workflows/dev-orchestration.yaml`

- [ ] **Step 1: Replace the full workflow YAML**

The new workflow structure:

| # | ID | Kind | New? | Gate | Notes |
|---|-----|------|------|------|-------|
| 1 | design | task | NEW | approval | Read-only codebase diagnosis + architecture |
| 2 | plan | task | NEW | approval | Subtask decomposition using design output |
| 3 | check-dup | task | existing | - | Unchanged |
| 4 | setup-git | task | existing | - | Input references updated |
| 5 | setup-worktree | task | NEW | - | Creates isolated worktree |
| 6 | implement-wave1 | fan_out | existing | - | References updated: plan.output, design.output |
| 7 | integrate-wave1 | fan_in | existing | - | Unchanged |
| 8 | implement-wave2 | fan_out | existing | - | References updated |
| 9 | integrate-wave2 | fan_in | existing | - | References updated |
| 10 | quality-gate | task | existing | - | References updated |
| 11 | review | task | existing | - | References updated |
| 12 | fix | task | existing | - | References updated |
| 13 | ui-verify | task | existing | - | References updated |
| 14 | save-results | task | existing | - | References updated |
| 15 | finalize | task | existing | approval | References updated |

Write the complete updated YAML:

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
  # Stage 1: 設計仕様 — コードベース診断 + 要件分析 + アーキテクチャ設計
  - id: design
    kind: task
    gate: approval
    facets:
      persona: architect
      knowledge: [team-roster, skill-catalog, mcp-catalog]
      instructions: [design-spec]
    input: ${workflow.inputs.task}
    output_contract: design-result
    permission: default  # 読み取り専用 — 分析のみ、ファイル変更不可

  # Stage 2: タスク計画 — サブタスク分解 + persona/instruction/skill選定 + Wave振り分け
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
    permission: default  # 読み取り専用 — 計画のみ、ファイル変更不可

  # Stage 3: 重複チェック
  - id: check-dup
    kind: task
    facets:
      persona: project-manager
      instructions: [check-duplicates]
    input: ${workflow.inputs.task}
    output_contract: duplicate-check

  # Stage 4: Issue + ブランチ作成
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

  # Stage 5: Worktree 作成 — 実装用の隔離環境を準備
  - id: setup-worktree
    kind: task
    facets:
      persona: project-manager
      instructions: [setup-worktree]
    input: |
      Branch: ${setup-git.output.branch_name}
      Design: ${design.output}
    output_contract: worktree-setup

  # Stage 6: Wave1 並列実装
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
    output_contract: implementation-result

  # Stage 7: Wave1 統合
  - id: integrate-wave1
    kind: fan_in
    from: ${implement-wave1.outputs}
    facets:
      persona: integrator
      policies: [coding-standards]
      instructions: [merge-implementations]
    output_contract: integration-result

  # Stage 8: Wave2 並列実装（条件付き）
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
    output_contract: implementation-result

  # Stage 9: Wave2 統合（条件付き）
  - id: integrate-wave2
    kind: fan_in
    when: ${plan.output.has_wave2} == 'true'
    from: ${implement-wave2.outputs}
    facets:
      persona: integrator
      policies: [coding-standards]
      instructions: [merge-implementations]
    output_contract: integration-result

  # Stage 10: 品質ゲート
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

  # Stage 11: 5軸コードレビュー
  # A+ → ui-verifyへスキップ、それ以外 → fixへ(stageIndex++)
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

  # Stage 12: レビュー指摘の修正（1ラウンド）→ reviewへ戻る
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

  # Stage 13: UI視覚検証（FE変更時のみ — ダークモード/モバイル必須）
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

  # Stage 14: レビュー結果保存 + ログ
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

  # Stage 15: push + PR作成 + 結果報告（ユーザー承認必須）
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

Variable reference migration summary:
- `${analyze.output}` → `${design.output}` (for codebase context, approach) or `${plan.output}` (for subtasks, wave info)
- `${analyze.output.wave1_subtasks}` → `${plan.output.wave1_subtasks}`
- `${analyze.output.wave2_subtasks}` → `${plan.output.wave2_subtasks}`
- `${analyze.output.has_wave2}` → `${plan.output.has_wave2}`
- `${analyze.output.has_fe}` → `${plan.output.has_fe}`
- `${analyze.output.codebase_context}` → `${design.output.codebase_context}`
- `${analyze.output.wave1_subtasks[0].persona}` → `${plan.output.wave1_subtasks[0].persona}`
- New: `${setup-worktree.output.worktree_path}` injected into implement stages

- [ ] **Step 2: Validate YAML syntax**

Run: `python3 -c "import yaml; yaml.safe_load(open('workflows/dev-orchestration.yaml'))" && echo "YAML valid"`
Expected: `YAML valid`

- [ ] **Step 3: Verify stage count is 15**

Run: `grep -c "^  - id:" workflows/dev-orchestration.yaml`
Expected: `15`

- [ ] **Step 4: Verify all new facet references exist**

Run: `for f in design-spec plan-tasks setup-worktree; do test -f "facets/instructions/$f.md" && echo "OK: $f" || echo "MISSING: $f"; done`
Expected: All OK

- [ ] **Step 5: Verify all new contract references exist**

Run: `for c in design-result plan-result worktree-setup; do test -f "contracts/$c.md" && echo "OK: $c" || echo "MISSING: $c"; done`
Expected: All OK

- [ ] **Step 6: Verify no remaining analyze references**

Run: `grep -n 'analyze' workflows/dev-orchestration.yaml`
Expected: No output (no remaining references to old `analyze` stage)

- [ ] **Step 7: Commit**

```bash
git add workflows/dev-orchestration.yaml
git commit -m "feat(mosaic-orch): redesign workflow — 13 to 15 stages with design/plan/worktree phases"
```

---

### Task 8: Sync to Installed Location

The skill has two locations: development (`/home/itoshun/works/claude-skills-org/skills/mosaic-orch/`) and installed (`/home/itoshun/.claude/skills/mosaic-orch/`). Sync changes.

**Files:**
- Sync: All new/modified files to `~/.claude/skills/mosaic-orch/`

- [ ] **Step 1: Sync new instruction files**

```bash
cp facets/instructions/design-spec.md ~/.claude/skills/mosaic-orch/facets/instructions/
cp facets/instructions/plan-tasks.md ~/.claude/skills/mosaic-orch/facets/instructions/
cp facets/instructions/setup-worktree.md ~/.claude/skills/mosaic-orch/facets/instructions/
```

- [ ] **Step 2: Sync new contract files**

```bash
cp contracts/design-result.md ~/.claude/skills/mosaic-orch/contracts/
cp contracts/plan-result.md ~/.claude/skills/mosaic-orch/contracts/
cp contracts/worktree-setup.md ~/.claude/skills/mosaic-orch/contracts/
```

- [ ] **Step 3: Sync updated workflow**

```bash
cp workflows/dev-orchestration.yaml ~/.claude/skills/mosaic-orch/workflows/
```

- [ ] **Step 4: Verify sync**

```bash
diff -r workflows/ ~/.claude/skills/mosaic-orch/workflows/
diff -r contracts/ ~/.claude/skills/mosaic-orch/contracts/
diff facets/instructions/design-spec.md ~/.claude/skills/mosaic-orch/facets/instructions/design-spec.md
diff facets/instructions/plan-tasks.md ~/.claude/skills/mosaic-orch/facets/instructions/plan-tasks.md
diff facets/instructions/setup-worktree.md ~/.claude/skills/mosaic-orch/facets/instructions/setup-worktree.md
```

Expected: No diff output (files are identical)

- [ ] **Step 5: Commit sync (if applicable)**

No commit needed — installed location is not version controlled.

---

### Task 9: Dry-Run Validation

- [ ] **Step 1: Run dry-run to validate the new workflow**

```bash
# Invoke mosaic-orch with --dry-run to validate stage resolution and variable references
```

The dry-run should:
- Parse the YAML without errors (V1-V17 pass)
- Resolve all facet references (V6 pass)
- Resolve all contract references (V7 pass)
- Show the 15-stage execution plan

- [ ] **Step 2: Review dry-run output**

Verify:
- All 15 stages listed
- design and plan stages show approval gates
- setup-worktree appears between setup-git and implement-wave1
- No SchemaError or FacetNotFound errors

- [ ] **Step 3: Final commit with validation confirmation**

```bash
git add docs/superpowers/plans/2026-04-14-workflow-redesign.md
git commit -m "docs(mosaic-orch): add workflow redesign implementation plan"
```
