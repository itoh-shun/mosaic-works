# Contributing to mosaic-works

## ワークフローの追加方法

### 1. ウィザードで作成 (推奨)

```
/mosaic-orch --new-workflow
```

対話型ウィザードが工程の定義、担当者の選定、指示書・評価軸・出力形式の設定をガイドします。

### 2. 手動で作成

1. `workflows/{name}.yaml` を作成
2. 必要な facet ファイルを `facets/` 配下に追加
3. 必要な contract ファイルを `contracts/` 配下に追加
4. `--dry-run` で検証

## ファイル配置ルール

| 種類 | ディレクトリ | 命名 |
|---|---|---|
| ワークフロー | `workflows/` | `{name}.yaml` |
| 担当者 (Persona) | `facets/personas/` | `{name}.md` |
| ルール (Policy) | `facets/policies/` | `{name}.md` |
| 前提知識 (Knowledge) | `facets/knowledge/` | `{name}.md` |
| 指示書 (Instruction) | `facets/instructions/` | `{name}.md` |
| 評価軸 (Rubric) | `facets/rubrics/` | `{name}.md` |
| 出力形式 (Contract) | `contracts/` | `{name}.md` |

## Facet の再利用

既存の facet は複数のワークフローで共有できます。新しいワークフローを作る前に、既存の facet で代用できないか確認してください:

```
/mosaic-orch --facet-usage
```

## PR ルール

### ブランチ命名

```
{type}/mo-{YYYYMMDD}-{slug}
```

- type: `feat` (新規WF/facet), `fix` (修正), `docs` (ドキュメント)
- slug: 英語kebab-case、3-5語

### コミットメッセージ

```
{type}(mosaic-orch): {subject}
```

例:
- `feat(mosaic-orch): add blog-review workflow`
- `fix(mosaic-orch): correct clarity rubric grading criteria`

### PR 必須要件

1. **Dry-run 結果を貼る** — `--dry-run` の出力をPR本文に含める
2. **Facet/Contract 完備** — YAMLが参照する全ファイルが存在する
3. **SoC 違反なし** — エンジン修正の場合、依存方向が一方向
4. **既存WF非破壊** — 既存ワークフローの `--dry-run` が通ること

### レビュー観点

| 観点 | チェック内容 |
|---|---|
| 完備性 | YAML が参照する全 facet/contract が存在するか |
| 再利用性 | 既存 facet で代用できるのに新規作成していないか |
| 命名 | kebab-case、既存パターンとの一貫性 |
| 指示書の質 | 手順が具体的か、出力フォーマットが明確か |
| 評価軸の独立性 | 各 rubric が他の rubric に依存していないか |
| 契約の検証可能性 | パース規則が機械的に実行可能か |

## エンジンへの変更

`engine/*.md` を変更する場合は特に慎重に:

1. **依存方向を守る** — 下位レイヤーが上位を参照してはならない
2. **既存WFで検証** — 全ワークフローの `--dry-run` が通ること
3. **変更スコープを最小化** — 1ファイル1関心の原則を維持

```
禁止される参照方向:
  composer.md → stage-runner.md (上位参照)
  dispatcher.md → composer.md (横断参照)
  facet-loader.md → contracts.md (横断参照)
```
