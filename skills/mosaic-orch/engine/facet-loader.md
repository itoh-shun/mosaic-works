# Facet Loader — mosaic-orch

Facet名からMarkdownファイルの本文を解決する。Composer(L4)から呼ばれる。

## あなたの責務

Facet名とFacet種別(persona/policies/knowledge/instructions/rubrics)を受け取り、
対応するMarkdownファイルを Read して本文を返す。
**Facetの内容は解釈しない。** 読んで返すだけ。

## 入力

- `kind`: `"personas"` | `"policies"` | `"knowledge"` | `"instructions"` | `"rubrics"`
- `name`: Facet名（例: `"analyst"`, `"clarity"`）

## 検索順序

1. `~/.claude/skills/mosaic-orch/facets/{kind}/{name}.md` （Skill同梱）

将来拡張時: `~/.mosaic-orch/facets/{kind}/{name}.md` をスキルの前に検索する（ユーザーカスタム優先）。
初版はスキルディレクトリのみ。

## 解決手順

1. 上記パスで Read tool を実行する
2. ファイルが存在する場合:
   a. YAML frontmatter（`---` で囲まれた部分）があれば除去する
   b. frontmatter 除去後の本文を返す
3. ファイルが存在しない場合:
   - **FacetNotFound エラー**を報告する
   - エラーメッセージ: `Facet not found: {kind}/{name}.md — searched: {paths}`

## 出力

- 成功: `{ body: string, sourcePath: string }`
- 失敗: FacetNotFound エラー

## 注意事項

- ファイルの中身は一切パースしない（Rubric の採点段階も Policy のルールも関知しない）
- 空ファイルは正常値として返す（空の body）
- Facet内で他のFacetを `{{include}}` するような機能は非対応
