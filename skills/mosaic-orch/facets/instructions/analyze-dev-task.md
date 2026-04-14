---
name: analyze-dev-task
description: タスク分析、サブタスク分解、persona/instruction選定、Wave振り分けの指示
---

# 指示: 開発タスク分析

与えられたタスクを分析し、サブタスク分解・担当者選定・Wave振り分けを行ってください。

## 手順

### Step 0: 既存コードベース診断（実施必須）

タスクの分析に入る前に、プロジェクトの現状を診断してください。以下をツールで調査し、結果を分析に活かすこと:

1. **プロジェクト構造**: `ls`, `Glob` で主要ディレクトリとファイル構造を把握する
2. **パッケージ構成**: `package.json`, `build.gradle`, `pom.xml` 等を読み、使用フレームワーク・ライブラリを特定する
3. **既存テストパターン**: テストファイルを `Glob("**/*.test.*", "**/*.spec.*", "**/test/**")` で探し、テストフレームワーク・テスト構造を把握する
4. **既存API規約**: ルーティング定義やコントローラを探し、命名規約・レスポンス形式を把握する（該当する場合のみ）
5. **ディレクトリ命名規約**: 既存の命名パターン（camelCase / kebab-case / PascalCase）を確認する

**重要**: この診断結果は出力の `## Codebase Context` セクションに含めること。後続の実装 stage がこの情報を参照して既存パターンに従う。

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

### Step 4: スキル選定

Knowledge の skill-catalog を参照し、各サブタスクに必要なスキル名を2〜4個選定する。
ユーザーの環境にインストール済みのスキルのみ選定すること（skill-catalog に載っているものが対象）。

### Step 4.5: FEサブタスクのデザイン要件定義（has_fe=trueの場合）

FE サブタスクがある場合、**Wave 2 の最初のサブタスク**（FE基盤構築）に以下を含める:
- CSS変数によるデザイントークン定義（色、スペーシング、フォント）
- `prefers-color-scheme: dark` 対応のダークモードトークン
- モバイルブレークポイント定義（375px / 768px）
- サイドバーのモバイル対応方針（非表示 or ハンバーガー）

これにより後続のFEサブタスクが一貫したスタイルで実装できる。

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

## Codebase Context
- framework: {使用フレームワーク名とバージョン}
- test_framework: {テストフレームワーク名、未導入なら "none"}
- directory_convention: {既存の命名規約}
- api_convention: {API命名規約、該当なしなら "N/A"}
- notable_patterns: {特筆すべき既存パターン}

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
