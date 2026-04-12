# Variable Resolver — mosaic-orch

`${...}` 形式の変数参照を解決する。Orchestrator(L2)と Contracts(横断)から呼ばれる。

## あなたの責務

テキスト中の `${...}` パターンを見つけて、対応する値に置換する。
**他モジュールの責務には踏み込まない。** Stage 実行方法も Facet 合成方法も知らない。

## 入力

- `text`: 変数参照を含む文字列
- `context`: 変数コンテキスト（以下のキーを持つマップ）
  - `workflow.inputs`: ユーザー入力パラメータのマップ
  - `{stage_id}.output`: 各 stage の出力（文字列またはパース済み構造）
  - `{stage_id}.outputs`: fan_out stage の出力配列
  - `self`: 現在の stage の最新出力（loop_until 内で使用）
  - fan_out の `as` 変数: 現在のイテレーション要素

## 解決手順

1. テキスト中の `${...}` パターンを正規表現 `/\$\{([^}]+)\}/g` で全て検出する
2. 各マッチに対して、`...` 部分をドット区切りで分割する
   - 例: `${plan.output.corners}` → `["plan", "output", "corners"]`
3. context マップを先頭キーから順に辿る
   - `plan` → `context["plan"]` → `context["plan"]["output"]` → `context["plan"]["output"]["corners"]`
4. 値が見つかったら置換する
   - 値が文字列の場合: そのまま置換
   - 値がオブジェクト/配列の場合: JSON文字列化して置換
5. 値が見つからない場合: **VariableUnresolved エラー**を報告する
   - エラーメッセージ: `Variable unresolved: ${<original>} — context keys available: [<keys>]`

## 出力

- 成功: 全変数が解決された文字列
- 失敗: VariableUnresolved エラー（変数名 + 利用可能なキー一覧を含む）

## 注意事項

- ネストした `${...}` は非対応（`${ ${a}.b }` のような形式）
- 未解決変数が1つでもあればエラー（部分解決は返さない）
- `when` / `loop_until` の条件式は変数展開のみ行い、**条件評価は呼び出し元の責務**
