---
name: mosaic-orch
description: >
  Facetベース(persona/policy/knowledge/instruction/rubric)のドメイン非依存オーケストレーター。
  Stage/Fan-out/Fan-in/Loopをサポートする宣言的Workflow YAMLで、複数サブエージェントを合成する。
  Use when: 多段レビューループ、並列分解タスク、faceted-prompting流の構造化プロンプト実行、開発タスク(dev-orchestration workflow)。
  Not for: 単発の軽い質問、直接コーディング。
user-invocable: true
---

# Mosaic-Orch Skill

## 引数の解析

$ARGUMENTS を以下のように解析する:

```
/mosaic-orch {workflow} [--dry-run] [--permission default|acceptEdits|bypassPermissions] {inputs...}
/mosaic-orch --resume {runDir}
/mosaic-orch --new-workflow
/mosaic-orch --list-workflows
/mosaic-orch --facet-usage [{facet-kind/facet-name}]
/mosaic-orch --mosaic
```

- **第1トークン**: workflow名またはYAMLファイルパス（必須）、またはユーティリティフラグ（下記参照）
- **`--dry-run`**: プロンプト合成まで実行し、サブエージェントは起動しない
- **`--permission`**: 権限モード（任意、デフォルト: `default`）
- **`--resume {runDir}`**: ABORT/中断した run を途中から再開する
- **残りのトークン**: タスク入力（省略時は AskUserQuestion でユーザーに入力を求める）

例:
- `/mosaic-orch radio-script 4月のニュース` → radio-script WF, default権限
- `/mosaic-orch radio-script --dry-run 4月のニュース` → dry-run
- `/mosaic-orch /path/to/custom.yaml 実装して` → カスタムYAML
- `/mosaic-orch --resume .mosaic-orch/runs/20260414-153000-dev-orchestration` → 途中再開
- `/mosaic-orch --list-workflows` → 利用可能なworkflow一覧を表示
- `/mosaic-orch --facet-usage` → 全facetの使用状況を逆引き表示
- `/mosaic-orch --facet-usage personas/reviewer` → reviewer persona を使うworkflowを表示

### ユーティリティコマンド

第1トークンが以下のユーティリティフラグの場合、Orchestrator を呼ばずに直接処理する:

#### `--list-workflows`

利用可能な workflow を列挙して表示する。

1. 以下のディレクトリを Glob で検索する:
   - `~/.mosaic-orch/workflows/*.yaml`（ユーザーカスタム）
   - `~/.claude/skills/mosaic-orch/workflows/*.yaml`（Skill同梱）
2. 各 YAML の `name` と `description` フィールドを Read して表示する:
   ```
   利用可能な workflow:
   - radio-script    : お題からラジオ台本を生成、多角レビューで A+ まで磨く
   - tech-article    : 技術記事を調査→構成→並列執筆→統合→レビューで仕上げる
   - dev-orchestration: 開発タスクをチーム分解・並列実装・5軸レビューで品質担保して納品する
   ```

#### `--facet-usage [kind/name]`

全 workflow YAML を走査し、facet の使用状況を逆引き表示する。

引数なしの場合（全 facet サマリー）:
1. 全 workflow YAML（ビルトイン + ユーザーカスタム）を Read する
2. 各 YAML の全 stage の `facets` フィールドを走査する
3. facet 種別ごとに、「facet名 → 使用しているworkflow名と stage id」のマップを構築する
4. 以下の形式で出力する:

   ```
   ## Facet 使用状況（逆引き）

   ### personas
   | Facet | Workflow | Stage |
   |---|---|---|
   | architect | dev-orchestration | analyze, fix |
   | editor | radio-script | assemble, polish |
   | editor | tech-article | assemble, polish |
   | radio-planner | radio-script | plan |
   ...

   ### instructions
   | Facet | Workflow | Stage |
   ...

   ### policies / knowledge / rubrics
   ...
   ```

引数あり（例: `personas/reviewer`）:
1. 指定した facet に絞って同様の表示を行う
2. その facet が使われていない場合: `"personas/reviewer は現在どの workflow でも使用されていません"` と表示する

#### `--mosaic`

ワークフロー実行履歴を GitHub Contribution Graph と同じレイアウトで表示する。

1. `.mosaic-orch/mosaic.json` を Read する（存在しない場合「まだ実行履歴がありません」と表示）
2. エントリを日付ごとにグループ化し、同日に複数 run がある場合は**最高 Grade** を採用する
3. 以下のカラーマッピングでタイルを表示する:

| Grade | タイル | 意味 |
|---|---|---|
| S | 🟪 | 模範的 |
| A+ | 🟩 | 高品質 |
| A | 🟢 | 良好 |
| B | 🟡 | 可 |
| C | 🔴 | 不可 |
| N/A | 🟦 | 評価なし(レビューstageがないWF) |
| abort | ⬛ | 中断 |
| (なし) | ⬜ | 実行なし |

4. **GitHub Contribution Graph レイアウト**で表示する:

