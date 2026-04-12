# Mosaic-Orch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** faceted-promptingのSoC原則を拡張した、ドメイン非依存のマルチエージェントオーケストレーションSkillを構築する

**Architecture:** 5層構造(L1 Entry → L2 Orchestrator → L3 StageRunner → L4 Composer → L5 Dispatcher)+ 横断モジュール(contracts, facet-loader, variable-resolver, run-recorder)。各ファイル1責務、一方向依存。宣言的Workflow YAML(3 kind: task/fan_out/fan_in)で駆動。

**Tech Stack:** Claude Code Skill (Markdown instruction files), YAML workflow definitions, Task tool for agent dispatch

**Spec:** `docs/superpowers/specs/2026-04-12-mosaic-orch-design.md`

**Development path:** `skills/mosaic-orch/` (リポジトリ内) → `~/.claude/skills/mosaic-orch` (symlink)

---

## File Map

### Engine files (to create)
| File | Responsibility | Lines | Depends on |
|---|---|---|---|
| `skills/mosaic-orch/SKILL.md` | L1 Entry: 引数解析, workflow解決, orchestratorへ委譲 | ~80 | orchestrator.md |
| `skills/mosaic-orch/engine/yaml-schema.md` | YAMLスキーマ仕様+検証ルール | ~200 | (参照専用) |
| `skills/mosaic-orch/engine/variable-resolver.md` | `${...}` 変数展開 | ~80 | (参照専用) |
| `skills/mosaic-orch/engine/facet-loader.md` | facet名→Markdown本文の解決 | ~50 | (ファイルシステム) |
| `skills/mosaic-orch/engine/dispatcher.md` | Task tool呼び出しラッパー | ~60 | (外部Task tool) |
| `skills/mosaic-orch/engine/composer.md` | 5Facet→system/userプロンプト合成 | ~80 | facet-loader |
| `skills/mosaic-orch/engine/contracts.md` | Output Contract検証 | ~120 | variable-resolver |
| `skills/mosaic-orch/engine/run-recorder.md` | .mosaic-orch/runs/*への記録 | ~80 | (ファイルシステム) |
| `skills/mosaic-orch/engine/stage-runner.md` | 3 kindのStage実行 | ~180 | composer, dispatcher, contracts, facet-loader |
| `skills/mosaic-orch/engine/orchestrator.md` | 状態機械(INIT→...→COMPLETE) | ~150 | stage-runner, variable-resolver, run-recorder, yaml-schema |

### Asset files (to create — radio-script sample)
| File | Content |
|---|---|
| `skills/mosaic-orch/facets/personas/radio-planner.md` | ラジオ企画者ペルソナ |
| `skills/mosaic-orch/facets/personas/radio-writer.md` | ラジオ台本作家ペルソナ |
| `skills/mosaic-orch/facets/personas/editor.md` | 編集者ペルソナ |
| `skills/mosaic-orch/facets/personas/reviewer.md` | 多角レビューワーペルソナ |
| `skills/mosaic-orch/facets/policies/tone-casual.md` | カジュアルトーンポリシー |
| `skills/mosaic-orch/facets/knowledge/broadcast-format.md` | ラジオ放送フォーマット知識 |
| `skills/mosaic-orch/facets/instructions/plan-corners.md` | コーナー企画の指示 |
| `skills/mosaic-orch/facets/instructions/draft-corner.md` | コーナー執筆の指示 |
| `skills/mosaic-orch/facets/instructions/assemble-script.md` | 台本統合の指示 |
| `skills/mosaic-orch/facets/instructions/multi-axis-review.md` | 多角レビューの指示 |
| `skills/mosaic-orch/facets/instructions/apply-suggestions-and-self-assess.md` | 修正+自己採点の指示 |
| `skills/mosaic-orch/facets/rubrics/clarity.md` | 明晰さの評価軸 |
| `skills/mosaic-orch/facets/rubrics/humor.md` | ユーモアの評価軸 |
| `skills/mosaic-orch/facets/rubrics/pace.md` | テンポの評価軸 |
| `skills/mosaic-orch/facets/rubrics/accuracy.md` | 正確性の評価軸 |
| `skills/mosaic-orch/contracts/corner-plan.md` | コーナー企画の出力契約 |
| `skills/mosaic-orch/contracts/corner-draft.md` | コーナー原稿の出力契約 |
| `skills/mosaic-orch/contracts/full-script.md` | 完成台本の出力契約 |
| `skills/mosaic-orch/contracts/review-verdict.md` | レビュー判定の出力契約 |
| `skills/mosaic-orch/contracts/polished-verdict.md` | 修正+自己採点の出力契約 |
| `skills/mosaic-orch/workflows/radio-script.yaml` | ラジオ台本生成ワークフロー |

### Docs/Examples (to create)
| File | Content |
|---|---|
| `skills/mosaic-orch/examples/radio-script-walkthrough.md` | ラジオ台本WF全体の実行ウォーク |
| `skills/mosaic-orch/references/error-handling.md` | エラーパターンと対応 |

---

## Task 1: ディレクトリ構造 + SKILL.md

**Files:**
- Create: `skills/mosaic-orch/SKILL.md`
- Create: directory scaffolding

- [ ] **Step 1: ディレクトリ構造を作成**

```bash
cd /home/itoshun/works/claude-skills-org
mkdir -p skills/mosaic-orch/{engine,facets/{personas,policies,knowledge,instructions,rubrics},contracts,workflows,examples,references}
```

- [ ] **Step 2: SKILL.md を作成**

```markdown
---
name: mosaic-orch
description: >
  Facetベース(persona/policy/knowledge/instruction/rubric)のドメイン非依存オーケストレーター。
  Stage/Fan-out/Fan-in/Loopをサポートする宣言的Workflow YAMLで、複数サブエージェントを合成する。
  Use when: 多段レビューループ、並列分解タスク、faceted-prompting流の構造化プロンプト実行。
  Not for: 単発の軽い質問、開発タスク(intendant推奨)、直接コーディング。
user-invocable: true
---

# Mosaic-Orch Skill

## 引数の解析

$ARGUMENTS を以下のように解析する:

```
/mosaic-orch {workflow} [--dry-run] [--permission default|acceptEdits|bypassPermissions] {inputs...}
```

- **第1トークン**: workflow名またはYAMLファイルパス（必須）
- **`--dry-run`**: プロンプト合成まで実行し、サブエージェントは起動しない
- **`--permission`**: 権限モード（任意、デフォルト: `default`）
- **残りのトークン**: タスク入力（省略時は AskUserQuestion でユーザーに入力を求める）

例:
- `/mosaic-orch radio-script 4月のニュース` → radio-script WF, default権限
- `/mosaic-orch radio-script --dry-run 4月のニュース` → dry-run
- `/mosaic-orch /path/to/custom.yaml 実装して` → カスタムYAML

## 事前準備

手順を開始する前に、以下を **Read tool で読み込む**:
1. `engine/orchestrator.md` — 状態機械の全手順

## 手順

### 手順 1: Workflow 解決

引数からworkflow名を取得し、以下の順で検索する:
1. `.yaml` / `.yml` で終わる、または `/` を含む → ファイルパスとして直接 Read
2. workflow名として検索:
   - `~/.mosaic-orch/workflows/{name}.yaml` （ユーザーカスタム、優先）
   - `~/.claude/skills/mosaic-orch/workflows/{name}.yaml` （Skill同梱ビルトイン）
3. 見つからない場合: 上記2ディレクトリを Glob で列挙し、AskUserQuestion で選択させる

### 手順 2: Orchestrator に委譲

`engine/orchestrator.md` の手順に従って実行を開始する。以下を渡す:
- workflow YAML ファイルパス
- ユーザー入力(inputs)
- 権限モード(permission)
- dry-run フラグ

### 手順 3: 結果報告

orchestrator.md が COMPLETE を返したら、結果のサマリーをユーザーに報告する。
ABORT の場合は失敗理由を報告する（engine/orchestrator.md のABORT報告テンプレートに従う）。
```

- [ ] **Step 3: ファイル存在を確認**

```bash
ls -la skills/mosaic-orch/SKILL.md
ls -d skills/mosaic-orch/engine skills/mosaic-orch/facets/rubrics skills/mosaic-orch/contracts
```

- [ ] **Step 4: Commit**

```bash
git add skills/mosaic-orch/
git commit -m "feat(mosaic-orch): scaffold directory structure and SKILL.md entry point"
```

---

## Task 2: engine/yaml-schema.md

**Files:**
- Create: `skills/mosaic-orch/engine/yaml-schema.md`

- [ ] **Step 1: yaml-schema.md を作成**

```markdown
# Workflow YAML Schema — mosaic-orch

このドキュメントは Workflow YAML の構造定義と検証ルールを規定する。
Orchestrator(L2)が INIT 時に参照し、静的検証に使用する。

## トップレベル

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `name` | string | ✅ | workflow識別子 |
| `description` | string | | 人間向け説明 |
| `version` | `"1"` | ✅ | スキーマバージョン。値は `"1"` 固定 |
| `inputs` | InputDef[] | | ユーザーパラメータ宣言 |
| `defaults` | Defaults | | 全Stage共通のデフォルト |
| `stages` | StageDef[] | ✅ | Stage配列（宣言順が実行順） |

### InputDef

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `name` | string | ✅ | パラメータ名 |
| `type` | `"string"` | ✅ | 型（初版は string のみ） |
| `required` | boolean | | デフォルト false |

### Defaults

| フィールド | 型 | 説明 |
|---|---|---|
| `permission` | `"default"` \| `"acceptEdits"` \| `"bypassPermissions"` | デフォルト: `"default"` |
| `timeout` | number | 秒。デフォルト: 600 |

## Stage 共通フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `id` | string | ✅ | Stage識別子（workflow内でunique） |
| `kind` | `"task"` \| `"fan_out"` \| `"fan_in"` | ✅ | Stage種別 |
| `facets` | FacetSet | ✅ | Facet参照 |
| `input` | string | | 変数参照 `${...}` |
| `output_contract` | string | | contracts/{name}.md と紐付く |
| `when` | string | | 条件式。false なら SKIP |
| `permission` | string | | defaults を上書き |
| `timeout` | number | | defaults を上書き |

### FacetSet

| フィールド | 型 | 説明 |
|---|---|---|
| `persona` | string | 単一。facets/personas/{name}.md |
| `policies` | string[] | facets/policies/{name}.md |
| `knowledge` | string[] | facets/knowledge/{name}.md |
| `instructions` | string[] | facets/instructions/{name}.md |
| `rubrics` | string[] | facets/rubrics/{name}.md |

全フィールド任意。ただし `persona` がないと system prompt が空になる（警告は出す）。

## task Stage 固有フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `loop_until` | string | | 条件式。true でループ終了 |
| `max_iterations` | number | loop_until 時必須 | 上限回数 |

## fan_out Stage 固有フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `from` | string | ✅ | 反復対象の変数参照（配列を返す） |
| `as` | string | ✅ | 各要素の変数名 |
| `max_parallel` | number | | 並列度の上限。デフォルト: 全部並列 |
| `on_error` | `"fail"` \| `"continue"` | | デフォルト: `"fail"` |

## fan_in Stage 固有フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `from` | string | ✅ | 統合対象の変数参照（配列） |

## 変数参照文法

| パターン | 意味 |
|---|---|
| `${workflow.inputs.X}` | ユーザー入力パラメータ |
| `${<stage_id>.output}` | 指定StageのOutput全体 |
| `${<stage_id>.output.field}` | Output内の特定フィールド |
| `${<stage_id>.outputs}` | fan_out Stageの出力配列 |
| `${self.X}` | loop_until内で自分自身の出力フィールド |
| `${<var>}` | fan_outの`as`で宣言した変数 |

非対応: 関数呼び出し、算術、ループカウンタ、文字列結合

## 静的検証ルール

Orchestrator INIT 時に全て実行する。1つでも失敗したら SchemaError で ABORT。

| # | 検査項目 | 失敗時 |
|---|---|---|
| V1 | name, version, stages が存在する | SchemaError |
| V2 | version が `"1"` である | SchemaError |
| V3 | 全 stage の id が unique | SchemaError |
| V4 | 全 stage の kind が `task` / `fan_out` / `fan_in` のいずれか | SchemaError |
| V5 | 変数参照 `${X.output}` の X が先行 stage の id または `workflow` | SchemaError |
| V6 | 全 facet 参照先のファイルが実在する | FacetNotFound |
| V7 | 全 output_contract 参照先の contracts/{name}.md が実在する | SchemaError |
| V8 | fan_out の from が先行 stage の配列出力を参照している | SchemaError |
| V9 | fan_in の from が先行 fan_out の outputs を参照している（推奨） | WARN |
| V10 | loop_until 使用時に max_iterations が宣言されている | SchemaError |
| V11 | fan_out に as が宣言されている | SchemaError |
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/engine/yaml-schema.md
git commit -m "feat(mosaic-orch): add YAML schema specification"
```

---

## Task 3: engine/variable-resolver.md + engine/facet-loader.md

**Files:**
- Create: `skills/mosaic-orch/engine/variable-resolver.md`
- Create: `skills/mosaic-orch/engine/facet-loader.md`

- [ ] **Step 1: variable-resolver.md を作成**

```markdown
# Variable Resolver — mosaic-orch

`${...}` 形式の変数参照を解決する。Orchestrator(L2)と Contracts(横断)から呼ばれる。

## あなたの責務

テキスト中の `${...}` パターンを見つけて、対応する値に置換する。
**他モジュールの責務には踏み込まない。** Stage 実行方法も Facet 合成方法も知らない。

## 入力

- `text`: 変数参照を含む文字列
- `context`: 変数コンテキスト（以下のキーを持つマップ）
  - `workflow.inputs`: ユーザー入力パラメータのマップ
  - `{stage_id}.output`: 各 stage の出力（文字列またはパース済み構造）
  - `{stage_id}.outputs`: fan_out stage の出力配列
  - `self`: 現在の stage の最新出力（loop_until 内で使用）
  - fan_out の `as` 変数: 現在のイテレーション要素

## 解決手順

1. テキスト中の `${...}` パターンを正規表現 `/\$\{([^}]+)\}/g` で全て検出する
2. 各マッチに対して、`...` 部分をドット区切りで分割する
   - 例: `${plan.output.corners}` → `["plan", "output", "corners"]`
3. context マップを先頭キーから順に辿る
   - `plan` → `context["plan"]` → `context["plan"]["output"]` → `context["plan"]["output"]["corners"]`
4. 値が見つかったら置換する
   - 値が文字列の場合: そのまま置換
   - 値がオブジェクト/配列の場合: JSON文字列化して置換
5. 値が見つからない場合: **VariableUnresolved エラー**を報告する
   - エラーメッセージ: `Variable unresolved: ${<original>} — context keys available: [<keys>]`

## 出力

- 成功: 全変数が解決された文字列
- 失敗: VariableUnresolved エラー（変数名 + 利用可能なキー一覧を含む）

## 注意事項

- ネストした `${...}` は非対応（`${ ${a}.b }` のような形式）
- 未解決変数が1つでもあればエラー（部分解決は返さない）
- `when` / `loop_until` の条件式は変数展開のみ行い、**条件評価は呼び出し元の責務**
```

- [ ] **Step 2: facet-loader.md を作成**

```markdown
# Facet Loader — mosaic-orch

Facet名からMarkdownファイルの本文を解決する。Composer(L4)から呼ばれる。

## あなたの責務

Facet名とFacet種別(persona/policies/knowledge/instructions/rubrics)を受け取り、
対応するMarkdownファイルを Read して本文を返す。
**Facetの内容は解釈しない。** 読んで返すだけ。

## 入力

- `kind`: `"personas"` | `"policies"` | `"knowledge"` | `"instructions"` | `"rubrics"`
- `name`: Facet名（例: `"analyst"`, `"clarity"`）

## 検索順序

1. `~/.claude/skills/mosaic-orch/facets/{kind}/{name}.md` （Skill同梱）

将来拡張時: `~/.mosaic-orch/facets/{kind}/{name}.md` をスキルの前に検索する（ユーザーカスタム優先）。
初版はスキルディレクトリのみ。

## 解決手順

1. 上記パスで Read tool を実行する
2. ファイルが存在する場合:
   a. YAML frontmatter（`---` で囲まれた部分）があれば除去する
   b. frontmatter 除去後の本文を返す
3. ファイルが存在しない場合:
   - **FacetNotFound エラー**を報告する
   - エラーメッセージ: `Facet not found: {kind}/{name}.md — searched: {paths}`

## 出力

- 成功: `{ body: string, sourcePath: string }`
- 失敗: FacetNotFound エラー

## 注意事項

- ファイルの中身は一切パースしない（Rubric の採点段階も Policy のルールも関知しない）
- 空ファイルは正常値として返す（空の body）
- Facet内で他のFacetを `{{include}}` するような機能は非対応
```

- [ ] **Step 3: Commit**

```bash
git add skills/mosaic-orch/engine/variable-resolver.md skills/mosaic-orch/engine/facet-loader.md
git commit -m "feat(mosaic-orch): add variable-resolver and facet-loader modules"
```

---

## Task 4: engine/dispatcher.md

**Files:**
- Create: `skills/mosaic-orch/engine/dispatcher.md`

- [ ] **Step 1: dispatcher.md を作成**

```markdown
# Dispatcher — mosaic-orch (L5)

Task tool 呼び出しのラッパー。Stage Runner(L3) から呼ばれる。

## あなたの責務

system/user プロンプトと権限モードを受け取り、Task tool でサブエージェントを起動して、
その出力（文字列）を返す。
**プロンプトの中身は知らない。** Facet も Contract も Stage も関知しない。

## 単発実行（task / fan_in Stage 用）

### 入力
- `systemPrompt`: string
- `userMessage`: string
- `permission`: `"default"` | `"acceptEdits"` | `"bypassPermissions"`
- `timeout`: number（秒）
- `stageName`: string（ログ用の名前）

### 手順
1. Task tool を呼ぶ:
   ```
   prompt: |
     <system>
     {systemPrompt}
     </system>

     {userMessage}
   description: "{stageName} - mosaic-orch"
   subagent_type: "general-purpose"
   mode: {permission}
   ```
2. Task tool の戻り値（文字列）をそのまま返す

### エラー処理
- Task tool がタイムアウトした場合: **DispatchTimeout エラー**
  - 1回リトライする（同じプロンプト）
  - 2回目も失敗したら Stage Runner にエラーを返す

## 並列実行（fan_out Stage 用）

### 入力
- `prompts`: Array<{ systemPrompt, userMessage, permission, timeout, stageName }>
- `maxParallel`: number | null（null = 全部並列）

### 手順
1. maxParallel が null または prompts.length 以上の場合:
   - **1つのメッセージで** 全 prompts に対して Task tool を並列に呼ぶ
   - 全 Task 完了を待機し、結果配列を返す

2. maxParallel が prompts.length 未満の場合:
   - prompts を maxParallel 個ずつのバッチに分割する
   - バッチ単位で並列実行し、バッチ間は順次
   - 全バッチ完了後、結果配列を元の順序で返す

### エラー処理
- 各 Task のタイムアウトは単発と同じ（1回リトライ）
- 結果配列に失敗した要素がある場合: 成功/失敗のフラグを付けて Stage Runner に返す
  （Stage Runner が on_error ポリシーに基づいて判定する）

## Dry-run モード

dry-run フラグが true の場合:
- Task tool は**呼ばない**
- 代わりに `"[DRY-RUN] Would dispatch: {stageName}"` という文字列を返す
- 並列の場合は N 個の dry-run 文字列を配列で返す
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/engine/dispatcher.md
git commit -m "feat(mosaic-orch): add dispatcher module (L5)"
```

---

## Task 5: engine/composer.md

**Files:**
- Create: `skills/mosaic-orch/engine/composer.md`

- [ ] **Step 1: composer.md を作成**

```markdown
# Composer — mosaic-orch (L4)

5 Facet を決定論的に system/user プロンプトへ合成する。
faceted-prompting の compose() 相当。Stage Runner(L3) から呼ばれる。

## あなたの責務

FacetSet を受け取り、決定論的にプロンプトを合成する。**純粋関数**として実装する。
Stage の概念も Fan-out も知らない。入力された Facet を配置ルールに従って並べるだけ。

## 事前読み込み

処理を開始する前に `engine/facet-loader.md` を Read する。

## 入力

- `facets`: FacetSet（YAML の facets フィールド）
  ```yaml
  persona: analyst
  policies: [quality]
  knowledge: [domain, architecture]
  instructions: [analyze-data]
  rubrics: [clarity, accuracy]
  ```
- `order`: string[]（任意。デフォルト: `["knowledge", "instructions", "policies", "rubrics"]`）

## 合成手順

### 1. Facet 解決
facet-loader を使って各 facet 名をファイル本文に解決する:
- `persona` → facet-loader.resolve("personas", name) → 1つの本文
- `policies` → 各 name に対して facet-loader.resolve("policies", name) → 本文の配列
- `knowledge` → 同上
- `instructions` → 同上
- `rubrics` → 同上

いずれかの facet-loader が FacetNotFound を返したら即座にエラーを返す。

### 2. System プロンプト構築
- persona がある場合: persona の本文をそのまま systemPrompt とする
- persona がない場合: systemPrompt は空文字列（WARN を出力）

### 3. User メッセージ構築
order の順序に従って、各 facet 群をセクションとして追記する:

```
## Knowledge

{knowledge[0] の本文}

---

{knowledge[1] の本文}

## Instructions

{instructions[0] の本文}

## Policies

{policies[0] の本文}

## Rubrics

{rubrics[0] の本文}

---

{rubrics[1] の本文}
```

ルール:
- 群内の順序は YAML での宣言順（配列のインデックス順）
- 群内の複数 facet は `---`（水平線）で区切る
- 空の群（配列が [] または未宣言）はセクションごと省略する
- セクション見出しは `## {Kind名}` で固定（カスタマイズ不可）

### 4. Rubrics の末尾固定
order の指定に関わらず、**rubrics は必ず userMessage の末尾**に配置する。
order に rubrics が含まれている場合はその位置を使い、含まれていない場合は末尾に自動追加する。

## 出力

```
{
  systemPrompt: string,
  userMessage: string,
  sourceFiles: string[]   # 読み込んだ facet ファイルパスの一覧
}
```

## 注意事項

- テンプレート変数（`{{variable}}`）の展開は**しない**。将来拡張候補
- 同じ facet 名が複数 kind で使われていてもエラーにしない（ファイルパスが異なるため）
- sourceFiles は run-recorder がトレースに使うために返す
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/engine/composer.md
git commit -m "feat(mosaic-orch): add composer module (L4)"
```

---

## Task 6: engine/contracts.md

**Files:**
- Create: `skills/mosaic-orch/engine/contracts.md`

- [ ] **Step 1: contracts.md を作成**

```markdown
# Contracts — mosaic-orch

Output Contract の読み込み・抽出・検証を行う。Stage Runner(L3) から呼ばれる。

## あなたの責務

contract 名とサブエージェント出力を受け取り、
(1) contract 定義ファイルを読む → (2) 出力からフィールドを抽出 → (3) 検証項目をチェック。
**Stage 実行方法は知らない。** 文字列を受け取って検証結果を返すだけ。

## 事前読み込み

処理を開始する前に `engine/variable-resolver.md` を Read する（条件検証に使う場合）。

## 入力

- `contractName`: string（例: `"review-verdict"`）
- `agentOutput`: string（サブエージェントの出力テキスト全体）

## Contract 定義ファイルの構造

`contracts/{contractName}.md` を Read する。以下のセクションを期待する:

```markdown
---
name: review-verdict
description: 多角レビューの総合判定
---

# Output Contract: review-verdict

## 期待形式
（人間向け説明。検証には使わない）

## パース規則（エンジンが抽出）
- {fieldName}: {抽出方法の説明}
  例: grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/

## 検証項目
- {fieldName} が {条件}（必須 / 推奨）
```

## 処理手順

### Step 1: Contract 定義ファイルの読み込み
1. `contracts/{contractName}.md` を Read する
2. ファイルが存在しない場合: SchemaError（静的検証で防ぐべきだが、防御的にチェック）

### Step 2: フィールド抽出
「## パース規則」セクションを読み、各フィールドの抽出方法に従って agentOutput からフィールドを抽出する。

抽出方法の解釈:
- **見出し直下**: agentOutput 中の該当見出し以降、次の見出しまでのテキストを取得
- **正規表現**: 指定された正規表現でマッチングし、最初のマッチを取得
- **箇条書き配列化**: 箇条書き（`- ` で始まる行）を配列に変換

抽出結果を `extracted` マップとして保持する: `{ grade: "A+", evidence: "...", suggestions: [...] }`

### Step 3: 検証
「## 検証項目」セクションを読み、各項目を上から順にチェックする。

- 「必須」と記載されたフィールドが空または未抽出 → **ContractViolation エラー**
- 「推奨」と記載されたフィールドが空 → WARN（エラーにはしない）
- 条件（正規表現マッチ、件数範囲など）を満たさない → **ContractViolation エラー**

### Step 4: 結果返却

## 出力

- 成功: `{ extracted: Map<string, any>, valid: true }`
- 失敗: `ContractViolation { field, expected, actual, contractName }`

## エラー処理

ContractViolation が発生した場合:
- Stage Runner に返す（Stage Runner が 2 回までリトライする）
- エラーメッセージに以下を含める:
  - contract 名
  - 失敗したフィールド名
  - 期待値と実際値
  - agentOutput の先頭 200 文字（デバッグ用）
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/engine/contracts.md
git commit -m "feat(mosaic-orch): add contracts module"
```

---

## Task 7: engine/run-recorder.md

**Files:**
- Create: `skills/mosaic-orch/engine/run-recorder.md`

- [ ] **Step 1: run-recorder.md を作成**

```markdown
# Run Recorder — mosaic-orch

実行ログを `.mosaic-orch/runs/` に記録する。Orchestrator(L2) から呼ばれる。

## あなたの責務

実行の開始・Stage 完了・終了のタイミングで成果物やトレースを書き出す。
**Stage の実行方法は知らない。** 渡されたデータを指定のパスに書くだけ。

## ディレクトリ構造

```
.mosaic-orch/runs/{YYYYMMDD-HHmmss}-{workflow-name}/
├── workflow.yaml            # 実行に使った YAML のコピー
├── inputs.json              # ユーザー入力
├── trace.ndjson             # イベントログ（JSON Lines）
├── stages/
│   ├── {stage-id}/
│   │   ├── prompt.md        # Composer が組み立てたプロンプト
│   │   ├── response.md      # サブエージェントの出力
│   │   └── extracted.json   # Contract 抽出結果
│   ├── {stage-id}-{N}/      # fan_out の場合: stage-id-1, stage-id-2, ...
│   └── ...
└── final.md                 # 最終 Stage の出力
```

## API（Orchestrator から呼ばれる操作）

### initRun(workflowYamlPath, inputs, workflowName)
1. タイムスタンプ `YYYYMMDD-HHmmss` を生成する
2. `slug = {timestamp}-{workflowName}` でランディレクトリパスを確定
3. ディレクトリ構造を mkdir -p で作成
4. workflow.yaml を Read → Write でコピー
5. inputs を JSON にして inputs.json に Write
6. trace.ndjson を空ファイルで作成
7. ランディレクトリパスを返す

### recordEvent(runDir, event)
1. event オブジェクトに `ts` フィールド（ISO 8601）を追加
2. JSON 1 行にシリアライズして trace.ndjson に追記（Bash で `echo >> `）

イベント種別:
```json
{"ts": "...", "event": "stage_start", "stage_id": "plan", "iteration": 1}
{"ts": "...", "event": "prompt_composed", "stage_id": "plan", "chars": 1834}
{"ts": "...", "event": "dispatch", "stage_id": "plan", "permission": "default"}
{"ts": "...", "event": "response", "stage_id": "plan", "chars": 2140}
{"ts": "...", "event": "contract_check", "stage_id": "plan", "result": "ok"}
{"ts": "...", "event": "stage_complete", "stage_id": "plan", "duration_ms": 4200}
{"ts": "...", "event": "stage_skip", "stage_id": "polish", "reason": "when=false"}
{"ts": "...", "event": "abort", "stage_id": "draft", "error": "ContractViolation"}
{"ts": "...", "event": "complete", "final_stage": "assemble"}
```

### recordStage(runDir, stageId, data)
1. `stages/{stageId}/prompt.md` に data.prompt を Write
2. `stages/{stageId}/response.md` に data.response を Write
3. data.extracted があれば `stages/{stageId}/extracted.json` に JSON で Write

fan_out の場合: stageId を `{stageId}-{index}` にして各並列要素を記録する。

### recordFinal(runDir, output)
1. `final.md` に最終 Stage の出力を Write

## Dry-run モード

dry-run の場合:
- ランディレクトリのプレフィックスを `DRYRUN-` にする
- prompt.md は記録する（Composer の出力確認用）
- response.md は記録しない（Dispatcher が呼ばれないため）
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/engine/run-recorder.md
git commit -m "feat(mosaic-orch): add run-recorder module"
```

---

## Task 8: engine/stage-runner.md

**Files:**
- Create: `skills/mosaic-orch/engine/stage-runner.md`

- [ ] **Step 1: stage-runner.md を作成**

```markdown
# Stage Runner — mosaic-orch (L3)

1 Stage の実行を担当する。Orchestrator(L2) から呼ばれる。

## あなたの責務

Stage 定義を受け取り、(1) Facet 合成 → (2) 入力注入 → (3) サブエージェント起動 → (4) 契約検証
のパイプラインを実行して結果を返す。
**Workflow 全体は知らない。** 次の Stage も前の Stage も関知しない。

## 事前読み込み

以下を **Read tool で読み込む**:
1. `engine/composer.md` — Facet 合成
2. `engine/dispatcher.md` — サブエージェント起動
3. `engine/contracts.md` — Output Contract 検証
4. `engine/facet-loader.md` — Facet 解決（composer.md が使う）

## 入力

- `stage`: Stage 定義オブジェクト（YAML の 1 stage 分）
- `input`: 変数展開済みの入力テキスト（Orchestrator が展開済み）
- `permission`: 権限モード
- `timeout`: タイムアウト秒
- `dryRun`: boolean
- `runDir`: ランディレクトリパス（run-recorder 用）

## Kind 別の実行フロー

### kind: task

```
1. Composer に stage.facets を渡してプロンプトを合成する
   → { systemPrompt, userMessage, sourceFiles }

2. userMessage の末尾に入力を追記する:
   ---
   ## Input
   {input}

3. run-recorder.recordStage(runDir, stage.id, { prompt: userMessage })

4. Dispatcher に単発実行を依頼する:
   → agentOutput (文字列)

5. run-recorder.recordStage(runDir, stage.id, { response: agentOutput })

6. output_contract がある場合:
   a. contracts.md の手順で検証する
   b. 成功 → extracted を返す
   c. ContractViolation →
      - リトライカウント < 2 なら同じプロンプトで再度 Step 4 から
      - リトライカウント >= 2 なら StageFailure エラー

7. output_contract がない場合:
   agentOutput をそのまま返す
```

### kind: fan_out

```
1. stage.from を input から取得する（配列であること）
   配列でなければ SchemaError

2. 配列の各要素 element に対して:
   a. fan_out の as 変数に element をバインド
   b. Composer に stage.facets を渡してプロンプトを合成する
   c. userMessage の末尾に入力を追記する:
      ---
      ## Input
      {element の内容}
   d. run-recorder.recordStage(runDir, "{stage.id}-{index}", { prompt: userMessage })

3. 全プロンプトを Dispatcher に並列実行で渡す:
   → outputs[] (文字列の配列)

4. 各 output に対して:
   a. run-recorder.recordStage(runDir, "{stage.id}-{index}", { response: output })
   b. output_contract がある場合は検証する

5. エラー処理:
   - on_error == "fail" (デフォルト): 1つでも失敗 → StageFailure
   - on_error == "continue": 成功分のみ配列に含めて返す

6. 全結果を配列として返す → ${stage.id}.outputs で参照可能
```

### kind: fan_in

```
1. stage.from を input から取得する（配列であること）

2. 配列を整形して userMessage に "## 統合対象" として追記する:
   各要素に見出しを付与:

   ## 統合対象

   ### Item 1
   {outputs[0] の内容}

   ### Item 2
   {outputs[1] の内容}

   ...

3. Composer に stage.facets を渡してプロンプトを合成する

4. userMessage の末尾に整形済み統合対象を追記する

5. 以降は kind: task の Step 3〜7 と同じ
```

## loop_until 処理

**task kind のみ対応。** fan_out / fan_in で loop_until があれば SchemaError。

```
iteration = 1
loop:
  1. 上記 kind: task の Step 1〜7 を実行する
  2. output_contract の extracted から self 変数にバインドする
     例: extracted = { grade: "B" } → self.grade = "B"
  3. stage.loop_until の条件を評価する:
     a. 変数展開（self.X を実値に置換）
     b. 比較演算を実行:
        - 文字列比較: `<`, `>`, `>=`, `<=`, `==`, `!=`
        - 順序: S > A+ > A > B > C（成績型の場合）
     c. true → ループ終了、最新の output を返す
     d. false → iteration += 1

  4. iteration > max_iterations の場合:
     最新の output を返すが、フラグ loop_exhausted=true を付与する

end loop
```

## 比較演算の詳細

`when` / `loop_until` の条件式は以下の形式のみ対応:

```
${variable} operator 'value'
```

operator: `<`, `>`, `>=`, `<=`, `==`, `!=`

文字列の大小比較は以下の成績順序を使う:
`S > A+ > A > B > C`

例: `${review.output.grade} < 'A'` は grade が B または C のとき true。
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/engine/stage-runner.md
git commit -m "feat(mosaic-orch): add stage-runner module (L3)"
```

---

## Task 9: engine/orchestrator.md

**Files:**
- Create: `skills/mosaic-orch/engine/orchestrator.md`

- [ ] **Step 1: orchestrator.md を作成**

```markdown
# Orchestrator — mosaic-orch (L2)

Workflow 状態機械。SKILL.md (L1) から呼ばれ、Stage の順序制御を行う。

## あなたの責務

Workflow YAML を読み込み、状態機械に従って Stage を順に実行する。
**Facet 合成方法もサブエージェント起動方法も知らない。** Stage Runner(L3) に委譲する。
**自分では作業しない。** Stage の実行、検証、ログ記録は全て下位モジュールに委譲する。

## 事前読み込み

以下を **Read tool で読み込む**:
1. `engine/yaml-schema.md` — YAML スキーマ仕様
2. `engine/stage-runner.md` — Stage 実行
3. `engine/variable-resolver.md` — 変数展開
4. `engine/run-recorder.md` — ログ記録

## 入力（SKILL.md から受け取る）

- `workflowPath`: YAML ファイルパス
- `inputs`: ユーザー入力テキスト
- `permission`: 権限モード（`"default"` | `"acceptEdits"` | `"bypassPermissions"`）
- `dryRun`: boolean

## 状態機械

```
[INIT] → [RESOLVE_STAGE] → [CHECK_WHEN] → [RUN_STAGE] → [CHECK_LOOP] → [ADVANCE] → [COMPLETE]
                                   ↓ false                                    ↑
                                 [SKIP] ───────────────────────────────────────┘
エラー発生時 → [ABORT]
```

## 手順

### INIT

1. workflowPath を Read して YAML をパースする
2. yaml-schema.md の静的検証ルール（V1〜V11）を全て実行する
   - 1 つでも失敗 → ABORT（SchemaError）
3. inputs をパースする:
   - workflow.inputs 定義がある場合: required チェック
   - 定義がない場合: 入力テキスト全体を `workflow.inputs.task` としてバインド
4. 変数コンテキストを初期化する:
   ```
   context = {
     workflow: { inputs: { task: "...", ... } }
   }
   ```
5. run-recorder.initRun() を呼ぶ → runDir を取得
6. stageIndex = 0 に設定
7. stages 配列を取得

→ [RESOLVE_STAGE] に進む

### RESOLVE_STAGE

1. stageIndex >= stages.length なら → [COMPLETE]
2. currentStage = stages[stageIndex]
3. currentStage 内の全変数参照（input, when, loop_until）を variable-resolver で展開する
   - VariableUnresolved → ABORT
4. run-recorder.recordEvent(runDir, { event: "stage_start", stage_id: currentStage.id })

→ [CHECK_WHEN] に進む

### CHECK_WHEN

1. currentStage.when が未定義 → [RUN_STAGE] に進む
2. when 条件を評価する（stage-runner.md の比較演算ルールを使う）
3. true → [RUN_STAGE] に進む
4. false → [SKIP] に進む

### SKIP

1. run-recorder.recordEvent(runDir, { event: "stage_skip", stage_id: currentStage.id, reason: "when=false" })
2. → [ADVANCE] に進む

### RUN_STAGE

1. stage-runner に委譲する:
   ```
   stageRunner.run(
     stage: currentStage,
     input: 展開済み input,
     permission: currentStage.permission || defaults.permission || permission,
     timeout: currentStage.timeout || defaults.timeout,
     dryRun: dryRun,
     runDir: runDir
   )
   ```
2. 結果を受け取る:
   - 成功 → output を context に追加:
     - task/fan_in: `context[stage.id] = { output: result }`
     - fan_out: `context[stage.id] = { outputs: resultArray }`
   - StageFailure → ABORT

3. run-recorder.recordEvent(runDir, { event: "stage_complete", stage_id: currentStage.id })

→ [CHECK_LOOP] に進む（stage-runner が loop_until を内部処理するため、Orchestrator レベルでは loop はない）

### CHECK_LOOP

loop_until は stage-runner 内部で処理される。Orchestrator はこの状態を通過するだけ。

- result に loop_exhausted=true がある場合:
  run-recorder.recordEvent(runDir, { event: "loop_exhausted", stage_id: currentStage.id })

→ [ADVANCE] に進む

### ADVANCE

1. stageIndex += 1
2. → [RESOLVE_STAGE] に戻る

### COMPLETE

1. 最後に成功した Stage の output を final output とする
2. run-recorder.recordFinal(runDir, finalOutput)
3. run-recorder.recordEvent(runDir, { event: "complete", final_stage: lastStageId })
4. ユーザーに報告:
   ```
   ✅ COMPLETE
   Workflow: {name}
   Stages executed: {実行された stage id のリスト}
   Trace: {runDir}
   ```
5. final output のサマリーを表示する

### ABORT

1. run-recorder.recordEvent(runDir, { event: "abort", stage_id: currentStage.id, error: errorType })
2. ユーザーに報告:
   ```
   ❌ ABORT
   Workflow: {name}
   Failed stage: {stage_id} (iteration {i} of {max})
   Error: {error_type}
   Details: {human_readable_detail}

   Trace: {runDir}
   最終成功Stage: {last_ok_stage_id} (成果物あり)
   ```
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/engine/orchestrator.md
git commit -m "feat(mosaic-orch): add orchestrator module (L2)"
```

---

## Task 10: サンプル Facets（radio-script 用）

**Files:**
- Create: 15 facet files under `skills/mosaic-orch/facets/`

- [ ] **Step 1: Persona facets を作成**

`skills/mosaic-orch/facets/personas/radio-planner.md`:
```markdown
---
name: radio-planner
description: ラジオ番組の企画構成を担当するプランナー
---

あなたはラジオ番組の構成作家です。

リスナーが楽しめるコーナー構成を企画します。以下を心がけてください:
- お題から3〜5個のコーナーに分解する
- 各コーナーに明確なテーマと想定尺（分）を設定する
- 全体の流れとして起承転結のリズムを意識する
- オープニングとエンディングは必ず含める
```

`skills/mosaic-orch/facets/personas/radio-writer.md`:
```markdown
---
name: radio-writer
description: ラジオ台本のコーナー執筆を担当する作家
---

あなたはラジオ番組の台本作家です。

1つのコーナーの台本を書きます。以下を心がけてください:
- パーソナリティのセリフは自然な話し言葉で書く
- 「（笑）」「（間）」などの演出指示を適宜入れる
- リスナーへの問いかけや参加を促す要素を盛り込む
- 想定尺に収まるボリュームで書く（1分 ≒ 300文字目安）
```

`skills/mosaic-orch/facets/personas/editor.md`:
```markdown
---
name: editor
description: 複数の原稿を1つの完成品に統合する編集者
---

あなたは経験豊富な編集者です。

複数の原稿や素材を受け取り、1つの一貫した完成品に仕上げます。以下を心がけてください:
- 全体の流れが自然になるように接続部分を調整する
- トーンや文体の統一を図る
- 冗長な部分を削り、足りない部分を補う
- 完成品として独立して読めるようにする
```

`skills/mosaic-orch/facets/personas/reviewer.md`:
```markdown
---
name: reviewer
description: 成果物を複数の評価軸で採点するレビューワー
---

あなたは厳格だが公正なレビューワーです。

成果物を複数の評価軸（Rubrics）で採点します。以下を心がけてください:
- 各軸を独立に評価する（1つの軸の印象が他に影響しないように）
- 必ず具体的な根拠（引用）を添える
- 改善提案は実行可能で具体的なものにする
- 全体評価は各軸の最低値に引きずられるように（最弱リンク方式）
```

- [ ] **Step 2: Policy, Knowledge facets を作成**

`skills/mosaic-orch/facets/policies/tone-casual.md`:
```markdown
---
name: tone-casual
description: カジュアルな口語調を維持するポリシー
---

# トーンポリシー: カジュアル

- 「です・ます」調ではなく「だ・である」調、または話し言葉を使う
- 専門用語を使う場合は直後にかみ砕いた説明を入れる
- 硬い表現を避け、リスナーに語りかけるように書く
- ただし品位は保つ（下品な表現・差別的表現は禁止）
```

`skills/mosaic-orch/facets/knowledge/broadcast-format.md`:
```markdown
---
name: broadcast-format
description: ラジオ番組のフォーマットに関する前提知識
---

# ラジオ番組フォーマット

## 基本構成
- オープニング（1-2分）: 挨拶、今回のテーマ紹介
- コーナー1〜3（各3-5分）: メインコンテンツ
- エンディング（1-2分）: まとめ、次回予告

## 台本記法
- 【パーソナリティ名】: セリフ
- （SE: 効果音の説明）
- （BGM: 楽曲指定）
- （間）: 意図的な沈黙
- ＞ ナレーション

## 想定尺
- 1コーナー = 3〜5分 = 900〜1500文字
- 全体 = 15〜20分
```

- [ ] **Step 3: Instruction facets を作成**

`skills/mosaic-orch/facets/instructions/plan-corners.md`:
```markdown
---
name: plan-corners
description: お題からコーナー構成を企画する指示
---

# 指示: コーナー企画

与えられたお題を分析し、ラジオ番組のコーナー構成を企画してください。

## 出力フォーマット

## Corners

以下の形式で3〜5個のコーナーを出力してください:

### Corner 1: {コーナー名}
- theme: {テーマの1行説明}
- duration_min: {想定分数}
- description: {コーナーの内容説明 2-3文}

### Corner 2: {コーナー名}
...

必ずオープニングとエンディングを含めてください。
```

`skills/mosaic-orch/facets/instructions/draft-corner.md`:
```markdown
---
name: draft-corner
description: 1つのコーナーの台本を執筆する指示
---

# 指示: コーナー台本執筆

与えられたコーナー情報に基づいて、ラジオ台本を執筆してください。

## 出力フォーマット

## Script

台本記法に従って、コーナーの完全な台本を出力してください:
- 【パーソナリティ】: のセリフ形式
- （SE:）（BGM:）（間）の演出指示
- 想定尺に収まるボリューム
```

`skills/mosaic-orch/facets/instructions/assemble-script.md`:
```markdown
---
name: assemble-script
description: 複数コーナーの台本を1つの完成台本に統合する指示
---

# 指示: 台本統合

複数のコーナー台本を受け取り、1つの完成した番組台本に仕上げてください。

## 作業内容
1. コーナー間の接続（つなぎのセリフ、SE、BGM）を追加する
2. 全体のトーン・テンポを統一する
3. オープニングとエンディングを番組全体に合わせて調整する
4. 全体尺が 15-20 分に収まるように調整する

## 出力フォーマット

## Script

完成した番組台本を1つのドキュメントとして出力してください。
コーナーの区切りは `---` で示してください。
```

`skills/mosaic-orch/facets/instructions/multi-axis-review.md`:
```markdown
---
name: multi-axis-review
description: Rubrics に従って多角的にレビューする指示
---

# 指示: 多角レビュー

与えられた成果物を、指定された Rubrics（評価軸）に従って採点してください。

## 手順
1. 各 Rubric を上から順に読む
2. 各 Rubric の「採点時に観察すること」に従って成果物を分析する
3. 各 Rubric の「採点段階」に照らして等級を決定する
4. 必ず具体的な引用（evidence）を添える
5. 改善提案（suggestions）を 0-3 個添える
6. 全軸の最低等級を全体の Grade とする

## 出力フォーマット

## Grade
{S|A+|A|B|C}

## Axes
### {軸名1}
- grade: {等級}
- evidence: {根拠の引用}
- suggestions: {改善提案}

### {軸名2}
...

## Evidence
{全体の根拠まとめ}

## Suggestions
- {改善提案1}
- {改善提案2}
```

`skills/mosaic-orch/facets/instructions/apply-suggestions-and-self-assess.md`:
```markdown
---
name: apply-suggestions-and-self-assess
description: レビュー指摘を反映し、自己採点も行う指示
---

# 指示: 修正 + 自己採点

レビューの指摘事項を踏まえて成果物を修正し、修正後の品質を Rubrics に従って自己採点してください。

## 手順
1. レビューの Suggestions を1つずつ確認する
2. 各 Suggestion に対応する箇所を特定し、修正を適用する
3. 修正後の成果物全体を通読する
4. 指定された Rubrics に従って自己採点する（multi-axis-review と同じ手順）
5. 全軸の最低等級を全体の Grade とする

## 出力フォーマット

## Script
{修正後の完成台本}

## Grade
{S|A+|A|B|C}

## Evidence
{自己採点の根拠}

## Suggestions
- {残存する改善余地があれば}
```

- [ ] **Step 4: Rubric facets を作成**

`skills/mosaic-orch/facets/rubrics/clarity.md`:
```markdown
---
name: clarity
description: 読み手への伝達のクリアさを評価する
---

# 評価軸: Clarity（伝達の明晰さ）

## 採点段階
- S: 再読不要。1度で伝わる
- A+: ほぼ1度で伝わるが、極めて細かい引っかかりが1箇所
- A: 小さな引っかかりあり。8割の読者に1度で伝わる
- B: 2回読まないと伝わらない箇所が3つ以上
- C: 前提知識が足りず、伝わらない

## 採点時に観察すること
- 主語と述語の対応
- 専門用語の説明の有無
- 指示代名詞の曖昧さ
- 文の長さ（1文50文字超は要注意）

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠を1-3個の具体的引用で>
suggestions: <改善提案を0-3個>
```

`skills/mosaic-orch/facets/rubrics/humor.md`:
```markdown
---
name: humor
description: ユーモアの質と量を評価する
---

# 評価軸: Humor（ユーモア）

## 採点段階
- S: 声を出して笑える箇所が2つ以上。ボケとツッコミのテンポが完璧
- A+: 笑える箇所が1つ以上。全体的にクスッとできる
- A: くすりとする箇所がある。真面目すぎない
- B: ユーモアの意図はあるが空振りしている
- C: 全編真面目。または不快なユーモア

## 採点時に観察すること
- ボケの種類（言葉遊び、例え、誇張、自虐）
- ツッコミのテンポ
- リスナーとの距離感
- 不快・差別的でないか

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠を1-3個の具体的引用で>
suggestions: <改善提案を0-3個>
```

`skills/mosaic-orch/facets/rubrics/pace.md`:
```markdown
---
name: pace
description: テンポとリズムの適切さを評価する
---

# 評価軸: Pace（テンポ）

## 採点段階
- S: 一定のリズムに緩急があり、飽きない。尺も適切
- A+: テンポが良く、ほぼ飽きない
- A: 大筋のテンポは良いが、中だるみが1箇所
- B: 冗長な部分が目立つ、または急ぎすぎ
- C: 全体的に単調、または支離滅裂

## 採点時に観察すること
- コーナー間の長さのバランス
- 1つのコーナー内の展開スピード
- 繰り返し・冗長の有無
- つなぎの自然さ

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠を1-3個の具体的引用で>
suggestions: <改善提案を0-3個>
```

`skills/mosaic-orch/facets/rubrics/accuracy.md`:
```markdown
---
name: accuracy
description: 情報の正確性と事実確認を評価する
---

# 評価軸: Accuracy（正確性）

## 採点段階
- S: 全ての情報が正確。出典が明示されている
- A+: 情報が正確。出典の明示は一部
- A: 明らかな誤りはないが、曖昧な表現が1-2箇所
- B: 事実誤認または根拠のない断定が1箇所
- C: 事実誤認が複数、または誤解を招く表現が多い

## 採点時に観察すること
- 固有名詞・数値・日付の正確性
- 断定と推測の区別
- 「みんな」「必ず」などの過度な一般化
- 出典・根拠の有無

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠を1-3個の具体的引用で>
suggestions: <改善提案を0-3個>
```

- [ ] **Step 5: Commit**

```bash
git add skills/mosaic-orch/facets/
git commit -m "feat(mosaic-orch): add radio-script sample facets (personas, policies, knowledge, instructions, rubrics)"
```

---

## Task 11: サンプル Contracts

**Files:**
- Create: 5 contract files under `skills/mosaic-orch/contracts/`

- [ ] **Step 1: 全 contract ファイルを作成**

`skills/mosaic-orch/contracts/corner-plan.md`:
```markdown
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
```

`skills/mosaic-orch/contracts/corner-draft.md`:
```markdown
---
name: corner-draft
description: コーナー原稿の出力契約
---

# Output Contract: corner-draft

## 期待形式
"## Script" 見出しの下に台本テキストが続く。

## パース規則（エンジンが抽出）
- script: "## Script" から次の "##" 見出しまたはファイル末尾までのテキスト

## 検証項目
- script が空でないこと（必須）
- script が 100 文字以上であること（必須）
```

`skills/mosaic-orch/contracts/full-script.md`:
```markdown
---
name: full-script
description: 完成台本の出力契約
---

# Output Contract: full-script

## 期待形式
"## Script" 見出しの下に完成した番組台本が続く。

## パース規則（エンジンが抽出）
- script: "## Script" から次の "##" 見出しまたはファイル末尾までのテキスト

## 検証項目
- script が空でないこと（必須）
- script が 500 文字以上であること（必須）
```

`skills/mosaic-orch/contracts/review-verdict.md`:
```markdown
---
name: review-verdict
description: 多角レビューの総合判定
---

# Output Contract: review-verdict

## 期待形式
"## Grade" 見出しの直下に S/A+/A/B/C のいずれか。
"## Evidence" に根拠。"## Suggestions" に改善提案。

## パース規則（エンジンが抽出）
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- evidence: "## Evidence" から "## Suggestions" までのテキスト
- suggestions: "## Suggestions" から末尾まで、箇条書きを配列化

## 検証項目
- grade が正規表現にマッチすること（必須）
- evidence が空でないこと（必須）
- suggestions の件数が 0〜5 の範囲（推奨）
```

`skills/mosaic-orch/contracts/polished-verdict.md`:
```markdown
---
name: polished-verdict
description: 修正後の台本 + 自己採点の出力契約
---

# Output Contract: polished-verdict

## 期待形式
"## Script" に修正後台本。"## Grade" に自己採点。
"## Evidence" に根拠。"## Suggestions" に残存改善余地。

## パース規則（エンジンが抽出）
- script: "## Script" から "## Grade" までのテキスト
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- evidence: "## Evidence" から "## Suggestions" までのテキスト
- suggestions: "## Suggestions" から末尾まで、箇条書きを配列化

## 検証項目
- script が空でないこと（必須）
- script が 500 文字以上であること（必須）
- grade が正規表現にマッチすること（必須）
- evidence が空でないこと（必須）
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/contracts/
git commit -m "feat(mosaic-orch): add radio-script sample contracts"
```

---

## Task 12: サンプル Workflow YAML

**Files:**
- Create: `skills/mosaic-orch/workflows/radio-script.yaml`

- [ ] **Step 1: radio-script.yaml を作成**

```yaml
name: radio-script
version: "1"
description: お題からラジオ台本を生成、多角レビューで A+ まで磨く

inputs:
  - name: topic
    type: string
    required: true

defaults:
  permission: acceptEdits

stages:
  - id: plan
    kind: task
    facets:
      persona: radio-planner
      knowledge: [broadcast-format]
      instructions: [plan-corners]
    input: ${workflow.inputs.topic}
    output_contract: corner-plan

  - id: draft
    kind: fan_out
    from: ${plan.output.corners}
    as: corner
    facets:
      persona: radio-writer
      policies: [tone-casual]
      instructions: [draft-corner]
    input: ${corner}
    output_contract: corner-draft

  - id: assemble
    kind: fan_in
    from: ${draft.outputs}
    facets:
      persona: editor
      instructions: [assemble-script]
    output_contract: full-script

  - id: review
    kind: task
    facets:
      persona: reviewer
      rubrics: [clarity, humor, pace, accuracy]
      instructions: [multi-axis-review]
    input: ${assemble.output}
    output_contract: review-verdict

  - id: polish
    kind: task
    when: ${review.output.grade} < 'A'
    facets:
      persona: editor
      rubrics: [clarity, humor, pace, accuracy]
      instructions: [apply-suggestions-and-self-assess]
    input: ${assemble.output}
    loop_until: ${self.grade} >= 'A'
    max_iterations: 3
    output_contract: polished-verdict
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/workflows/radio-script.yaml
git commit -m "feat(mosaic-orch): add radio-script sample workflow"
```

---

## Task 13: エラーハンドリング リファレンス

**Files:**
- Create: `skills/mosaic-orch/references/error-handling.md`

- [ ] **Step 1: error-handling.md を作成**

```markdown
# Error Handling Reference — mosaic-orch

## エラー分類

| エラー名 | 発生層 | 原因 | 対応 |
|---|---|---|---|
| SchemaError | L2 INIT | YAML不正、必須フィールド欠落、型不一致 | 即ABORT。YAML修正を案内 |
| VariableUnresolved | L2 RESOLVE | ${...}参照先不在 | 即ABORT。利用可能な変数キーを報告 |
| FacetNotFound | L4 Composer | facets/{kind}/{name}.md 不在 | 即ABORT。検索パスを報告 |
| DispatchTimeout | L5 Dispatcher | Task tool 応答なし | 1回リトライ → 失敗でStageFailure |
| ContractViolation | Contracts | 出力が契約を満たさない | 2回同Stage再実行 → 失敗でStageFailure |
| StageFailure | L3 | 上記いずれかの伝播 | loop_untilあればループ、なければABORT |
| LoopExhausted | L3 | max_iterations到達 | フラグ付きで次Stage。ABORTしない |

## ABORT テンプレート

```
❌ ABORT
Workflow: {name}
Failed stage: {stage_id} (iteration {i} of {max})
Error: {error_type}
Details: {human_readable_detail}

Trace: .mosaic-orch/runs/{slug}/
最終成功Stage: {last_ok_stage_id}
```

## ContractViolation のデバッグ

1. `.mosaic-orch/runs/{slug}/stages/{stage_id}/response.md` を確認
2. 期待形式と実出力を比較
3. よくある原因:
   - サブエージェントが見出し形式を間違えている（`## Grade` vs `# Grade`）
   - 箇条書きのプレフィックスが違う（`- ` vs `* `）
   - 空行が足りない
4. 対策: instruction facet に出力フォーマットをより明示的に記載する
```

- [ ] **Step 2: Commit**

```bash
git add skills/mosaic-orch/references/error-handling.md
git commit -m "docs(mosaic-orch): add error handling reference"
```

---

## Task 14: インストールと Dry-run 検証

**Files:**
- Create: symlink `~/.claude/skills/mosaic-orch`

- [ ] **Step 1: シンボリックリンクでインストール**

```bash
ln -sfn /home/itoshun/works/claude-skills-org/skills/mosaic-orch ~/.claude/skills/mosaic-orch
ls -la ~/.claude/skills/mosaic-orch
```

Expected: symlink が作成され、SKILL.md が見える

- [ ] **Step 2: Dry-run で静的検証を確認**

```
/mosaic-orch radio-script --dry-run テスト用お題
```

Expected:
- YAML パースが成功する
- 全 facet ファイルが見つかる（FacetNotFound なし）
- 全 contract ファイルが見つかる
- Stage trace が `.mosaic-orch/runs/DRYRUN-*/` に生成される
- 各 stage の prompt.md が生成される

- [ ] **Step 3: Dry-run 結果を確認**

```bash
ls .mosaic-orch/runs/DRYRUN-*/stages/
cat .mosaic-orch/runs/DRYRUN-*/stages/plan/prompt.md | head -30
```

Expected: plan, draft, assemble, review, polish のディレクトリと prompt.md がある

- [ ] **Step 4: 問題があれば修正してコミット**

---

## Task 15: ウォークスルーと最終コミット

**Files:**
- Create: `skills/mosaic-orch/examples/radio-script-walkthrough.md`

- [ ] **Step 1: ウォークスルーを作成**

```markdown
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
```

- [ ] **Step 2: 最終コミット**

```bash
git add skills/mosaic-orch/examples/
git commit -m "docs(mosaic-orch): add radio-script walkthrough example"
```

- [ ] **Step 3: 全ファイルの存在確認**

```bash
find skills/mosaic-orch -type f | sort
```

Expected: SKILL.md, engine/*.md (9 files), facets/**/*.md (15 files), contracts/*.md (5 files), workflows/*.yaml (1), examples/*.md (1), references/*.md (1) = 33 files total

- [ ] **Step 4: 最終 push**

```bash
git push origin main
```

---

## Self-Review Checklist

- [x] Spec coverage: 全6セクション（アーキテクチャ、5Facet、YAMLスキーマ、エンジン動作、ファイル構造、エラー処理）がタスクでカバーされている
- [x] Placeholder scan: TBD/TODO なし。全タスクに具体的なファイル内容を記載
- [x] Type consistency: facets の YAML キー名（rubrics, policies, instructions, knowledge）が全ファイルで統一。Contract 名（corner-plan, corner-draft, full-script, review-verdict, polished-verdict）が workflow YAML と全 contract ファイルで一致
- [x] 依存方向: Task 順序がボトムアップ（foundation → bottom-layer → upper-layer → assets → validation）に沿っており、各 engine ファイル内の参照が一方向
