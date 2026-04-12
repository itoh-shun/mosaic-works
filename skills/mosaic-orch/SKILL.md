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
