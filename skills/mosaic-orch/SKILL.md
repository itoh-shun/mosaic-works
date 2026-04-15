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

### 開発系workflowの選び方（速度 vs 堅牢性）

| Workflow | ステージ数 | 想定所要 | 想定タスク規模 |
|---|---|---|---|
| `dev-light` | 8 | 〜20分 | 単一機能・bugfix・小規模リファクタ。Wave分けなし、design-review/plan-review/arbitrate/5軸review/UI verifyを省略 |
| `dev-standard` | 15 | 30〜45分 | FE+BE複合、3〜5サブタスク。design-review/plan-review/arbitrate/UI verifyを省略、5軸reviewは残す。max_parallel=8 |
| `dev-orchestration` | 20 | 60〜90分 | 大規模・多領域・厳格品質要求。全レビュー層・arbitrate・UI verify・design/plan review loopあり |

タスクの規模・品質要求に応じて使い分ける。迷ったら `dev-standard` から始める。

### 自動マッピング（workflow省略時）

第1トークンが**既存workflow名でも `/` を含むパスでも `--` フラグでもない**場合、入力テキスト全体を「開発タスク」として扱い、軽量分析で **dev-light / dev-standard / dev-orchestration** のいずれかを自動選択する。

例:
- `/mosaic-orch ログイン画面の余白を直す` → 自動判定 → `dev-light`
- `/mosaic-orch ユーザー一覧画面に検索とソートを追加` → 自動判定 → `dev-standard`
- `/mosaic-orch Instagram風SNSをフルスタックで新規構築` → 自動判定 → `dev-orchestration`

#### 自動判定ルール（SKILL.md 内で評価する）

入力テキストに対して以下を順に評価し、最初にマッチした結果を採用する:

| 優先 | 判定条件 | 選定workflow |
|---|---|---|
| 1 | 以下のいずれかを含む: 「新規」「フルスタック」「ゼロから」「アーキテクチャ」「monorepo」「new project」「from scratch」「architecture」「fullstack」「greenfield」、または入力が **800文字以上** | `dev-orchestration` |
| 2 | FE系キーワード（「FE」「フロントエンド」「画面」「UI」「コンポーネント」「ダッシュボード」「frontend」「screen」「component」「dashboard」「page」）の **いずれか** かつ BE系キーワード（「API」「BE」「バックエンド」「DB」「エンドポイント」「backend」「database」「endpoint」「route」「migration」）の **いずれか** を含む（FE+BE複合）、または **複数機能の連結**（「と」「および」「+」「,」「and」「plus」で機能を列挙）、または入力が **200文字以上** | `dev-standard` |
| 3 | 上記いずれにも該当しない（短文・単一機能・bugfix系キーワード「直す」「修正」「リネーム」「typo」「改名」「fix」「rename」「tweak」「adjust」「polish」などを含む） | `dev-light` |

#### 自動選択時のユーザー確認

自動マッピングが発動した場合、Orchestrator に委譲する**前に** AskUserQuestion で確認する:

```
🤖 タスクを分析しました。

入力: 「{先頭150文字}」
判定: dev-standard
理由: {マッチしたルールの説明、例: "FE+BE複合の表現を検出"}

このまま実行しますか？
1. 続行（dev-standard で実行）
2. dev-light に変更（〜20分の軽量モード）
3. dev-orchestration に変更（60〜90分の厳格モード）
4. 中断
```

ユーザーが「2」「3」を選んだ場合は workflow を差し替えて続行する。「4」なら即終了。

#### 自動マッピングを無効化したいとき

明示的に workflow 名を指定すれば自動マッピングは発動しない:
- `/mosaic-orch dev-light タスク内容` — light を強制
- `/mosaic-orch dev-orchestration タスク内容` — heavy を強制
- `/mosaic-orch radio-script ...` — 開発系以外も従来通り

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
3. 見つからない場合 → **自動マッピング判定**へ進む（下記）

#### 自動マッピング判定（手順 1.5）

第1トークンが workflow として解決できなかった場合、**`/mosaic-orch {タスク文}` 形式の省略呼び出し**として扱い、$ARGUMENTS 全体を `task` として以下を実行する:

1. `task` テキストを上記「自動マッピング」セクションの判定ルールで評価し、`dev-light` / `dev-standard` / `dev-orchestration` のいずれかを選定する
2. 判定理由（マッチしたルール）を記録する
3. AskUserQuestion で確認画面（上記「自動選択時のユーザー確認」のテンプレート）を表示する
4. ユーザー選択に応じて workflow を確定する:
   - 「1. 続行」 → 自動判定の workflow を採用
   - 「2. dev-light に変更」 → `dev-light` を採用
   - 「3. dev-orchestration に変更」 → `dev-orchestration` を採用
   - 「4. 中断」 → 即終了
5. 確定した workflow を `~/.claude/skills/mosaic-orch/workflows/{name}.yaml` から Read して、手順 2 へ進む
6. inputs バインド時、$ARGUMENTS 全体を `workflow.inputs.task` に渡す（第1トークンも含む）

**注意**: 自動マッピングが発動するのは第1トークンが「workflow解決失敗」かつ「`--`フラグでない」かつ「ファイルパスでない」場合のみ。明示的に workflow 名を指定した場合（例: `dev-light`）は自動マッピングをスキップして通常通り実行する。

### 手順 2: Orchestrator に委譲

`engine/orchestrator.md` の手順に従って実行を開始する。以下を渡す:
- workflow YAML ファイルパス
- ユーザー入力(inputs)
- 権限モード(permission)
- dry-run フラグ

### 手順 3: 結果報告

orchestrator.md が COMPLETE を返したら、結果のサマリーをユーザーに報告する。
ABORT の場合は失敗理由を報告する（engine/orchestrator.md のABORT報告テンプレートに従う）。
