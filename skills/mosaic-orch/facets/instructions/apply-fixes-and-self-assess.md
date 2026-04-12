---
name: apply-fixes-and-self-assess
description: レビュー指摘の修正と同rubricでの自己採点の指示
---

# 指示: レビュー修正 + 自己採点

前回のレビュー指摘を修正し、同じ5軸rubricで自己採点してください。

## 手順

### Step 1: 指摘内容の確認

入力として渡されるレビュー結果から、修正必須項目（Issues）を確認する。

### Step 2: 修正実装

各指摘に対して修正を実施する:
- **ファイル名:行番号** の指摘に対して、指示された方向性で修正
- 修正が別の問題を引き起こさないか確認する
- 修正後、関連テストを再実行する

### Step 3: ビルド・テスト確認

```bash
# プロジェクトの標準ビルド・テストコマンドを実行
./gradlew compileKotlin && ./gradlew test  # BE
npm run build && npm run test              # FE
```

### Step 4: 自己採点

Rubrics セクションに提供される5軸に従い、修正後のコードを自己採点する:
- 各軸の評価（C/B/A/A+/S）
- 評価の根拠（修正前後の比較を含む）
- 総合グレードの算出

### Step 5: ローカルコミット

```bash
git add {修正ファイル}
git commit -m "fix: address review feedback — {修正概要}"
```

## 出力フォーマット

## Grade
{S|A+|A|B|C}

## Evidence
{修正内容と自己採点の根拠}

## Fixed Files
- {ファイルパス}: {修正内容の要約}

## Remaining Issues
- {未解決の指摘があれば（理由付き）}
