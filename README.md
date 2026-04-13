# mosaic-works

[mosaic-orch](skills/mosaic-orch/) — Facet ベースの SoC オーケストレーション Skill for Claude Code.

## mosaic-orch とは

プロンプトの関心を 5 つの Facet に分離し、宣言的 YAML ワークフローでマルチエージェントオーケストレーションを行う Claude Code Skill です。

[faceted-prompting](https://github.com/nrslib/faceted-prompting) の Facet 分類 (Persona / Policy / Knowledge / Instruction) の**考え方を参考**に、独自のエンジンと YAML スキーマを設計しています。faceted-prompting パッケージ自体への依存はありません。

### 5 Facet

| Facet | 役割 | プロンプト配置 |
|---|---|---|
| **Persona** | WHO — 実行者の同一性 | system プロンプト |
| **Policy** | HOW — 実行中の行動規範 | user メッセージ |
| **Knowledge** | WHAT TO KNOW — 前提知識 | user メッセージ |
| **Instruction** | WHAT TO DO — やるべきこと | user メッセージ |
| **Rubric** | HOW TO BE JUDGED — 評価基準 | user メッセージ (末尾) |

Rubric は mosaic-orch 独自の拡張です。Policy (実行中の行動規範) と Rubric (評価時の採点基準) を SoC で分離することで、同じ Rubric をレビュー Stage と修正 Stage で再利用できます。

### 3 つのオーケストレーション機能

1. **Stage + Output Contract** — 工程の関心を分離し、Stage 境界で出力型を強制
2. **Fan-out / Fan-in** — 1 タスクを N 分解 → 並列実行 → 統合
3. **Dynamic Facet Reference** — `${...}` で実行時に Facet を動的選択

## Workflows

| Workflow | 用途 | Stages |
|---|---|---|
| `tech-article` | 技術記事の執筆 | research → outline → draft(fan_out) → assemble(fan_in) → review → polish |
| `dev-orchestration` | 開発オーケストレーション | analyze → setup-git → implement(fan_out) → integrate(fan_in) → quality-gate → review → fix → finalize |

## Install

```bash
git clone https://github.com/itoh-shun/mosaic-works.git && \
ln -sfn "$(pwd)/mosaic-works/skills/mosaic-orch" ~/.claude/skills/mosaic-orch
```

<details>
<summary>既にclone済みの場合</summary>

```bash
ln -sfn /path/to/mosaic-works/skills/mosaic-orch ~/.claude/skills/mosaic-orch
```

</details>

Claude Code を再起動すると `/mosaic-orch` が使えるようになります。

## Usage

```bash
# 技術記事を書く
/mosaic-orch tech-article Reactの新しいuse()フックの使い方

# 開発タスクを実行
/mosaic-orch dev-orchestration ソート機能をユーザー一覧に追加

# 新しいワークフローを作る
/mosaic-orch --new-workflow

# Dry-run (プロンプト確認のみ)
/mosaic-orch tech-article --dry-run テスト

# ワークフロー一覧 / Facet逆引き
/mosaic-orch --list-workflows
/mosaic-orch --facet-usage
```

## アーキテクチャ

5 層構造。依存は一方向。

```
L1: SKILL.md (Entry)
L2: engine/orchestrator.md (状態機械)
L3: engine/stage-runner.md (Stage 実行)
L4: engine/composer.md (Facet 合成)
L5: engine/dispatcher.md (Task tool)
```

横断モジュール: contracts, facet-loader, variable-resolver, run-recorder, yaml-schema

## ディレクトリ構造

```
skills/mosaic-orch/
├── SKILL.md                    # エントリポイント
├── engine/                     # エンジン (9 modules)
├── facets/
│   ├── personas/               # WHO
│   ├── policies/               # HOW
│   ├── knowledge/              # WHAT TO KNOW
│   ├── instructions/           # WHAT TO DO
│   └── rubrics/                # HOW TO BE JUDGED
├── contracts/                  # Output Contract 定義
├── workflows/                  # Workflow YAML
├── examples/                   # ウォークスルー
└── references/                 # リファレンス
```

## Workflow YAML の書き方

```yaml
name: my-workflow
version: "1"
inputs:
  - name: task
    type: string
    required: true

stages:
  - id: plan
    kind: task
    facets:
      persona: planner
      instructions: [plan-task]
    input: ${workflow.inputs.task}
    output_contract: task-plan

  - id: execute
    kind: fan_out
    from: ${plan.output.subtasks}
    as: subtask
    facets:
      persona: ${subtask.persona}       # 動的 Facet 参照
      instructions: [${subtask.instruction}]
    input: ${subtask.description}
    output_contract: execution-result

  - id: review
    kind: task
    facets:
      persona: reviewer
      rubrics: [quality, correctness]
      instructions: [review-output]
    input: ${execute.outputs}
    output_contract: review-verdict
```

### Stage 種別

| kind | 用途 |
|---|---|
| `task` | 1 サブエージェントで 1 タスク実行 |
| `fan_out` | N 個の並列タスクに展開 |
| `fan_in` | 並列結果を 1 つに統合 |

## License

[MIT](LICENSE)
