# mosaic-works

[mosaic-orch](skills/mosaic-orch/) — faceted-prompting の SoC 原則を拡張したドメイン非依存オーケストレーション Skill for Claude Code.

## mosaic-orch とは

[faceted-prompting](https://github.com/nrslib/faceted-prompting) の 4 Facet (Persona / Policy / Knowledge / Instruction) に **Rubric (評価基準)** を第 5 Facet として追加し、宣言的 YAML ワークフローでマルチエージェントオーケストレーションを行う Claude Code Skill です。

### 3 つのオリジナル拡張

1. **Stage + Output Contract** — 工程の関心を分離し、Stage 境界で出力型を強制
2. **Fan-out / Fan-in** — 1 タスクを関心軸で N 分解 → 並列実行 → 統合
3. **Rubric Facet** — 評価基準を Policy から分離。レビューと実装で同じ Rubric を再利用可能

## Workflow

| Workflow | 用途 | Stages |
|---|---|---|
| `radio-script` | ラジオ台本生成 (サンプル) | plan → draft(fan_out) → assemble(fan_in) → review → polish |
| `dev-orchestration` | 開発オーケストレーション (intendant移植) | analyze → check-dup → setup-git → implement(fan_out) → integrate(fan_in) → quality-gate → review → fix → ui-verify → save-results → finalize |

## Quick Start

```bash
# インストール (symlink)
ln -sfn /path/to/mosaic-works/skills/mosaic-orch ~/.claude/skills/mosaic-orch

# ラジオ台本生成
/mosaic-orch radio-script 4月の桜と花見文化について

# 開発オーケストレーション
/mosaic-orch dev-orchestration ソート機能をユーザー一覧に追加

# Dry-run (サブエージェント起動なし)
/mosaic-orch radio-script --dry-run テスト
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

## 設計ドキュメント

- [mosaic-orch 設計仕様](docs/superpowers/specs/2026-04-12-mosaic-orch-design.md)
- [dev-orchestration 設計仕様](docs/superpowers/specs/2026-04-12-dev-orchestration-design.md)

## License

[MIT](LICENSE)
