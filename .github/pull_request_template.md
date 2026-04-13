## 変更種別

- [ ] 新規ワークフロー追加
- [ ] 既存ワークフロー修正
- [ ] Facet追加/修正 (persona / policy / knowledge / instruction / rubric)
- [ ] Contract追加/修正
- [ ] エンジン修正
- [ ] ドキュメント

## 概要

<!-- 何を・なぜ変更したか -->

## ワークフロー追加時のチェックリスト

新規ワークフローを追加する場合、以下を全て確認してください:

### Facet完備性
- [ ] 全 persona ファイルが `facets/personas/` に存在する
- [ ] 全 instruction ファイルが `facets/instructions/` に存在する
- [ ] 全 knowledge ファイルが `facets/knowledge/` に存在する (使用している場合)
- [ ] 全 policy ファイルが `facets/policies/` に存在する (使用している場合)
- [ ] 全 rubric ファイルが `facets/rubrics/` に存在する (使用している場合)

### Contract完備性
- [ ] 全 output_contract のファイルが `contracts/` に存在する
- [ ] 各 contract に「期待形式」「パース規則」「検証項目」が記載されている

### YAML検証
- [ ] `version: "1"` が指定されている
- [ ] 全 stage ID が unique
- [ ] 変数参照 `${...}` が全て先行 stage を指している
- [ ] fan_out に `from` と `as` がある
- [ ] loop_until に `max_iterations` がある

### 動作確認
- [ ] `--dry-run` で全 stage の prompt.md が正しく生成される
- [ ] FacetNotFound / SchemaError が出ない

## エンジン修正時のチェックリスト

- [ ] SoC依存方向が一方向のまま (下位→上位の参照がない)
- [ ] 既存ワークフロー (`radio-script`, `tech-article`, `dev-orchestration`) が壊れない
- [ ] `--dry-run` で既存ワークフローが正常動作する

## Dry-run結果

<!-- `/mosaic-orch {workflow} --dry-run テスト` の結果を貼ってください -->

```
(ここに貼る)
```
