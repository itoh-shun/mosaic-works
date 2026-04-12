---
name: code-review-5axis
description: 5軸コードレビュー（rubrics使用）の指示
---

# 指示: 5軸コードレビュー

`git diff {base-branch}...HEAD` の変更全体に対して、5軸コードレビューを実行してください。

## 手順

### Step 1: 変更差分の取得

```bash
git diff {base-branch}...HEAD
```

変更全体を把握する。ファイル数が多い場合はファイルごとに確認する。

### Step 2: 5軸レビュー実行

Rubrics セクションに提供される5つの評価軸に従って、各軸を評価する:

1. **Performance（パフォーマンス）** — rubric: performance
2. **Naming（命名・一貫性）** — rubric: naming
3. **Testing（テスト）** — rubric: testing
4. **Security（セキュリティ）** — rubric: security
5. **Design（設計・構造）** — rubric: design

各軸について:
- 採点段階に従って評価する（C/B/A/A+/S）
- 指摘がある場合は**ファイル名:行番号**で明示する
- 根拠を具体的に記述する

### Step 3: 総合評価の算出

5軸の評価から総合グレードを算出する:
- 全軸A+以上 → 総合A+
- 1軸でもA未満 → 総合はその最低値
- それ以外 → 5軸の平均（切り捨て）

### Step 4: 修正指示（A+未満の場合）

A+未満の軸がある場合、修正必須項目を明確に指示する:
- **ファイル名:行番号**: 指摘内容
- 修正の方向性を具体的に示す

## 出力フォーマット

## Grade
{S|A+|A|B|C}

## Axes
- performance: {grade} — {根拠の要約}
- naming: {grade} — {根拠の要約}
- testing: {grade} — {根拠の要約}
- security: {grade} — {根拠の要約}
- design: {grade} — {根拠の要約}

## Evidence
{各軸の詳細な根拠。ファイル名:行番号で指摘}

## Issues
{A+未満の修正必須項目リスト（ファイル名:行番号: 指摘内容）}

## Suggestions
{改善提案（必須ではないが推奨する項目）}
