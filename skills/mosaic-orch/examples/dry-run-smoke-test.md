# Dry-run スモークテスト手順

Wave1 で追加した各ドキュメントの記述と実際のエンジン動作の整合性を確認するためのスモークテストシナリオ集。
`--dry-run` フラグを使い、サブエージェントを起動せずにエンジンの静的検証・Facet解決・プロンプト合成を検証する。

---

## テスト1: 静的検証 — V12 ガードルール

### 目的

`yaml-schema.md` の検証ルール V12「fan_out の from 配列要素数が 6 以上で `max_parallel` が未設定の場合に WARN を出す」が正しく機能することを確認する。

### 準備: テスト用 YAML の作成

以下の内容を `workflows/test-v12-guard.yaml` として一時作成する。

```yaml
name: test-v12-guard
version: "1"
description: V12ガードルールの検証用 — max_parallel未設定

stages:
  - id: spread
    kind: fan_out
    from: ${workflow.inputs.items}
    as: item
    # max_parallel を意図的に省略（from が 6 要素以上を想定）
    facets:
      persona: tech-writer
```

> **注意**: `from` が参照する配列の要素数は実行時に決まるが、静的検証（INIT）ではエンジンは YAML の宣言内容から潜在的なリスクを警告する。
> V12 ルールの条件は「from 配列要素数が 6 以上かつ `max_parallel` が未設定」だが、要素数が静的に不明な変数参照（`${workflow.inputs.items}` 等）の場合もエンジンは保守的に WARN を出力する。

### 手順

```
/mosaic-orch workflows/test-v12-guard.yaml --dry-run
```

### 期待結果

dry-run の出力コンソールに以下の WARN メッセージが含まれること:

```
WARN [V12] fan_out stage "spread": max_parallel が未設定です。
     from 配列要素数が 6 以上になる場合、並列度が無制限になりリソース枯渇のリスクがあります。
     推奨値: max_parallel: 5（dispatcher.md 参照）
```

dry-run は WARN で止まらず最後まで完了すること（WARN はエラーではない）:

```
✅ COMPLETE (dry-run)
Workflow: test-v12-guard
Stages resolved: spread
Trace: .mosaic-orch/runs/DRYRUN-{timestamp}-test-v12-guard/
```

### 失敗時の対応

| 症状 | 原因と対処 |
|---|---|
| WARN が出ない | `orchestrator.md` の INIT → 静的検証ステップで V12 チェックが実装されていない。`yaml-schema.md` の V12 ルールとの整合性を確認する |
| ABORT になる | V12 は WARN のみのルール（SchemaError ではない）。エンジンが V12 を SchemaError として扱っていれば実装誤り |
| コマンドが認識されない | workflow のパスが正しいか確認する。SKILL.md の引数解釈ロジックを確認する |

### テスト後のクリーンアップ

```bash
rm workflows/test-v12-guard.yaml
```

---

## テスト2: Facet 解決 — 全 facet が存在するか

### 目的

全 workflow YAML が参照する facet ファイルが実際に存在することを確認する（`yaml-schema.md` V6 ルール: FacetNotFound が出ないこと）。

### 手順

登録済みの全 workflow を `--dry-run` で実行する:

```
/mosaic-orch dev-orchestration --dry-run "テスト用タスク"
/mosaic-orch radio-script --dry-run "テスト"
/mosaic-orch tech-article --dry-run "テスト"
```

`FacetNotFound` エラーが出ていないことを確認する:

```bash
grep -r "FacetNotFound" .mosaic-orch/runs/DRYRUN-*/trace.ndjson
```

出力が空であれば全 facet が解決されている。

### 期待結果

各 workflow の dry-run が `✅ COMPLETE (dry-run)` で終了すること。
`trace.ndjson` に `FacetNotFound` を含むイベントがないこと。

```bash
# 全 dry-run 実行後に一括確認
grep -h "FacetNotFound" .mosaic-orch/runs/DRYRUN-*/trace.ndjson | wc -l
# → 0
```

### 失敗時の対応

| 症状 | 原因と対処 |
|---|---|
| `FacetNotFound: personas/xxx` | `facets/personas/xxx.md` が存在しないか、YAML の facet 名がファイル名と一致していない。ファイル名・パスを確認する |
| `FacetNotFound: rubrics/yyy` | `facets/rubrics/yyy.md` を確認。`--facet-usage` コマンドで逆引きして参照元の YAML を特定する (`/mosaic-orch --facet-usage rubrics/yyy`) |
| dry-run 自体が ABORT | エラー種別を `trace.ndjson` で確認し、FacetNotFound 以外のエラーを先に解消する |

---

## テスト3: Contract 検証フロー — 出力構造チェック

### 目的

dry-run 時に `stages/*/prompt.md` が生成され、Composer が出力する userMessage のセクション構造（`## Knowledge / ## Instructions / ## Policies / ## Rubrics`）が `composer.md` の仕様通りであることを確認する。

