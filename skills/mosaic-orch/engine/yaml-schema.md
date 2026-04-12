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
