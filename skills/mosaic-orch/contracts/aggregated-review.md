---
name: aggregated-review
description: 6名レビュー結果の集約。min_grade/avg_grade/should_polish/findings/final_script を含む。
---

# Output Contract: aggregated-review

aggregate-radio-reviews instruction が生成する集約結果。

## 必須フィールド

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `min_grade` | string | ✅ | `S`, `A+`, `A`, `B+`, `B`, `C` のいずれか |
| `avg_grade` | string | ✅ | 同上 |
| `should_polish` | string | ✅ | `true` または `false` の文字列 |
| `reviewers_a_plus_or_above` | number | ✅ | 0〜6 |
| `reviewers_b_or_below` | number | ✅ | 0〜6 |
| `findings` | Finding[] |  | 0〜N件。should_polish=trueなら1件以上必須 |
| `final_script` | string | ✅ | 現在確定している台本本文（次stageへ受け渡す） |

### Finding 構造

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `description` | string | ✅ | 統合された指摘内容 |
| `reviewer_names` | string[] | ✅ | この指摘を出した人物名（1名以上） |
| `suggested_fix` | string | ✅ | 書き換え案またはアクション |
| `priority` | string | ✅ | `high`, `medium`, `low` のいずれか |

## パース仕様

aggregate-radio-reviews 出力から以下のパターンで抽出する:

```
## Aggregated Review
- min_grade: {value}
- avg_grade: {value}
- should_polish: {true|false}
- reviewers_a_plus_or_above: {N}
- reviewers_b_or_below: {N}

## Findings (優先度順)
### Finding 1
- description: ...
- reviewer_names: [...]
- suggested_fix: ...
- priority: ...

### Finding 2
...

## Final Script
{台本本文}
```

## バリデーションルール

| # | ルール | 失敗時 |
|---|---|---|
| AR1 | min_grade / avg_grade が定義済み6値のいずれか | ContractViolation |
| AR2 | should_polish が "true" または "false" 文字列 | ContractViolation |
| AR3 | reviewers_a_plus_or_above + reviewers_b_or_below + 中間grade数 = 6 | ContractViolation |
| AR4 | should_polish=true なら findings が1件以上 | ContractViolation |
| AR5 | final_script が空でない | ContractViolation |

## next ルールでの使用例

```yaml
next:
  - when: ${aggregate.output.should_polish} == 'false'
    goto: save
  - when: ${aggregate.output.should_polish} == 'true'
    goto: polish
```
