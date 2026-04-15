---
name: reviewer-grade
description: ラジオレビュアー1名の採点結果。grade/character_voice/evidence/suggestions を含む。
---

# Output Contract: reviewer-grade

ラジオ台本レビュアー1名（fan_out要素）が出力する採点結果。

## 必須フィールド

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `grade` | string | ✅ | `S`, `A+`, `A`, `B+`, `B`, `C` のいずれか |
| `character_voice` | string | ✅ | 1〜200文字。レビュアーキャラとしての一言コメント |
| `evidence` | string[] | ✅ | 1〜3個の具体的引用。空配列禁止 |
| `suggestions` | string[] |  | 0〜3個の改善提案。書き換え案を含むものを推奨 |

## パース仕様

レビュアーの出力（review-as-radio-persona instruction の出力）から以下のパターンで抽出する:

```
grade: {value}
character_voice: {value}
evidence:
  - {item1}
  - {item2}
suggestions:
  - {item1}
  - {item2}
```

- `grade` 行の値を抽出。前後空白・引用符を除去
- `evidence:` の直下のリストを抽出（`-` で始まる行）
- `suggestions:` の直下のリストを抽出（無い場合は空配列）

## バリデーションルール

| # | ルール | 失敗時 |
|---|---|---|
| R1 | grade が定義済み6値のいずれか | ContractViolation |
| R2 | character_voice が空でない | ContractViolation |
| R3 | evidence が1件以上 | ContractViolation |
| R4 | grade が「A〜B+」のような幅指定でない | ContractViolation |

## fan_out aggregate での使用例

```yaml
aggregate:
  all_a_plus: "all: ${item.grade} >= 'A+'"
  has_b_or_lower: "any: ${item.grade} <= 'B+'"
```
