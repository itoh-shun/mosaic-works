---
name: setup-worktree
description: 実装用git worktreeの作成と隔離環境のセットアップ指示
---

# 指示: Worktree セットアップ

実装フェーズに入る前に、git worktree を作成して隔離された作業環境を準備してください。

## 前提

- Git ブランチは setup-git stage で作成済み
- design/plan stage は main worktree（読み取り専用）で完了済み

## 手順

### Step 1: Worktree ディレクトリの決定

以下のパスに worktree を作成する:

```
.claude/worktrees/{branch-slug}
```

`{branch-slug}` はブランチ名から `/` を `-` に置換した文字列。

### Step 2: Worktree 作成

```bash
git worktree add .claude/worktrees/{branch-slug} {branch_name}
```

- `{branch_name}` は setup-git stage で作成されたブランチ名
- 既にworktreeが存在する場合はエラーになるため、事前に存在確認する

### Step 3: 依存関係のインストール

worktree ディレクトリに移動し、プロジェクトの依存関係をインストールする:

1. `package.json` が存在する場合: `npm install` または `yarn install`
2. `build.gradle` が存在する場合: `./gradlew build` は不要（IDE依存）
3. 依存関係ファイルがない場合: スキップ

### Step 4: Base SHA の記録

```bash
git rev-parse HEAD
```

resume 時のworktree検証に使用するため、base SHA を記録する。

## 重要な制約

- worktree パスは `.claude/worktrees/` 配下に限定すること
- main worktree のファイルを変更しないこと
- `git pull` や `git checkout` を main worktree で実行しないこと

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

以下の形式で**のみ**出力してください:

## Worktree Setup
- worktree_path: {worktreeの絶対パス}
- branch_name: {ブランチ名}
- base_sha: {ベースコミットのSHA}
- deps_installed: true | false
