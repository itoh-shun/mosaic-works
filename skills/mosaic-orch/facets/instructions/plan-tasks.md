---
name: plan-tasks
description: 設計仕様に基づくサブタスク分解、ファイル割り当て、テスト戦略、受入基準分配の指示
---

# 指示: タスク計画

承認済みの設計仕様に基づき、サブタスク分解・担当者選定・ファイル割り当て・テスト戦略・Wave振り分けを行ってください。

## 入力

- **タスク指示書** (workflow.inputs.task): ユーザーの元の要求
- **設計仕様** (design stage出力): コードベースコンテキスト、ファイル構成、設計パターン、実装ガイドライン、スコープ規律、受入基準

## 手順

### Step 1: サブタスク分解判定

設計仕様の要件・アーキテクチャに基づき、分解方式を決定する:

| 条件 | 分解方式 | 実行方式 |
|---|---|---|
| 単一レイヤー・単一関心事 | 分解しない | 1メンバー（fan_out要素数1） |
| BE+FE横断・相互依存なし | 並列分解 | Wave1で並列 |
| BE+FE横断・FEがBEに依存 | Wave分解 | Wave1: BE → Wave2: FE |
| 混合（独立+依存が混在） | Wave分解 | Wave1: 独立タスク並列 → Wave2: 依存タスク |

### Step 2: persona/instruction 選定

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

### Step 3: ファイル割り当て

design stage の File Structure テーブルを参照し、各サブタスクにファイルを割り当てる。

**制約:**
- **1ファイルが複数サブタスクにまたがらない**（衝突防止）
- File Structure に含まれないファイルを割り当てない（スコープクリープ防止）
- 全ての File Structure エントリがいずれかのサブタスクに割り当てられること

### Step 4: スキル選定

Knowledge の skill-catalog を参照し、各サブタスクに必要なスキル名を2〜4個選定する。
ユーザーの環境にインストール済みのスキルのみ選定すること（skill-catalog に載っているものが対象）。

### Step 4.5: MCP検出と割り当て

Knowledge の mcp-catalog を参照し、利用可能なMCPツールを検出する:
1. ToolSearch で `"mcp__"` を検索し、利用可能なMCPプレフィックスを特定する
2. 各サブタスクに適切なMCPを割り当てる（0〜2個）
3. MCP未検出の場合は割り当てない（mcpsフィールドを省略）

### Step 5: テスト戦略の策定

各サブタスクに対して、**何をどうテストするか**を具体的に定義する:
- ユニットテスト: どのモジュール/関数をテストするか
- 統合テスト: どのAPIエンドポイント/フローをテストするか
- 「テストを書く」ではなく「何をどうテストするか」を記述する

### Step 6: 受入基準の分配

design stage の Acceptance Criteria を各サブタスクに分配する。

**制約:**
- **全ての Acceptance Criteria がいずれかのサブタスクにマッピングされること**（漏れ防止）
- 1つの criteria が複数サブタスクに割り当てられてもよい（共同責任の場合）

### Step 7: FEサブタスクのデザイン要件定義（has_fe=trueの場合）

FE サブタスクがある場合、**Wave 2 の最初のサブタスク**（FE基盤構築）に以下を含める:
- CSS変数によるデザイントークン定義（色、スペーシング、フォント）
- `prefers-color-scheme: dark` 対応のダークモードトークン
- モバイルブレークポイント定義（375px / 768px）
- サイドバーのモバイル対応方針（非表示 or ハンバーガー）

### Step 8: Wave振り分け + 複雑度見積もり

- 依存関係のないサブタスクを Wave 1 にまとめる
- 依存関係のあるサブタスクを Wave 2 に配置する
- Wave 2 が不要な場合は has_wave2: false とする
- 各サブタスクに estimated_complexity (small/medium/large) を付与する

## 重要な制約

- **あなたの出力は計画レポートのみ。** ファイルの作成・変更・コーディングは一切行わないこと
- 設計仕様で承認された方針に従うこと。設計を変更する場合はその理由を明記すること
- design stage の File Structure に含まれないファイルを計画に含めない
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
- files_create: [{新規作成ファイルパス}]
- files_modify: [{変更ファイルパス}]
- skills: [{スキル名1}, {スキル名2}]
- mcps: [{MCP名: 説明}]（利用可能なMCPがある場合のみ）
- testing_strategy: {何をどうテストするか}
- acceptance_criteria: [{この subtask が担う受入基準}]
- estimated_complexity: small | medium | large

### Subtask 2
...

## Wave 2 Subtasks
### Subtask 1
...

## Criteria Coverage
| # | Acceptance Criteria | Subtask | Status |
|---|-------------------|---------|--------|
| 1 | {基準1} | Wave1-Subtask1 | covered |
| 2 | {基準2} | Wave2-Subtask1 | covered |
