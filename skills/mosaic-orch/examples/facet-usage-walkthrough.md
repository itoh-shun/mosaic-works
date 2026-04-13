# --facet-usage コマンド ウォークスルー

## 概要

`/mosaic-orch --facet-usage` は、全 workflow YAML を走査して **facet → workflow/stage の逆引きテーブル** を表示する診断コマンドです。

Persona、Policy、Knowledge、Instruction、Rubric といった facet の使用状況をマッピングし、以下を把握できます：

- どの workflow でどの facet が使われているか
- 各 facet がどのステージで適用されているか
- 動的参照（変数展開）の有無
- 未使用の facet

## 使い方

### 全 facet の使用状況を表示

```
/mosaic-orch --facet-usage
```

全 workflows/ 配下の workflow YAML をスキャンし、定義されているすべての facet と、それぞれの利用箇所を一覧表示します。

### 特定 facet の使用状況を検索

```
/mosaic-orch --facet-usage rubrics/clarity
```

指定した facet（ここでは `rubrics/clarity`）が使用されている workflow・stage をフォーカス表示します。

### 全 facet を含める（未使用も表示）

```
/mosaic-orch --facet-usage --all
```

`--all` フラグを付けると、現在のワークフローで利用されていない facet も含めて表示します。

## 期待される出力例

### 全 facet 出力

```
Facet Usage Report
==================

personas/architect:
  - dev-orchestration.yaml → analyze
  - dev-orchestration.yaml → implement-wave1 (dynamic: ${subtask.persona})

personas/project-manager:
  - dev-orchestration.yaml → check-dup
  - dev-orchestration.yaml → setup-git
  - dev-orchestration.yaml → save-results
  - dev-orchestration.yaml → finalize

personas/radio-planner:
  - radio-script.yaml → plan (stage 1/5)

rubrics/clarity:
  - tech-article.yaml → review (stage 3/4)
  - tech-article.yaml → polish (stage 4/4)

rubrics/performance:
  - dev-orchestration.yaml → review
  - dev-orchestration.yaml → fix

knowledge/broadcast-format:
  - radio-script.yaml → plan (dynamic: ${domain.format})

policies/tone-casual:
  - radio-script.yaml → draft (stage 2/5)

instructions/editorial-checklist:
  - tech-article.yaml → review (stage 3/4)
```

### 特定 facet 出力

```
rubrics/clarity:
  - tech-article.yaml → review (stage 3/4)
  - tech-article.yaml → polish (stage 4/4, conditional loop)
```

facet が複数の stage で使用されている場合、各 stage の位置情報（何番目の stage か）と、条件付き実行（`conditional loop` など）の有無も表示されます。

## エッジケース

### 1. 動的 facet 参照

```yaml
stages:
  - name: analyze
    persona: ${subtask.persona}
```

このような変数展開が含まれる場合、出力では以下のように表示されます：

```
personas/architect:
  - dev-orchestration.yaml → analyze (dynamic: ${subtask.persona})
```

`(dynamic: ...)` マークが付き、実行時に解決される参照であることが明示されます。

### 2. 未使用の facet

定義されているが、現在どの workflow でも使用されていない facet は、デフォルトでは表示されません。

```
/mosaic-orch --facet-usage --all
```

`--all` フラグで全 facet を表示するモードでは、以下のように表示されます：

```
policies/tone-formal:
  (not used)
```

### 3. 存在しない facet 名の指定

```
/mosaic-orch --facet-usage unknown/facet
```

指定した facet が存在しない場合：

```
Facet not found: unknown/facet
Available facet types: personas, policies, knowledge, instructions, rubrics
```

## 活用シーン

### Workflow デバッグ

```
/mosaic-orch --facet-usage rubrics/clarity
```

`rubrics/clarity` を確認したい workflow で使っているのに出力されない場合、YAML の facet 参照に誤りがないか確認できます。

### Facet 削除時の影響範囲確認

persona や rubric を削除する前に、どの workflow に影響するかを確認：

```
/mosaic-orch --facet-usage personas/deprecated-persona
```

出力が空の場合は安全に削除できます。

### Facet の再利用可能性チェック

新しい workflow を作成する際、既存の facet がどこで使われているかを確認：

```
/mosaic-orch --facet-usage
```

全体図から、再利用可能な facet を選別できます。

## 出力の解釈

| 項目 | 例 | 説明 |
|---|---|---|
| Facet 名 | `personas/architect` | `/` で区切られた facet ID |
| Workflow 名 | `dev-orchestration.yaml` | facet が定義されている workflow |
| Stage 名 | `analyze` | workflow 内のどのステージで使用されているか |
| Stage 位置 | `stage 1/5` | 5 段階中の 1 番目 |
| 動的参照 | `(dynamic: ${subtask.persona})` | 実行時に変数から解決される |
| 条件付き実行 | `(conditional loop)` | 特定条件下でのみ実行される |