### 手順

```
/mosaic-orch dev-orchestration --dry-run "テスト用タスク"
```

生成されたランディレクトリのパスを確認する（出力末尾の `Trace:` 行）。
各 stage の `prompt.md` が生成されていることを確認する:

```bash
ls .mosaic-orch/runs/DRYRUN-{timestamp}-dev-orchestration/stages/
# 期待: analyze/  check-dup/  setup-git/  implement-wave1/  ...
```

`prompt.md` のセクション構造を確認する。Knowledge・Instructions・Policies・Rubrics の順に並び、Rubrics が末尾に固定されていることを検証する:

```bash
#例: review stage の prompt.md を確認
cat .mosaic-orch/runs/DRYRUN-{timestamp}-dev-orchestration/stages/review/prompt.md
```

### 期待結果

各 `prompt.md` が以下のセクション構造を含むこと（使用している facet のみ出力される）:

```markdown
## Knowledge

{knowledge facet の本文}

## Instructions

{instructions facet の本文}

## Policies

{policies facet の本文}

## Rubrics

{rubrics facet の本文}

---

{Input セクション（stage-runner が追記）}
## Input

{展開済み入力}
```

具体的に確認するルール:
- 空の facet グループはセクションごと省略されること（例: `knowledge` が未宣言の stage には `## Knowledge` が出ない）
- `## Rubrics` セクションは常に末尾に配置されること
- `response.md` は生成されないこと（dry-run ではサブエージェントが起動しないため）

```bash
# response.md が存在しないことを確認
ls .mosaic-orch/runs/DRYRUN-{timestamp}-dev-orchestration/stages/analyze/
# 期待: prompt.md のみ（response.md なし）
```

### 失敗時の対応

| 症状 | 原因と対処 |
|---|---|
| `stages/*/prompt.md` が生成されない | `run-recorder.md` の dry-run モード実装を確認。`prompt.md は記録する` という仕様が実装されているか確認する |
| `## Rubrics` が末尾にない | `composer.md` の「Rubrics の末尾固定」ルールの実装を確認する |
| セクション見出しが `## Knowledge` でなく別の名前 | Composer のセクション見出しは `## {Kind名}` 固定。`composer.md` の仕様と照合する |
| 空の facet グループのセクションが出力される | Composer の「空の群はセクションごと省略」ルールの実装を確認する |

---

## テスト4: 変数解決 — `${...}` 展開

### 目的

fan_out stage での動的 facet 参照（`${subtask.persona}` 等）が dry-run の `prompt.md` に正しく展開されていることを確認する。

> **注意**: dry-run では `analyze` stage のサブエージェントが実行されないため、`${analyze.output.wave1_subtasks}` のような前段 stage の出力に依存する変数は解決できない。このテストは **本実行時のみ有効**。dry-run でこれらの変数が未解決（VariableUnresolved）になることは想定された動作である。

### dry-run で確認できる範囲

`workflow.inputs` に直接バインドされる変数は dry-run でも確認できる:

```
/mosaic-orch tech-article --dry-run "Rustの所有権モデルについて"
```

```bash
# plan stage の prompt.md で ${workflow.inputs.topic} が展開されているか確認
cat .mosaic-orch/runs/DRYRUN-{timestamp}-tech-article/stages/plan/prompt.md | grep -A5 "## Input"
```

### 本実行時の確認手順（参考）

本実行（`--dry-run` なし）後に以下を確認する:

```bash
# implement-wave1 の最初の並列ユニットの prompt.md を確認
cat .mosaic-orch/runs/{timestamp}-dev-orchestration/stages/implement-wave1-1/prompt.md
```

期待: `${subtask.persona}` が実際のペルソナ名（例: `backend-lead`）に展開されていること。
期待: `${subtask.instruction}` が実際の instruction 名（例: `implement-backend`）に展開されていること。

### 期待結果（dry-run で確認できる部分）

`workflow.inputs` 参照は dry-run でも展開されること:
- `tech-article` の `plan` stage で入力テキストが `## Input` セクションに展開されていること

前段 stage の出力に依存する変数（`${analyze.output.*}`）は dry-run では VariableUnresolved になることが**正しい動作**:
- この場合 dry-run は ABORT ではなく、変数未解決の旨を出力して終了する（または変数をプレースホルダーのまま残す — エンジンの実装方針による）

### 失敗時の対応

| 症状 | 原因と対処 |
|---|---|
| `workflow.inputs.*` が展開されない | `variable-resolver.md` の `workflow.inputs` バインディングを確認する |
| dry-run で VariableUnresolved が ABORT になる | dry-run モードでは前段出力への依存は許容される動作。orchestrator.md の dry-run 時の VariableUnresolved ハンドリングを確認する |
| `${subtask.persona}` がそのまま残る（本実行時） | Stage Runner の「共通前処理: Facet 変数展開」ステップの実装を確認する |

