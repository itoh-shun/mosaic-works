---
name: reviewer-list
description: ラジオ6名レビュアーの固定メタデータリスト。fan_outのfromソースとして使う。
---

# Output Contract: reviewer-list

emit-radio-reviewer-list instruction が出力する固定6名のレビュアー定義。

## 必須フィールド

| フィールド | 型 | 必須 | バリデーション |
|---|---|---|---|
| `reviewers` | Reviewer[] | ✅ | 必ず6件 |

### Reviewer 構造

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `character_name` | string | ✅ | レビュアーの人物名（例: 野沢修一） |
| `persona` | string | ✅ | facets/personas/{name}.md に対応する識別子（radio-* prefix） |
| `rubric` | string | ✅ | facets/rubrics/{name}.md に対応する識別子 |

## パース仕様

emit-radio-reviewer-list 出力から以下のパターンで抽出:

```
## Reviewer List
### Reviewer N
- character_name: ...
- persona: ...
- rubric: ...
```

`### Reviewer` で始まる各ブロックを Reviewer オブジェクトに変換し、reviewers 配列にまとめる。

## バリデーションルール

| # | ルール | 失敗時 |
|---|---|---|
| RL1 | reviewers の件数がちょうど6件 | ContractViolation |
| RL2 | 全 Reviewer の persona が radio-* で始まる | ContractViolation |
| RL3 | 全 Reviewer の persona ファイルが facets/personas/ に実在 | FacetNotFound |
| RL4 | 全 Reviewer の rubric ファイルが facets/rubrics/ に実在 | FacetNotFound |

## fan_out での使用例

```yaml
- id: review
  kind: fan_out
  from: ${reviewer-config.output.reviewers}
  as: reviewer
  facets:
    persona: ${reviewer.persona}
    rubrics: [${reviewer.rubric}]
```
