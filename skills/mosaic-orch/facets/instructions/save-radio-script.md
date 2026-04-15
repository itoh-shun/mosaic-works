---
name: save-radio-script
description: 確定したラジオ台本をファイル保存する指示
---

# 指示: ラジオ台本の保存

確定した最終台本をファイルに保存し、保存結果を報告してください。

## 手順

### Step 1: 保存先決定
- ディレクトリ: `radio-scripts/` （カレントディレクトリ直下、なければ作成）
- ファイル名: `YYYY-MM-DD-{topic-slug}.md`
  - 日付は今日の日付
  - topic-slug は Topic を kebab-case に変換（日本語含む場合はローマ字化または短い英訳）
  - 例: `2026-04-15-april-tech-news.md`

### Step 2: ファイル内容
- 先頭にメタデータを YAML frontmatter で付加:

```yaml
---
topic: {Topic}
final_grade: {min_grade}
generated_at: {ISO8601 datetime}
generator: mosaic-orch radio-writer workflow
---
```

- frontmatter の後に最終台本本文をそのまま続ける

### Step 3: ファイル書き込み
- Write tool で保存
- 既存ファイルがある場合は上書きせず `-2`, `-3` のサフィックスを付ける

### Step 4: トピックストックの更新（ラジってえーじぇんと！本流番組の場合）

`~/.claude/skills/mosaic-orch/facets/knowledge/rajitte-topic-stock.md` を Read し、今回採用した各ニュース・トピックを「使用済みトピック」セクションに追記する:

```
#### #N (YYYY-MM-DD) — タイトル
- slug: kebab-case-slug
- 主要キーワード: kw1, kw2, kw3
- 扱った角度: {1〜2行で説明}
- 続報可: {続報として何が扱えるか}
```

候補ストックから採用した場合: 「候補ストック」セクションから該当エントリを削除する。

Edit tool で追記する（既存内容を破壊せず、領域別カテゴリの末尾に追加）。

## 出力フォーマット（厳守）

## Save Result
- saved_path: {実際の保存パス}
- file_size_bytes: {サイズ}
- final_grade: {grade}
- topic: {Topic}
