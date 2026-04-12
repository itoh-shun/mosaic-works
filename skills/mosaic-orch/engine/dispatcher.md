# Dispatcher — mosaic-orch (L5)

Task tool 呼び出しのラッパー。Stage Runner(L3) から呼ばれる。

## あなたの責務

system/user プロンプトと権限モードを受け取り、Task tool でサブエージェントを起動して、
その出力（文字列）を返す。
**プロンプトの中身は知らない。** Facet も Contract も Stage も関知しない。

## 単発実行（task / fan_in Stage 用）

### 入力
- `systemPrompt`: string
- `userMessage`: string
- `permission`: `"default"` | `"acceptEdits"` | `"bypassPermissions"`
- `timeout`: number（秒）
- `stageName`: string（ログ用の名前）

### 手順
1. Task tool を呼ぶ:
   ```
   prompt: |
     <system>
     {systemPrompt}
     </system>

     {userMessage}
   description: "{stageName} - mosaic-orch"
   subagent_type: "general-purpose"
   mode: {permission}
   ```
2. Task tool の戻り値（文字列）をそのまま返す

### エラー処理
- Task tool がタイムアウトした場合: **DispatchTimeout エラー**
  - 1回リトライする（同じプロンプト）
  - 2回目も失敗したら Stage Runner にエラーを返す

## 並列実行（fan_out Stage 用）

### 入力
- `prompts`: Array<{ systemPrompt, userMessage, permission, timeout, stageName }>
- `maxParallel`: number | null（null = 全部並列）

### 手順
1. maxParallel が null または prompts.length 以上の場合:
   - **1つのメッセージで** 全 prompts に対して Task tool を並列に呼ぶ
   - 全 Task 完了を待機し、結果配列を返す

2. maxParallel が prompts.length 未満の場合:
   - prompts を maxParallel 個ずつのバッチに分割する
   - バッチ単位で並列実行し、バッチ間は順次
   - 全バッチ完了後、結果配列を元の順序で返す

### エラー処理
- 各 Task のタイムアウトは単発と同じ（1回リトライ）
- 結果配列に失敗した要素がある場合: 成功/失敗のフラグを付けて Stage Runner に返す
  （Stage Runner が on_error ポリシーに基づいて判定する）

## Dry-run モード

dry-run フラグが true の場合:
- Task tool は**呼ばない**
- 代わりに `"[DRY-RUN] Would dispatch: {stageName}"` という文字列を返す
- 並列の場合は N 個の dry-run 文字列を配列で返す
