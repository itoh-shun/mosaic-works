---
name: push-pr-report
description: git push、PR作成、PR Ready化、ユーザー報告の指示
---

# 指示: Push + PR作成 + 結果報告

全ブランチをpushし、PRを作成してReady化し、ユーザーに結果を報告してください。

## 手順

### Step 1: 全ブランチ一括push

```bash
git push -u origin {branch-name}
```

Stacked PRの場合は全ブランチを順にpush:
```bash
git push -u origin {branch-01}
git push -u origin {branch-02}
```

### Step 2: PR作成

```bash
gh pr create --title "{type}({scope}): {subject}" --body "{PR本文}" --base {base-branch}
```

PR本文テンプレート:
```
## Summary
{タスク内容の要約}

## Changes
{変更内容の箇条書き}

## Test Results
{テスト実行結果のサマリー}

## Review
Grade: {総合グレード}
- Performance: {grade}
- Naming: {grade}
- Testing: {grade}
- Security: {grade}
- Design: {grade}
```

Stacked PRの場合はPR本文に「Stacked PR N/M」と明記。

### Step 3: PR Ready化

```bash
gh pr ready {PR番号}
```

### Step 4: 結果報告

ユーザーに以下を報告:

```
## 完了報告

- **タスク**: {タスク内容}
- **実行方式**: {single | parallel | wave}
- **チーム**: 
  {persona → サブタスク [instruction]}
  ...
- **Issue**: #{番号} ({URL})
- **PR**: #{番号} ({URL})
- **テスト結果**: {pass/fail + 件数}
- **レビュー評価**: 
  - Performance: {grade}
  - Naming: {grade}
  - Testing: {grade}
  - Security: {grade}
  - Design: {grade}
  - **総合: {grade}**
- **レビュー結果保存先**: {パス}
```

## 出力フォーマット

## Completion Report
- pr_url: {PR URL}
- issue_url: {Issue URL}
- summary: {タスクの1行サマリー}
- team_report: {チーム報告テキスト}
