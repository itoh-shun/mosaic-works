---
name: analyze-dev-task
description: タスク分析、サブタスク分解、persona/instruction選定、Wave振り分けの指示
---

# 指示: 開発タスク分析

与えられたタスクを分析し、サブタスク分解・担当者選定・Wave振り分けを行ってください。

## 手順

### Step 1: タスク分析

以下の項目を分析してください:
1. **影響レイヤー**: FE / BE / 両方 / 非エンジニアリング
2. **タスク種別**: 新機能 / バグ修正 / リファクタリング / テスト / ドキュメント / コンテンツ
3. **設計判断の要否**: 既存パターンで対応可能か、新規設計が必要か
4. **サブタスク分解の要否**: 下記の判定基準で判断

### Step 2: サブタスク分解判定

| 条件 | 分解方式 | 実行方式 |
|---|---|---|
| 単一レイヤー・単一関心事 | 分解しない | 1メンバー（fan_out要素数1） |
| BE+FE横断・相互依存なし | 並列分解 | Wave1で並列 |
| BE+FE横断・FEがBEに依存 | Wave分解 | Wave1: BE → Wave2: FE |
| 混合（独立+依存が混在） | Wave分解 | Wave1: 独立タスク並列 → Wave2: 依存タスク |

### Step 3: persona/instruction 選定

各サブタスクの種別に応じて以下のテーブルから選定する:

| タスク種別 | persona | instruction |
|---|---|---|
| BE新機能・修正 | backend-lead | implement-backend |
| BE複雑ドメイン | backend-domain | implement-backend |
| FE新機能・修正 | frontend-lead | implement-frontend |
| FEコンポーネント | frontend-component | implement-frontend |
| 設計判断が必要 | architect | implement-general |
| テスト追加 | tester | implement-general |
| E2Eテスト | e2e-tester | implement-e2e |
| コンテンツ制作 | content-creator | implement-general |

### Step 4: スキル選定（superpowers含む）

Knowledge の skill-catalog を参照し、各サブタスクに必要なスキル名を2〜4個選定する。

各サブタスクに必要なスキルを選定する。skill-catalog に加えて、以下の superpowers スキルを積極的に含めること:

| 場面 | 推奨スキル |
|---|---|
| 実装全般 | superpowers:test-driven-development |
| Kotlin BE | kotlin-specialist |
| React FE | react-patterns, vercel-react-best-practices |
| E2E テスト | playwright-skill, playwright-e2e-testing |
| セキュリティ関連 | owasp-security |
| DB関連 | postgres, postgresql-database-engineering |
| アクセシビリティ | accessibility, accessibility-engineer |

### Step 5: Wave振り分け

- 依存関係のないサブタスクを Wave 1 にまとめる
- 依存関係のあるサブタスクを Wave 2 に配置する
- Wave 2 が不要な場合は has_wave2: false とする

## 重要な制約

- **あなたの出力は分析レポートのみ。** ファイルの作成・変更・コーディングは一切行わないこと
- 実装は後続の implement stage が担当する。あなたは「何を・誰が・どの順で」を決めるだけ
- 以下の出力フォーマット以外の出力は却下される（Output Contract で検証される）

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

以下の形式で**のみ**出力してください:

## Analysis
- mode: parallel | wave
- has_wave2: true | false
- has_fe: true | false

## Wave 1 Subtasks
### Subtask 1
- persona: {persona名}
- instruction: {instruction名}
- description: {サブタスク内容の1行説明}
- skills: [{スキル名1}, {スキル名2}]

### Subtask 2
...

## Wave 2 Subtasks
### Subtask 1
- persona: {persona名}
- instruction: {instruction名}
- description: {サブタスク内容の1行説明}
- skills: [{スキル名1}, {スキル名2}]