---

## テスト5: 条件分岐 — when / loop_until

### 目的

`when` 条件が `false` の場合に stage が SKIP され、`trace.ndjson` に `stage_skip` イベントが記録されることを確認する。

### テスト5-a: has_wave2=false の場合に wave2 stage が SKIP される

#### 手順

`analyze` stage の出力に `has_wave2: false` が含まれる本実行シナリオで確認する。または、以下のテスト用 YAML で dry-run を代用する（`when` 条件の評価は dry-run でも実行される）:

```yaml
# workflows/test-when-skip.yaml（一時ファイル）
name: test-when-skip
version: "1"
description: when=false の SKIP 動作検証

inputs:
  - name: has_wave2
    type: string
    required: false

stages:
  - id: always-run
    kind: task
    facets:
      persona: tech-writer
    input: ${workflow.inputs.has_wave2}

  - id: wave2-stage
    kind: task
    when: ${workflow.inputs.has_wave2} == 'true'
    facets:
      persona: tech-writer
    input: wave2 content
```

```
/mosaic-orch workflows/test-when-skip.yaml --dry-run has_wave2=false
```

#### 期待結果

`trace.ndjson` に以下のイベントが記録されること:

```json
{"ts": "...", "event": "stage_skip", "stage_id": "wave2-stage", "reason": "when=false"}
```

コンソール出力の `Stages resolved:` に `wave2-stage` がリストされ、SKIP されたことが分かること。

```bash
# trace.ndjson を確認
cat .mosaic-orch/runs/DRYRUN-{timestamp}-test-when-skip/trace.ndjson | grep stage_skip
# 期待: {"ts":"...","event":"stage_skip","stage_id":"wave2-stage","reason":"when=false"}
```

### テスト5-b: has_fe=false の場合に ui-verify stage が SKIP される

#### 手順

`dev-orchestration` workflow の `ui-verify` stage の `when` 条件 (`${analyze.output.has_fe} == 'true'`) の動作を確認する。

本実行で `analyze` stage が `has_fe: false` を含む出力を返した場合:

```bash
# 本実行後の trace.ndjson を確認
grep "stage_skip" .mosaic-orch/runs/{timestamp}-dev-orchestration/trace.ndjson
```

#### 期待結果

`has_fe: false` の場合:

```json
{"ts": "...", "event": "stage_skip", "stage_id": "ui-verify", "reason": "when=false"}
```

`has_fe: true` の場合は `stage_skip` イベントが記録されず、`ui-verify` が実行されること。

### テスト5-c: trace.ndjson への stage_skip イベント記録の確認

dry-run での一般的な確認コマンド:

```bash
# SKIP イベントの一覧
grep '"event":"stage_skip"' .mosaic-orch/runs/DRYRUN-{timestamp}-{workflow}/trace.ndjson

# 全イベントの時系列確認
cat .mosaic-orch/runs/DRYRUN-{timestamp}-{workflow}/trace.ndjson | python3 -m json.tool --no-ensure-ascii 2>/dev/null || cat .mosaic-orch/runs/DRYRUN-{timestamp}-{workflow}/trace.ndjson
```

### 失敗時の対応

| 症状 | 原因と対処 |
|---|---|
| `stage_skip` イベントが記録されない | `orchestrator.md` の SKIP ステップで `run-recorder.recordEvent` が呼ばれているか確認する |
| `when=false` なのに stage が実行される | `orchestrator.md` の CHECK_WHEN ステップの条件評価ロジックを確認する |
| `stage_skip` イベントの `reason` フィールドがない | `run-recorder.md` の `stage_skip` イベント定義を確認する（`reason: "when=false"` が必須フィールド）|
| 条件式の比較が正しく評価されない | `stage-runner.md` の比較演算ルール（`==`, `!=`, `<`, `>` 等）の実装を確認する |

### テスト後のクリーンアップ

```bash
rm -f workflows/test-when-skip.yaml
```

---

## まとめ: スモークテスト実行チェックリスト

| # | テスト | dry-run 適用 | 確認コマンド |
|---|---|---|---|
| 1 | V12 ガードルール WARN | ✅ | コンソール出力に `WARN [V12]` が含まれる |
| 2 | 全 facet 解決 | ✅ | `grep FacetNotFound trace.ndjson` → 0件 |
| 3 | prompt.md 生成・セクション構造 | ✅ | `ls stages/*/prompt.md` + 中身確認 |
| 4a | `workflow.inputs.*` 変数展開 | ✅ | `prompt.md` の `## Input` セクション確認 |
| 4b | `${subtask.*}` 動的 facet 展開 | 本実行のみ | `stages/implement-wave1-*/prompt.md` 確認 |
| 5 | `when=false` → stage_skip イベント | ✅（テスト用YAML使用） | `grep stage_skip trace.ndjson` |
