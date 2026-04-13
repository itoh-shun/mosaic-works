# Contracts — mosaic-orch

Output Contract の読み込み・抽出・検証を行う。Stage Runner(L3) から呼ばれる。

## Contract 検証フロー全体像

| # | タイミング | 実行層 | 何をするか | 失敗時 |
|---|---|---|---|---|
| 1 | INIT | L2 Orchestrator | 全 output_contract の contracts/{name}.md が実在するか | SchemaError → ABORT |
| 2 | RUN_STAGE 後 | L3 Stage Runner | サブエージェント出力をcontract定義に照らして抽出・検証 | ContractViolation → リトライ(2回) → StageFailure |
| 3 | CHECK_LOOP | L3 Stage Runner | loop_until 条件内の self.X が extracted から解決できるか | 解決不能 → LoopExhausted |

## あなたの責務

contract 名とサブエージェント出力を受け取り、
(1) contract 定義ファイルを読む → (2) 出力からフィールドを抽出 → (3) 検証項目をチェック。
**Stage 実行方法は知らない。** 文字列を受け取って検証結果を返すだけ。

## 事前読み込み

処理を開始する前に `engine/variable-resolver.md` を Read する（条件検証に使う場合）。

## 入力

- `contractName`: string（例: `"review-verdict"`）
- `agentOutput`: string（サブエージェントの出力テキスト全体）

## Contract 定義ファイルの構造

`contracts/{contractName}.md` を Read する。以下のセクションを期待する:

```markdown
---
name: review-verdict
description: 多角レビューの総合判定
---

# Output Contract: review-verdict

## 期待形式
（人間向け説明。検証には使わない）

## パース規則（エンジンが抽出）
- {fieldName}: {抽出方法の説明}
  例: grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/

## 検証項目
- {fieldName} が {条件}（必須 / 推奨）
```

## 処理手順

### Step 1: Contract 定義ファイルの読み込み
1. `contracts/{contractName}.md` を Read する
2. ファイルが存在しない場合: SchemaError（静的検証で防ぐべきだが、防御的にチェック）

### Step 2: フィールド抽出
「## パース規則」セクションを読み、各フィールドの抽出方法に従って agentOutput からフィールドを抽出する。

抽出方法の解釈:
- **見出し直下**: agentOutput 中の該当見出し以降、次の見出しまでのテキストを取得
- **正規表現**: 指定された正規表現でマッチングし、最初のマッチを取得
- **箇条書き配列化**: 箇条書き（`- ` で始まる行）を配列に変換

抽出結果を `extracted` マップとして保持する: `{ grade: "A+", evidence: "...", suggestions: [...] }`

### Step 3: 検証
「## 検証項目」セクションを読み、各項目を上から順にチェックする。

- 「必須」と記載されたフィールドが空または未抽出 → **ContractViolation エラー**
- 「推奨」と記載されたフィールドが空 → WARN（エラーにはしない）
- 条件（正規表現マッチ、件数範囲など）を満たさない → **ContractViolation エラー**

### Step 4: 結果返却

## 出力

- 成功: `{ extracted: Map<string, any>, valid: true }`
- 失敗: `ContractViolation { field, expected, actual, contractName }`

## エラー処理

ContractViolation が発生した場合:
- Stage Runner に返す（Stage Runner が 2 回までリトライする）
- エラーメッセージに以下を含める:
  - contract 名
  - 失敗したフィールド名
  - 期待値と実際値
  - agentOutput の先頭 200 文字（デバッグ用）
