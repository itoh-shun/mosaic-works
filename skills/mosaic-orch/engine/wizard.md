# Workflow Builder Wizard — mosaic-orch

`--new-workflow` で起動される対話型ウィザード。SKILL.md(L1)から呼ばれる。

## あなたの責務

ユーザーとの対話を通じてWorkflow YAML + 必要なfacet/contractファイルを生成する。
**1問ずつ** AskUserQuestion で聞き、既存資産の再利用を優先する。

## 手順

### Step 1: 基本情報

AskUserQuestion で以下を1問ずつ聞く:

1. **ワークフロー名** (例: `tech-article`, `code-review-loop`)
   - kebab-case で入力してもらう
2. **何をするワークフローか** (1行説明)
3. **入力パラメータ名** (デフォルト: `topic`)

### Step 2: ステージ設計

AskUserQuestion でステージを1つずつ定義する。以下を繰り返す:

#### 2a. ステージの概要

```
「ステージ {N} を定義します。」

options:
  - task (1サブエージェントで1タスク)
  - fan_out (N並列に分解)
  - fan_in (並列結果を統合)
  - 完了 (これ以上ステージを追加しない)
```

「完了」が選ばれたら Step 3 へ。

#### 2b. ステージ名

ステージID を入力してもらう (例: `research`, `draft`, `review`)

#### 2c. Persona 選定

既存の persona 一覧を Glob で取得し、選択肢として提示:

```
Persona を選んでください:

既存:
  - researcher
  - tech-writer
  - editor
  - reviewer
  - backend-lead
  - ...
  - (新規作成)
```

「新規作成」が選ばれたら:
1. persona名を入力
2. 役割の1行説明を入力
3. `facets/personas/{name}.md` をスケルトン生成:

```markdown
---
name: {name}
description: {説明}
---

あなたは{説明}を担当します。

## 専門領域
- (ユーザーが後で記入)

## 行動指針
- (ユーザーが後で記入)
```

#### 2d. Knowledge / Policy 選定 (任意)

```
Knowledge を追加しますか? (複数選択可)

既存:
  - article-format
  - broadcast-format
  - team-roster
  - ...
  - (新規作成)
  - (なし)
```

Policy も同様。

#### 2e. Instruction 選定

```
Instruction を選んでください:

既存:
  - research-topic
  - draft-section
  - code-review-5axis
  - ...
  - (新規作成)
```

「新規作成」が選ばれたら:
1. instruction名を入力
2. 何をする指示か1行説明を入力
3. `facets/instructions/{name}.md` をスケルトン生成:

```markdown
---
name: {name}
description: {説明}
---

# 指示: {名前}

{説明}

## 手順
1. (ユーザーが後で記入)

## 出力フォーマット
(ユーザーが後で記入)
```

#### 2f. Rubric 選定 (任意)

レビュー系ステージの場合に提示:

```
Rubric を追加しますか? (複数選択可)

既存:
  - clarity
  - accuracy
  - structure
  - readability
  - performance
  - naming
  - testing
  - security
  - design
  - (新規作成)
  - (なし)
```

#### 2g. Output Contract

```
Output Contract 名を入力してください (例: research-result)
既存: [一覧] / 新規作成
```

「新規作成」が選ばれたら:
1. contract名を入力
2. `contracts/{name}.md` をスケルトン生成:

```markdown
---
name: {name}
description: (後で記入)
---

# Output Contract: {name}

## 期待形式
(後で記入)

## パース規則（エンジンが抽出）
- field1: (抽出方法)

## 検証項目
- field1 が空でないこと（必須）
```

#### 2h. 追加オプション (条件付き)

kind が task の場合:
- `when` 条件を設定するか? (例: `${review.output.grade} < 'A'`)
- `loop_until` を設定するか? (設定する場合は `max_iterations` も)

kind が fan_out の場合:
- `from` (どのステージの配列を分解するか)
- `as` (各要素の変数名)
- `max_parallel` (並列上限)

kind が fan_in の場合:
- `from` (どの fan_out の outputs を統合するか)

### Step 3: YAML 生成

収集した情報から `workflows/{name}.yaml` を生成する。

```yaml
name: {name}
version: "1"
description: {説明}

inputs:
  - name: {パラメータ名}
    type: string
    required: true

defaults:
  permission: acceptEdits

stages:
  {収集したステージ定義をYAML形式で出力}
```

### Step 4: 確認と保存

生成したYAMLをユーザーに表示し、AskUserQuestion で確認:

```
以下のワークフローを生成しました:

{YAML全文}

新規作成されるファイル:
  - workflows/{name}.yaml
  - facets/personas/{新規のみ}
  - facets/instructions/{新規のみ}
  - contracts/{新規のみ}

options:
  - 保存する
  - 修正してから保存する
```

「保存する」→ 全ファイルを Write して完了報告。
「修正」→ 修正箇所を聞いて反映後、再表示。

### Step 5: 完了報告

```
✅ ワークフロー '{name}' を作成しました。

作成ファイル:
  - workflows/{name}.yaml
  - {新規facetファイル一覧}
  - {新規contractファイル一覧}

実行: /mosaic-orch {name} {入力}
Dry-run: /mosaic-orch {name} --dry-run {入力}

スケルトンとして生成されたファイル（中身を記入してください）:
  - {スケルトンファイル一覧}
```
