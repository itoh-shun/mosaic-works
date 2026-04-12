---
name: git-conventions
description: ブランチ命名規約とコミットメッセージ規約のポリシー
---

# Git規約ポリシー

## ブランチ命名規約
- 形式: `{type}/mo-{YYYYMMDD}-{slug}`
- type: feat, fix, refactor, test, docs, chore
- YYYYMMDD: 作成日
- slug: タスク内容の英語要約（kebab-case、3-5語）

例: `feat/mo-20260412-add-sort-endpoint`

## Stacked PR ブランチ
- 形式: `{type}/{issue}-{name}/01-{step1}`, `{type}/{issue}-{name}/02-{step2}`
- 各PRのbaseを前のブランチに設定
- PR本文に「Stacked PR N/M」と明記

## コミットメッセージ規約
- 形式: `{type}({scope}): {subject}`
- subject は英語、小文字始まり、末尾ピリオドなし
- フレーバーテキスト禁止（絵文字、ジョーク、不要な修飾語）
- body は任意。書く場合は「何を」ではなく「なぜ」を記述

## マージコミット
- 形式: `merge: {サブタスクの概要}`
- `--no-ff` を必ず使用（マージコミットを残す）
