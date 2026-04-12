---
name: setup-git-branch
description: Issue作成、ベースブランチ最新化、ブランチ作成の指示
---

# 指示: Git ブランチセットアップ

Issue確保とブランチ作成を行ってください。

## 手順

### Step 1: Issue 確保

タスクにIssue番号があるか確認する。なければ作成:

```bash
gh issue create --title "{type}({scope}): {subject}" --body "{タスク内容}"
```

### Step 2: ベースブランチ最新化

```bash
git pull origin {base-branch}
```

`{base-branch}` はプロジェクトの既定ブランチ（main, master, develop 等）を自動判定する。

### Step 3: ブランチ作成

**通常の場合:**

```bash
git checkout -b {type}/mo-{YYYYMMDD}-{slug}
```

- type: feat, fix, refactor, test, docs, chore（タスク種別から判定）
- YYYYMMDD: 本日の日付
- slug: タスク内容の英語要約（kebab-case、3-5語）

**Stacked PRの場合（Wave分解時）:**

```bash
git checkout -b {type}/{issue}-{name}/01-{step1}
git checkout -b {type}/{issue}-{name}/02-{step2}
```

各PRのbaseを前のブランチに設定する。

### Step 4: push はしない

ブランチ作成のみ行う。pushとPR作成はfinalize stageで行う。

## 出力フォーマット

## Git Setup
- issue_number: {Issue番号}
- branch_name: {ブランチ名}
- base_branch: {ベースブランチ名}
- stacked_branches: [{ブランチ名1}, {ブランチ名2}, ...]（Stacked PRの場合のみ）
