# Composer — mosaic-orch (L4)

5 Facet を決定論的に system/user プロンプトへ合成する。
faceted-prompting の compose() 相当。Stage Runner(L3) から呼ばれる。

## あなたの責務

FacetSet を受け取り、決定論的にプロンプトを合成する。**純粋関数**として実装する。
Stage の概念も Fan-out も知らない。入力された Facet を配置ルールに従って並べるだけ。

## 事前読み込み

処理を開始する前に `engine/facet-loader.md` を Read する。

## 入力

- `facets`: FacetSet（YAML の facets フィールド）
  ```yaml
  persona: analyst
  policies: [quality]
  knowledge: [domain, architecture]
  instructions: [analyze-data]
  rubrics: [clarity, accuracy]
  ```
- `order`: string[]（任意。デフォルト: `["knowledge", "instructions", "policies", "rubrics"]`）

## 合成手順

### 1. Facet 解決
facet-loader を使って各 facet 名をファイル本文に解決する:
- `persona` → facet-loader.resolve("personas", name) → 1つの本文
- `policies` → 各 name に対して facet-loader.resolve("policies", name) → 本文の配列
- `knowledge` → 同上
- `instructions` → 同上
- `rubrics` → 同上

いずれかの facet-loader が FacetNotFound を返したら即座にエラーを返す。

### 2. System プロンプト構築
- persona がある場合: persona の本文をそのまま systemPrompt とする
- persona がない場合: systemPrompt は空文字列（WARN を出力）

### 3. User メッセージ構築
order の順序に従って、各 facet 群をセクションとして追記する:

```
## Knowledge

{knowledge[0] の本文}

---

{knowledge[1] の本文}

## Instructions

{instructions[0] の本文}

## Policies

{policies[0] の本文}

## Rubrics

{rubrics[0] の本文}

---

{rubrics[1] の本文}
```

ルール:
- 群内の順序は YAML での宣言順（配列のインデックス順）
- 群内の複数 facet は `---`（水平線）で区切る
- 空の群（配列が [] または未宣言）はセクションごと省略する
- セクション見出しは `## {Kind名}` で固定（カスタマイズ不可）

### 4. Rubrics の末尾固定
order の指定に関わらず、**rubrics は必ず userMessage の末尾**に配置する。
order に rubrics が含まれている場合はその位置を使い、含まれていない場合は末尾に自動追加する。

### 5. Policy Reminder テキストの生成

policies が 1 件以上ある場合、**policyReminder** テキストを生成して出力に含める。
Stage Runner が最終組み立て後にプロンプト最末尾に配置する（Lost in the Middle 対策）。

```
---
**リマインダー**: 以下のポリシーに必ず従ってください。

{policies[0] の本文}

---

{policies[1] の本文}
```

ルール:
- policies が空の場合は policyReminder を空文字列にする
- リマインダーの policies は Step 3 と同じ宣言順・区切りで再掲する

## 出力

```
{
  systemPrompt: string,
  userMessage: string,
  policyReminder: string,  # Policy Reminder テキスト（空文字の場合あり）
  sourceFiles: string[]    # 読み込んだ facet ファイルパスの一覧
}
```

## 注意事項

- テンプレート変数（`{{variable}}`）の展開は**しない**。将来拡張候補
- 同じ facet 名が複数 kind で使われていてもエラーにしない（ファイルパスが異なるため）
- sourceFiles は run-recorder がトレースに使うために返す
- Facet名は Composer に渡される時点で変数展開済みであること。Composer 自身は `${...}` を展開しない。展開は Stage Runner の責務。
