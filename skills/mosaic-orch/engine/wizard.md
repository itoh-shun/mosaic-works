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

### Step 2: ワークフローの流れを設計

#### 2a. 全体の流れを聞く

まず**全体の工程**を自然な言葉で聞く:

```
ワークフローの工程を、矢印でつないで教えてください。

例:
  調査 → 構成案作成 → セクションごとに並列執筆 → 統合 → レビュー → 修正
  分析 → 実装 → テスト → レビュー
  情報収集 → 要約 → レビュー → 最終化
```

#### 2b. 工程からstage構造を自動推定

ユーザーの回答を解析し、以下のルールでstage kind を推定する:

| ユーザーの表現 | 推定される kind |
|---|---|
| 「〜ごとに並列」「分割して」「それぞれ」 | **fan_out** (直後に fan_in を自動追加) |
| 「統合」「まとめる」「合体」 | **fan_in** (明示的に書かれた場合のみ。fan_out直後は自動追加済み) |
| それ以外(調査、執筆、レビュー、分析、etc.) | **task** |

stage ID はユーザーの工程名から自動生成する (日本語→英語kebab-case):
- 調査 → `research`
- 構成案作成 → `outline`
- セクションごとに並列執筆 → `draft` (fan_out) + `assemble` (fan_in)
- レビュー → `review`
- 修正 → `fix`

#### 2c. 推定結果を確認

推定した構造を分かりやすく表示して確認する:

```
以下の工程で進めます:

1. 📋 調査 (research) — 1人が担当
2. 📋 構成案作成 (outline) — 1人が担当
3. 🔀 並列執筆 (draft) — セクションごとに分かれて同時に執筆
4. 🔗 統合 (assemble) — 並列結果を1つにまとめる
5. 📋 レビュー (review) — 1人が担当
6. 📋 修正 (fix) — レビュー結果に基づいて修正(条件付き)

options:
  - この構成でOK
  - 工程を追加/変更したい
```

「追加/変更」→ 修正箇所を聞いて反映し、再表示する。

#### 2d. 各工程の詳細を順に設定

確認済みの工程リストに対して、**1工程ずつ**詳細を聞く。

#### 2e. 誰がやるか (Persona)

工程に合った「担当者」を既存一覧から選ぶか、新しく作る:

```
「{工程名}」は誰がやりますか?

  - 🔍 リサーチャー (researcher) — 正確な情報収集・ソース明示
  - ✍️ テックライター (tech-writer) — 読者目線の技術文書
  - 📝 エディター (editor) — 統合・仕上げ・トーン統一
  - 👀 レビューワー (reviewer) — 多角的な評価・採点
  - 🏗️ アーキテクト (architect) — 設計判断
  - 💻 バックエンドリード (backend-lead) — Kotlin/BE実装
  - 🎨 フロントエンドリード (frontend-lead) — React/FE実装
  - ... (他の既存persona)
  - ➕ 新しい担当者を作る
```

「新しい担当者を作る」が選ばれたら:
1. 名前を入力(kebab-case)
2. 何をする人か1行説明を入力
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

各工程について以下を順に聞く。既存資産はGlobで一覧取得して表示する。

#### 誰がやるか (Persona)

```
「{工程名}」は誰がやりますか?

  - 🔍 リサーチャー (researcher) — 正確な情報収集・ソース明示
  - ✍️ テックライター (tech-writer) — 読者目線の技術文書
  - 📝 エディター (editor) — 統合・仕上げ・トーン統一
  - 👀 レビューワー (reviewer) — 多角的な評価・採点
  - 🏗️ アーキテクト (architect) — 設計判断
  - 💻 バックエンドリード (backend-lead) — Kotlin/BE実装
  - 🎨 フロントエンドリード (frontend-lead) — React/FE実装
  - ... (他の既存persona — Globで取得)
  - ➕ 新しい担当者を作る
```

「新しい担当者を作る」→ 名前+説明を入力 → スケルトン生成

#### 前提知識 (Knowledge) — 任意

```
「{工程名}」で必要な前提知識はありますか? (複数選択可)
  - 既存一覧(Globで取得、絵文字+説明付き)
  - ➕ 新しい前提知識を作る
  - ❌ なし
```

#### ルール (Policy) — 任意

```
「{工程名}」で守るべきルールはありますか? (複数選択可)
  - 既存一覧(Globで取得)
  - ➕ 新しいルールを作る
  - ❌ なし
```

#### 具体的な指示 (Instruction)

```
「{工程名}」の具体的な指示書を選んでください:
  - 既存一覧(Globで取得、説明付き)
  - ➕ 新しい指示書を作る
```

「新しい指示書を作る」→ 名前+説明を入力 → スケルトン生成:

```markdown
---
name: {name}
description: {説明}
---

# 指示: {名前}

{説明}

## 手順
1. (後で記入)

## 出力フォーマット
(後で記入)
```

#### 評価軸 (Rubric) — レビュー/修正工程のみ

レビュー系の工程(「レビュー」「評価」「採点」「チェック」を含む)の場合のみ表示:

```
どの観点で評価しますか? (複数選択可)
  - 📖 明晰さ (clarity) — 伝わりやすさ
  - ✅ 正確性 (accuracy) — 事実の正しさ
  - 🏗️ 構造 (structure) — 論理的な流れ
  - 👁️ 読みやすさ (readability) — 視覚的な見やすさ
  - ⚡ パフォーマンス (performance) — コード効率
  - 🏷️ 命名 (naming) — 規約準拠
  - 🧪 テスト (testing) — テスト品質
  - 🔒 セキュリティ (security) — OWASP準拠
  - 📐 設計 (design) — SoC・依存方向
  - ➕ 新しい評価軸を作る
  - ❌ なし
```

#### 出力の形式 (Output Contract)

```
「{工程名}」の出力として何を期待しますか?
  - 既存一覧(Globで取得)
  - ➕ 新しい出力形式を定義する
  - ❌ 形式を指定しない(自由出力)
```

「新しい出力形式を定義する」→ 名前を入力 → スケルトン生成:

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