- **横軸**: 週（左=古い、右=新しい）。直近12週分を表示
- **縦軸**: 曜日（Mon〜Sun の7行）
- **各セル**: その日の最高 Grade に対応するタイル。実行なしの日は ⬜
- **月ラベル**: 週の先頭が月初を含む列の上に月名を表示

```
🧩 Mosaic
         Feb          Mar                   Apr
Mon  ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
Tue  ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
Wed  ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
Thu  ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
Fri  ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
Sat  ⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜⬜
Sun  ⬜⬜⬜🟦⬜⬜⬜⬜🟢🟢🟡⬜

 12 weeks | 4 runs | 🟢 A×2  🟡 B×1  🟦 N/A×1
 Workflows: dev-orchestration(3), tech-article(1)
 Projects: todo-api, react-dashboard, fullstack-app
```

5. **構築手順**:
   a. 今日の日付から12週前（84日前）の月曜日を `startDate` とする
   b. `startDate` から今日まで、各日に対応する mosaic.json エントリを検索する
   c. 12列（週） × 7行（曜日）のグリッドを構築する
   d. 各セルに対応する日のタイルを配置する（エントリなし → ⬜）
   e. 月が変わる列の上に月名ラベルを配置する
   f. 未来の日付のセルは空白（スペース）にする
   g. グリッドの下にサマリー行を表示する

6. **サマリー行**（グリッド下に1行空けて表示）:
   - `{weeks}週 | {totalRuns} runs | {Grade別の内訳}`
   - `Workflows: {workflow名(回数)}` — 使用された workflow の内訳
   - `Projects: {project名}` — 実行されたプロジェクト一覧（重複除去）

7. 12週より古い run がある場合: サマリーの末尾に `+ {N} older runs` と表示

### バリデーション

第1トークンがユーティリティフラグでも workflow 名/パスでもない場合、引数解析後に以下のチェックを行う。いずれかが失敗した場合は即座にエラーを表示して終了する（Orchestrator を呼ばない）。

| # | チェック項目 | エラーメッセージ |
|---|---|---|
| A1 | $ARGUMENTS が空 | `エラー: workflow名が指定されていません。\n使い方: /mosaic-orch {workflow名} [--dry-run] [--permission ...] {入力}\n利用可能なworkflow一覧: /mosaic-orch --list-workflows` |
| A2 | `--permission` の次のトークンが `default` / `acceptEdits` / `bypassPermissions` のいずれでもない | `エラー: --permission の値が不正です: "{指定値}"\n有効な値: default, acceptEdits, bypassPermissions` |
| A3 | 不明なフラグ（`--` で始まるが既知フラグ以外のトークン） | `エラー: 不明なオプション: "{フラグ}"\n使い方: /mosaic-orch {workflow名} [--dry-run] [--permission default|acceptEdits|bypassPermissions] {入力}` |

## ユーザーオーバーライド

`~/.mosaic-orch/overrides.md` を配置すると、全ワークフロー実行時にOrchestrator INIT の最初に読み込まれる。

変更可能: デフォルト permission、追加ポリシー、タイムアウト調整、workflow別カスタム挙動
変更不可: 検証ルール(V1-V16)の無効化、Stage追加/削除、Contract検証スキップ、Loop Monitor無効化

## 事前準備

手順を開始する前に、以下を **Read tool で読み込む**:
1. `engine/orchestrator.md` — 状態機械の全手順

ただし `--new-workflow` / `--list-workflows` / `--facet-usage` / `--mosaic` ユーティリティコマンドの場合は orchestrator.md の読み込みは不要。

## 手順

### 起動時モザイク表示（全コマンド共通）

**どのコマンドでも、処理を開始する前に**直近1週間のミニモザイクを1行で表示する:

1. `.mosaic-orch/mosaic.json` を Read する（存在しない場合はスキップ）
2. 今日から過去7日分（Mo〜Su）のタイルを生成し、1行で表示する:

```
🧩 Mo Tu We Th Fr Sa Su  (3 runs this week)
   ⬜ ⬜ ⬜ ⬜ ⬜ 🟢 🟩
```

- 実行なしの日は ⬜、その日の最高 Grade に対応するタイルを配置
- 全日 ⬜（実行なし）の場合: `🧩 (no runs this week)` のみ表示

3. 表示後、通常の手順に進む（表示に失敗しても処理は続行する）

### 手順 0: ユーティリティコマンドの判定

第1トークンを確認する:
- `--resume` → 第2トークンを `resumeRunDir` として取得。`{resumeRunDir}/workflow.yaml` を Read して workflowPath を復元。手順 2 へ進む（resumeRunDir を Orchestrator に渡す）
- `--new-workflow` → `engine/wizard.md` を Read し、その手順に従ってワークフロー構築ウィザードを実行して終了
- `--list-workflows` → ユーティリティコマンド「`--list-workflows`」の手順を実行して終了
- `--facet-usage` → ユーティリティコマンド「`--facet-usage`」の手順を実行して終了
- `--mosaic` → ユーティリティコマンド「`--mosaic`」の手順を実行して終了
- その他 → 手順 1 へ進む

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
