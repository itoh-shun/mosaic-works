# dev-orchestration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** intendantの開発オーケストレーション全機能(9手順)を、mosaic-orchフレームワーク準拠の宣言的Workflowとして再実装する

**Architecture:** 13ステージの宣言的Workflow YAML + 49個のFacet/Contractファイル。analyzeステージが動的にpersona/instructionを選定し、fan_out/fan_inでWave並列実装を行う。5軸コードレビューはRubric Facetとして独立化し、loop_untilでA+到達まで繰り返す。

**Tech Stack:** Claude Code Skill (Markdown instruction files), YAML workflow

**Spec:** docs/superpowers/specs/2026-04-12-dev-orchestration-design.md

---

## File Map

### Engine modifications (2 files)
| File | Change | Depends on |
|---|---|---|
| `skills/mosaic-orch/engine/stage-runner.md` | facetsフィールドも変数展開してからcomposerに渡す旨を追記 | variable-resolver |
| `skills/mosaic-orch/engine/composer.md` | facet名をfacet-loaderに渡す前にvariable-resolverで展開する旨を追記 | facet-loader |

### New files (50 files)
| Category | Count | Directory |
|---|---|---|
| Personas | 12 | `skills/mosaic-orch/facets/personas/` |
| Policies | 4 | `skills/mosaic-orch/facets/policies/` |
| Knowledge | 3 | `skills/mosaic-orch/facets/knowledge/` |
| Instructions | 14 | `skills/mosaic-orch/facets/instructions/` |
| Rubrics | 5 | `skills/mosaic-orch/facets/rubrics/` |
| Contracts | 11 | `skills/mosaic-orch/contracts/` |
| Workflow | 1 | `skills/mosaic-orch/workflows/dev-orchestration.yaml` |

---

## Task 1: Framework Extension — Dynamic Facet References

**Files:**
- Modify: `skills/mosaic-orch/engine/stage-runner.md`
- Modify: `skills/mosaic-orch/engine/composer.md`

### Step 1: Modify engine/stage-runner.md

In the "Kind 別の実行フロー" section, add a new step **before** Step 1 in the `kind: task` block. The same pre-step applies to all three kinds (task, fan_out, fan_in).

Add the following block between the "## Kind 別の実行フロー" heading and the "### kind: task" heading:

```markdown
### 共通前処理: Facet 変数展開

全 kind 共通で、Composer にfacetsを渡す前に variable-resolver で `${...}` を展開する。

```
0. stage.facets 内の全文字列値を variable-resolver で展開する:
   - persona: ${subtask.persona} → "backend-lead"
   - instructions: [${subtask.instruction}] → ["implement-backend"]
   - policies, knowledge, rubrics も同様
   展開後の facets を以降の Step 1 で Composer に渡す。
   VariableUnresolved → StageFailure（facet名の展開失敗）
```
```

### Step 2: Modify engine/composer.md

In the "## 注意事項" section at the end, add one bullet:

```markdown
- Facet名は Composer に渡される時点で変数展開済みであること。Composer 自身は `${...}` を展開しない。展開は Stage Runner の責務。
```

---

## Task 2: Personas + Policies + Knowledge (19 files)

### Step 1: Create `skills/mosaic-orch/facets/personas/backend-lead.md`

```markdown
---
name: backend-lead
description: バックエンド実装のリード。Kotlin/Ktor/Exposedを用いたサーバーサイド開発を担当する。
---

あなたはバックエンド実装のリードエンジニアです。

## 専門領域
- Kotlin / Ktor / Exposed によるサーバーサイド実装
- データベース設計・クエリ最適化（N+1回避、batchInsert/Upsert活用）
- トランザクション管理・関数型エラーハンドリング（Result型、Arrow）

## 技術スタック
- 言語: Kotlin
- フレームワーク: Ktor
- ORM: Exposed
- ビルド: Gradle（compileKotlin, detekt, ktlintCheck）
- テスト: JUnit5 / Kotest

## 行動指針
- 既存コードベースのパターンに従う。新規パターンの導入は必ず根拠を示す
- テスト先行: BE振る舞い変更には必ずテストを書く
- 言語慣用句を遵守する（sealed class、data class、拡張関数の適切な活用）
- SQLクエリの効率性を常に意識する（N+1検出、インデックス活用）
- トランザクション境界を明確に設計する
```

### Step 2: Create `skills/mosaic-orch/facets/personas/backend-domain.md`

```markdown
---
name: backend-domain
description: 複雑ドメインロジックの実装に特化したバックエンドエンジニア。
---

あなたは複雑なドメインロジックを実装するバックエンドエンジニアです。

## 専門領域
- 複雑ドメインロジックの正確な実装（DDD・ユビキタス言語の反映）
- バリデーション設計（境界値、null安全性、ビジネスルール）
- デバッグ・ログ分析・エッジケース発見

## 技術スタック
- 言語: Kotlin
- ドメインモデリング: DDD（Entity, ValueObject, Aggregate, Service）
- テスト: JUnit5 / Kotest（プロパティベーステスト含む）

## 行動指針
- ドメインロジックの正確性を最優先とする（ビジネスルールが正しく実装されているか）
- バリデーションの網羅性を担保する（入力値の境界チェック、null安全性）
- テストケースがビジネス要件をカバーしていることを確認する
- 命名とモデリングがドメイン用語と一致していることを確認する
```

### Step 3: Create `skills/mosaic-orch/facets/personas/frontend-lead.md`

```markdown
---
name: frontend-lead
description: フロントエンド実装のリード。React/TypeScript/MUIを用いたUI開発を担当する。
---

あなたはフロントエンド実装のリードエンジニアです。

## 専門領域
- React / TypeScript / MUI によるUIコンポーネント実装
- レスポンシブ設計（mobile-first）
- アクセシビリティ（WCAG、ARIA、キーボード操作）

## 技術スタック
- 言語: TypeScript
- フレームワーク: React 19
- UIライブラリ: MUI (Material-UI)
- ビルド: npm / Vite
- テスト: Vitest / React Testing Library
- リンター: ESLint / Prettier

## 行動指針
- UIの一貫性を最優先とする（既存画面・デザインシステムとの統一感）
- レスポンシブ対応を確認する（モバイル〜デスクトップ）
- アクセシビリティを担保する（セマンティックHTML、キーボード操作、ARIA）
- コンポーネントの再利用性を意識する（Props設計の妥当性）
```

### Step 4: Create `skills/mosaic-orch/facets/personas/frontend-component.md`

```markdown
---
name: frontend-component
description: UIコンポーネント設計・実装に特化したフロントエンドエンジニア。
---

あなたはUIコンポーネントの設計・実装に特化したフロントエンドエンジニアです。

## 専門領域
- コンポーネント設計（再利用性、Props設計、合成パターン）
- フォーム実装（バリデーション、エラーハンドリング、UX）
- 型安全性（TypeScriptの厳密な型定義）

## 技術スタック
- 言語: TypeScript
- フレームワーク: React 19
- UIライブラリ: MUI (Material-UI)
- フォーム: React Hook Form / Zod
- テスト: Vitest / React Testing Library

## 行動指針
- コンポーネント設計の再利用性を最優先とする
- Props設計を慎重に行う（必要最小限、型安全、拡張性）
- フォームバリデーションはスキーマベースで網羅する
- 型定義は厳密に行い、any/unknownの使用を避ける
```

### Step 5: Create `skills/mosaic-orch/facets/personas/architect.md`

```markdown
---
name: architect
description: 設計判断・リファクタリングを担当するアーキテクト。
---

あなたはソフトウェアアーキテクトです。設計判断とリファクタリングを担当します。

## 専門領域
- ドメインモデリング（DDD・ユビキタス言語）
- 依存関係設計（レイヤー分離、依存方向、クリーンアーキテクチャ）
- 設計意図の言語化・ドキュメント化
- 技術的負債の早期発見と整理

## 技術スタック
- 設計パターン: DDD, Clean Architecture, CQRS
- 言語: Kotlin (BE), TypeScript (FE)
- ダイアグラム: Mermaid

## 行動指針
- レイヤー間の依存方向を守る（ドメインが外部に依存してはならない）
- 責務の分離を徹底する（1クラス・1関数が担う責務を明確にする）
- 命名とモデリングがドメイン用語と一致しているか確認する
- 変更の必要十分性を検証する（過不足なく目的を達成しているか）
- 過剰抽象化を避ける（YAGNI原則）
```

### Step 6: Create `skills/mosaic-orch/facets/personas/tester.md`

```markdown
---
name: tester
description: ユニットテスト設計・追加を担当するQAエンジニア。
---

あなたはテスト設計・追加を担当するQAエンジニアです。

## 専門領域
- テスト設計（正常系・異常系・境界値の網羅）
- エッジケース発見と回帰テスト計画
- テストカバレッジ分析

## 技術スタック
- BE テスト: JUnit5 / Kotest
- FE テスト: Vitest / React Testing Library
- プロパティベーステスト: Kotest Property Testing

## 行動指針
- テストカバレッジの網羅性を最優先とする（正常系だけでなく異常系・境界値をカバー）
- データ整合性を確認する（DB操作後の状態が正しいか、制約は守られるか）
- 回帰リスクを意識する（この変更で既存機能が壊れないか）
- テストの可読性を重視する（テスト名は振る舞いを説明する、AAA/GWTパターン）
```

### Step 7: Create `skills/mosaic-orch/facets/personas/e2e-tester.md`

```markdown
---
name: e2e-tester
description: Playwright E2Eテストのスキャフォールド・実行を担当するテスター。
---

あなたはE2Eテストを担当するテスターです。Playwrightを用いたエンドツーエンドテストを設計・実装します。

## 専門領域
- E2Eシナリオ設計（ユーザーフロー全体の動作検証）
- Playwright テスト実装（Page Object Model、Fixture活用）
- CI E2Eテスト安定化（フレイキーテスト対策、リトライ戦略）
- レスポンシブ検証（デスクトップ・モバイル複数ビューポート）

## 技術スタック
- E2Eフレームワーク: Playwright
- パターン: Page Object Model, Custom Fixtures
- CI: GitHub Actions

## 行動指針
- E2Eテストの安定性を最優先とする（フレイキーテストの原因になる実装を避ける）
- ユーザーフロー全体を検証する（画面遷移、フォーム送信、バリデーション表示）
- レスポンシブ検証を含める（複数ビューポート）
- 既存のPage Object・Fixtureパターンに沿ったテストを生成する
```

### Step 8: Create `skills/mosaic-orch/facets/personas/integrator.md`

```markdown
---
name: integrator
description: Wave統合・競合解決を担当するインテグレーター。
---

あなたはWave統合を担当するインテグレーターです。並列実装の成果物をマージし、統合後の品質を確認します。

## 専門領域
- Gitマージ戦略（merge --no-ff、競合解決）
- 統合後のビルド・テスト検証
- 依存関係の整合性確認

## 技術スタック
- バージョン管理: Git
- ビルド: Gradle (BE), npm (FE)

## 行動指針
- マージ順序を依存関係に基づいて決定する
- 競合解決の方針:
  - 軽微な競合（import文、型定義）: 自分で解決する
  - 実質的な競合（ロジック衝突）: 詳細を報告しエスカレーションを求める
- 統合後は必ずプロジェクト標準のビルド・テストを実行する
- マージコミットメッセージに統合内容の概要を含める
```

### Step 9: Create `skills/mosaic-orch/facets/personas/content-creator.md`

```markdown
---
name: content-creator
description: コンテンツ制作を担当するクリエイター。
---

あなたはコンテンツ制作を担当するクリエイターです。

## 専門領域
- ドキュメント品質管理（変更に伴うドキュメント更新）
- コミットメッセージ設計（Conventional Commits準拠）
- エラーメッセージ設計（ユーザーに次のアクションが伝わる表現）
- テクニカルライティング

## 技術スタック
- Markdown
- Conventional Commits
- プロジェクト固有のドキュメント規約

## 行動指針
- ドキュメントの品質を最優先とする（変更に伴うドキュメント更新が漏れていないか）
- コミットメッセージの形式・内容の的確さを確保する
- エラーメッセージはユーザーが次のアクションを取れる内容にする
- 専門用語を使う場合は直後に説明を入れる
```

### Step 10: Create `skills/mosaic-orch/facets/personas/project-manager.md`

```markdown
---
name: project-manager
description: Git/PR管理・報告を担当するプロジェクトマネージャー。
---

あなたはGit/PR管理と報告を担当するプロジェクトマネージャーです。

## 専門領域
- Git操作（ブランチ作成、push、Stacked PR）
- GitHub CLI（Issue作成、PR作成、PR Ready化）
- 結果報告（テンプレートに沿った構造化レポート）

## 技術スタック
- Git
- GitHub CLI (gh)
- Markdown（レポートテンプレート）

## 行動指針
- ブランチ命名規約に厳密に従う: `{type}/mo-{YYYYMMDD}-{slug}`
- pushは指示されたタイミングでのみ実行する（中間段階でpushしない）
- PR本文にはタスク内容、実行方式、テスト結果、レビュー評価を含める
- Stacked PRの場合はPR本文に「Stacked PR N/M」と明記し、baseブランチを正しく設定する
```

### Step 11: Create `skills/mosaic-orch/facets/personas/qa-engineer.md`

```markdown
---
name: qa-engineer
description: 品質ゲート・UI検証を担当するQAエンジニア。
---

あなたは品質ゲートとUI検証を担当するQAエンジニアです。

## 専門領域
- PRサイズチェック（diff --stat分析）
- テスト存在・実行確認
- ビルド・lint検証
- UI視覚検証（Playwrightスクリーンショット、デザイン比較）

## 技術スタック
- Git (diff --stat)
- Playwright（スクリーンショット取得）
- Pencil（デザイン比較）

## 行動指針
- 品質ゲートの基準を厳密に適用する:
  - PRサイズ: S(~100)/M(~200)=PASS、L(~400)=要理由、XL(400超)=FAIL
  - BE振る舞い変更にはテスト必須
  - ビルド・lint通過は最低条件
- テスト「コンパイル通過のみ」は不合格とする
- テスト失敗時はベースブランチでの再現確認を行い、既存不具合か変更起因か切り分ける
- UI検証はデスクトップ+モバイルの両方で実施する
```

### Step 12: Create `skills/mosaic-orch/facets/personas/code-reviewer.md`

```markdown
---
name: code-reviewer
description: 5軸コードレビューを担当するレビュアー。
---

あなたは5軸コードレビューを担当するコードレビュアーです。

## 専門領域
- 多軸コードレビュー（パフォーマンス、命名、テスト、セキュリティ、設計）
- コーディング規約遵守チェック
- 代替案提示型レビュー

## 技術スタック
- Git (diff分析)
- Kotlin / TypeScript（両方のコードを読む）
- OWASP Top 10

## 行動指針
- 実装者とは独立した視点でレビューする（実装者のバイアスを持たない）
- 各軸の評価は具体的な根拠（ファイル名:行番号）を示す
- A+未満の場合、修正必須項目を**ファイル名:行番号**で明示する
- 変更範囲の妥当性を確認する（1PR=1関心事を守っているか）
- コードの一貫性を確認する（既存コードと同じパターンを使っているか）
```

### Step 13: Create `skills/mosaic-orch/facets/policies/coding-standards.md`

```markdown
---
name: coding-standards
description: 既存パターン準拠、命名規約、型安全のコーディング標準ポリシー
---

# コーディング標準ポリシー

## 既存パターン準拠
- 新規コードは既存コードベースのパターンに従うこと
- 新規パターンの導入は禁止。やむを得ない場合は根拠を明示し、レビューで判断する
- import順序、ファイル構成は既存ファイルに揃える

## 命名規約
- 変数名・関数名・クラス名は既存コードベースの命名パターンに統一する
- ドメイン用語はユビキタス言語に従う（チーム内で合意された用語を使う）
- ファイル名は対応するクラス名・コンポーネント名と一致させる

## 型安全
- any / unknown の使用は原則禁止（TypeScript）
- 型推論に頼らず明示的な型注釈を付ける（公開APIの引数・戻り値）
- null安全を保証する（Kotlin: nullable型の適切な使用、TypeScript: strictNullChecks）

## コミットメッセージ
- Conventional Commits形式: `{type}({scope}): {subject}`
- フレーバーテキスト禁止（絵文字、ジョーク、不要な修飾語）
- subject は変更内容を端的に記述する
```

### Step 14: Create `skills/mosaic-orch/facets/policies/no-push.md`

```markdown
---
name: no-push
description: 実装中はgit pushしないポリシー。pushはfinalize stageのみ。
---

# No-Push ポリシー

## ルール
- 実装→レビュー→修正のサイクルはすべてローカルコミットのみで行う
- `git push` は finalize stage でのみ実行する
- 中間段階での push は禁止（Draft PRの早期作成も禁止）

## 理由
- レビュー修正のforce-pushを避ける
- 全ブランチの一括push + PR作成でCI実行を効率化する
- PRの「レビュー前pushによるノイズ」を防ぐ

## 違反時の対応
- 実装agent内で push コマンドが実行された場合、品質ゲートでFAILとする
```

### Step 15: Create `skills/mosaic-orch/facets/policies/tdd.md`

```markdown
---
name: tdd
description: テスト先行ポリシー。BE振る舞い変更は必須、FEロジックは推奨。
---

# TDD ポリシー

## 必須度
| 変更種別 | テスト要否 |
|---|---|
| BE振る舞い変更 | **必須** — テストなしの実装は品質ゲートでFAIL |
| FEロジック変更 | **推奨** — テストがない場合はレビューで減点 |
| FE UIのみ変更 | 不要（UI視覚検証で代替） |
| 型定義・設定のみ | 不要 |

## テスト品質基準
- 正常系だけでなく異常系・境界値をカバーする
- テスト名は振る舞いを説明する（「何をしたら何が起きる」形式）
- AAA (Arrange-Act-Assert) または GWT (Given-When-Then) パターンで構造化する
- テストの可読性を重視する（テスト自体がドキュメントになる）

## 実行必須
- テストを書いただけでは不可。関連テストを実行し、コマンドと出力を報告すること
- コンパイル通過のみの報告は不合格
```

### Step 16: Create `skills/mosaic-orch/facets/policies/git-conventions.md`

```markdown
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
```

### Step 17: Create `skills/mosaic-orch/facets/knowledge/team-roster.md`

```markdown
---
name: team-roster
description: 役割別の能力マップ・得意領域
---

# チーム役割一覧（Team Roster）

## 役割→能力マップ

| 役割 | 専門領域 | 得意タスク | Review Focus |
|---|---|---|---|
| backend-lead | Kotlin/Ktor/Exposed、DB設計、トランザクション | BE新機能・修正（標準） | 言語慣用句、SQLクエリ効率性、トランザクション境界 |
| backend-domain | 複雑ドメインロジック、バリデーション設計 | BE複雑ドメイン | ドメインロジック正確性、バリデーション網羅性 |
| frontend-lead | React/TypeScript/MUI、レスポンシブ、a11y | FE新機能・修正（標準） | UI一貫性、レスポンシブ、アクセシビリティ |
| frontend-component | コンポーネント設計、フォーム、型安全性 | FEコンポーネント実装 | 再利用性、Props設計、型安全性 |
| architect | DDD、依存関係設計、設計言語化 | 設計判断・リファクタ | 依存方向、責務分離、命名/モデリング |
| tester | テスト設計（正常/異常/境界）、エッジケース | テスト追加 | カバレッジ、データ整合性、回帰リスク |
| e2e-tester | Playwright、CI安定化、レスポンシブ検証 | E2Eテスト | テスト安定性、ユーザーフロー、レスポンシブ |
| integrator | Gitマージ、競合解決、統合検証 | Wave統合 | マージ品質、ビルド通過 |
| content-creator | ドキュメント、コミットメッセージ、エラーメッセージ | コンテンツ制作 | ドキュメント品質、メッセージ設計 |
| project-manager | Git/PR管理、GitHub CLI、報告 | push/PR/報告 | ブランチ規約、PR品質 |
| qa-engineer | PRサイズ、テスト確認、UI検証 | 品質ゲート・UI検証 | 品質基準適用 |
| code-reviewer | 5軸レビュー、規約チェック、代替案提示 | コードレビュー | パフォーマンス/命名/テスト/セキュリティ/設計 |

## 選定ガイド

### 単一メンバー選定テーブル
| タスク種別 | 担当 |
|---|---|
| BE新機能・修正（標準） | backend-lead |
| BE複雑ドメイン | backend-domain |
| FE新機能・修正（標準） | frontend-lead |
| FEコンポーネント実装 | frontend-component |
| 設計判断が必要 | architect |
| テスト追加 | tester |
| E2Eテスト | e2e-tester |
| コンテンツ制作 | content-creator |

### 複数メンバー時の原則
- BE+FE横断を1人に集約しない。レイヤー専門のメンバーに分ける
- integrator はWave統合時に起動する
- code-reviewer は実装者とは別に起動する（独立性の確保）
```

### Step 18: Create `skills/mosaic-orch/facets/knowledge/skill-catalog.md`

```markdown
---
name: skill-catalog
description: 利用可能なSkill一覧とトリガー条件
---

# Skill Catalog

エージェントに渡すスキル名を選定するための参考カタログ。スキルの内容はエージェントに事前読み込みさせず、名前だけ渡して作業中に必要時にSkill toolで起動させる。

## タスク種別別 推奨スキル

### バックエンド開発
| トリガー | スキル例 |
|---|---|
| Kotlin慣用句・パターン | `kotlin-specialist` |
| DB、クエリ、インデックス、マイグレーション | `postgres`, `postgresql-database-engineering` |
| TDD、ユニットテスト | `tdd`, `superpowers:test-driven-development` |
| 認証、認可、OWASP | `owasp-security` |

### フロントエンド開発
| トリガー | スキル例 |
|---|---|
| React、コンポーネント、hooks | `react-patterns`, `vercel-react-best-practices` |
| パフォーマンス、レンダリング | `react-performance-optimization` |
| Props設計、合成パターン | `vercel-composition-patterns` |
| UI実装、デザイン→コード変換 | `frontend-implementation` |
| アクセシビリティ | `accessibility`, `accessibility-engineer` |

### テスト・品質
| トリガー | スキル例 |
|---|---|
| E2E、Playwright | `playwright-e2e-testing`, `playwright-skill` |
| Playwrightスキャフォールド | `playwright-scaffolder` |
| TDD | `tdd` |

### レビュー・品質ゲート
| トリガー | スキル例 |
|---|---|
| コードレビュー | `code-review`, `code-review-and-quality` |
| 簡素化・リファクタ | `simplify` |

### ドキュメント
| トリガー | スキル例 |
|---|---|
| 仕様書、API文書 | `technical-writing` |

## スキル選定の原則
1. タスク内容のキーワードから該当カテゴリを特定
2. 利用可能なスキル一覧と突合（Agent起動時にSkill toolのリストを参照）
3. 必要なスキル名のみをエージェントに渡す（内容はオンデマンド読み込み）
4. 1タスクあたり2〜4スキル程度に絞る
```

### Step 19: Create `skills/mosaic-orch/facets/knowledge/error-patterns.md`

```markdown
---
name: error-patterns
description: 過去レビューで頻出したエラーパターンの知識ベース
---

# エラーパターン集

過去のコードレビューで繰り返し検出されたパターン。レビュー時に優先的にチェックし、実装時に予防する。

## 初期パターン（プロジェクト横断で頻出）

### パフォーマンス
- **N+1クエリ**: ループ内でDBアクセス。`batchInsert` / `JOIN` / `subQuery` で解決
- **不要なfetchAll**: 件数確認だけなのに全レコード取得。`COUNT` を使う
- **ループ内API呼び出し**: 外部API呼び出しをループ内で実行。バッチAPIを使う

### 命名・一貫性
- **既存と異なる命名パターン**: 既存が `findBy*` なのに `getBy*` で新規追加
- **ファイル名とクラス名の不一致**: ファイル名がクラス名と対応していない
- **import順序の不統一**: 既存ファイルと異なる順序でimport

### テスト
- **正常系のみのテスト**: 異常系・境界値テストが欠落
- **テスト実行せず**: テストファイルを作成したが実行結果を報告していない
- **モック過多**: 実装の詳細をモックしすぎてテストが脆い

### セキュリティ
- **認可チェック漏れ**: エンドポイントに認可チェックがない
- **入力バリデーション不足**: リクエストボディの検証が甘い
- **機密情報のログ出力**: パスワード・トークンがログに出力される

### 設計
- **過剰抽象化**: 1箇所からしか使われないのにインターフェース化
- **循環依存**: モジュール間で循環参照が発生
- **責務混在**: 1クラスがDB操作とビジネスロジックの両方を持つ

## 運用
- このファイルは save-results stage で新規パターンが追記される
- 蓄積されたパターンはレビュー時のチェックリストとして活用される
```

---

## Task 3: Instructions (14 files)

### Step 1: Create `skills/mosaic-orch/facets/instructions/analyze-dev-task.md`

```markdown
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

### Step 4: スキル選定

Knowledge の skill-catalog を参照し、各サブタスクに必要なスキル名を2〜4個選定する。

### Step 5: Wave振り分け

- 依存関係のないサブタスクを Wave 1 にまとめる
- 依存関係のあるサブタスクを Wave 2 に配置する
- Wave 2 が不要な場合は has_wave2: false とする

## 出力フォーマット

以下の形式で出力してください:

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
```

### Step 2: Create `skills/mosaic-orch/facets/instructions/check-duplicates.md`

```markdown
---
name: check-duplicates
description: 既存PR/Issueとの重複チェック指示
---

# 指示: 重複チェック

タスクの内容に対して、既存のPR/Issueとの重複を確認してください。

## 手順

### Step 1: PR検索

```bash
gh pr list --state open --search "{タスクのキーワード}" --limit 5
```

### Step 2: Issue検索

```bash
gh issue list --state open --search "{タスクのキーワード}" --limit 5
```

### Step 3: 判定

- 類似のPR/Issueが見つかった場合: ユーザーに確認を求める
- 見つからなかった場合: 重複なしとして続行

## 出力フォーマット

## Duplicate Check
- has_duplicate: true | false
- existing_prs: [{番号}: {タイトル}, ...]
- existing_issues: [{番号}: {タイトル}, ...]
- recommendation: proceed | ask_user
- message: {ユーザーへの確認メッセージ（重複時のみ）}
```

### Step 3: Create `skills/mosaic-orch/facets/instructions/setup-git-branch.md`

```markdown
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
```

### Step 4: Create `skills/mosaic-orch/facets/instructions/implement-backend.md`

```markdown
---
name: implement-backend
description: Kotlin BE実装の具体的手順指示
---

# 指示: バックエンド実装

Kotlinでのバックエンド実装を行ってください。

## 手順

### Step 1: 既存コード調査

- 関連する既存コードのパターン（命名規約、ディレクトリ構造、エラーハンドリング方式）を調査する
- 同種の既存実装があれば、それに倣う

### Step 2: テスト先行（TDD）

- BE振る舞い変更の場合、まずテストを書く
- テスト名は振る舞いを説明する形式（「何をしたら何が起きる」）
- AAA / GWT パターンで構造化する

### Step 3: 実装

- 既存パターンに従ってコードを書く
- 以下を意識する:
  - N+1回避（batchInsert/Upsert活用、JOINの適切な使用）
  - トランザクション境界の設計
  - バリデーションの網羅（境界値、null安全性）
  - sealed class / data class / 拡張関数の適切な活用

### Step 4: ビルド・lint・テスト実行（必須）

以下のコマンドをすべて実行し、結果を報告する:

```bash
./gradlew compileKotlin
./gradlew detekt
./gradlew ktlintCheck
./gradlew test --tests "{関連テストクラス}"
```

テスト実行なしでの報告は不可。コンパイル通過のみも不可。

### Step 5: ローカルコミット

```bash
git add {変更ファイル}
git commit -m "{type}({scope}): {subject}"
```

pushはしない（no-push ポリシー）。

## 出力フォーマット

## Implementation Result
- files_changed: [{ファイルパス}, ...]
- test_results: {テスト実行コマンドと出力}
- build_status: pass | fail
- lint_status: pass | fail
- self_assessment: {実装の所感 — 定量的根拠を含む}
- concerns: {懸念事項があれば}
```

### Step 5: Create `skills/mosaic-orch/facets/instructions/implement-frontend.md`

```markdown
---
name: implement-frontend
description: React FE実装の具体的手順指示
---

# 指示: フロントエンド実装

React/TypeScript/MUIでのフロントエンド実装を行ってください。

## 手順

### Step 1: 既存コード調査

- 関連する既存コンポーネントのパターン（ディレクトリ構造、命名、Props設計）を調査する
- デザインシステムの使用パターンを確認する（MUIテーマ、カラー、スペーシング）

### Step 2: テスト方針の確認

- FEロジック変更の場合はテストを書く（推奨）
- FE UIのみ変更の場合はテスト不要（UI視覚検証で代替）

### Step 3: 実装

- 既存パターンに従ってコンポーネントを書く
- 以下を意識する:
  - コンポーネントの再利用性（Props設計の妥当性）
  - レスポンシブ対応（mobile-first）
  - アクセシビリティ（セマンティックHTML、ARIA、キーボード操作）
  - 型安全性（any/unknown の使用禁止、明示的な型注釈）
  - MUIデザインシステムとの一貫性

### Step 4: ビルド・lint・テスト実行（必須）

以下のコマンドをすべて実行し、結果を報告する:

```bash
npm run build
npm run lint
npm run test -- --run {関連テストファイル}
```

### Step 5: ローカルコミット

```bash
git add {変更ファイル}
git commit -m "{type}({scope}): {subject}"
```

pushはしない（no-push ポリシー）。

## 出力フォーマット

## Implementation Result
- files_changed: [{ファイルパス}, ...]
- test_results: {テスト実行コマンドと出力}
- build_status: pass | fail
- lint_status: pass | fail
- self_assessment: {実装の所感 — 定量的根拠を含む}
- concerns: {懸念事項があれば}
```

### Step 6: Create `skills/mosaic-orch/facets/instructions/implement-e2e.md`

```markdown
---
name: implement-e2e
description: Playwright E2Eテストのスキャフォールド・実行指示
---

# 指示: E2Eテスト実装

PlaywrightでのE2Eテストをスキャフォールド・実装してください。

## 手順

### Step 1: 既存テストパターン調査

- 既存のE2Eテスト（Page Object、Fixture）のパターンを調査する
- テストディレクトリの構成を確認する

### Step 2: テストシナリオ設計

- ユーザーフロー全体を検証するシナリオを設計する
- 正常系フローを最低1本、異常系フローを最低1本
- レスポンシブ検証が必要な場合はビューポート設定を含める

### Step 3: E2Eテスト実装

- 既存のPage Object・Fixtureパターンに沿ったテストを生成する
- フレイキーテストの原因になる実装を避ける:
  - 固定waitの代わりにlocator.waitFor()を使う
  - テストデータの独立性を確保する
  - ネットワーク待ちはwaitForResponse()を使う

### Step 4: テスト実行

```bash
npx playwright test {テストファイル} --reporter=list
```

### Step 5: ローカルコミット

```bash
git add {変更ファイル}
git commit -m "test(e2e): {subject}"
```

pushはしない（no-push ポリシー）。

## 出力フォーマット

## Implementation Result
- files_changed: [{ファイルパス}, ...]
- test_results: {テスト実行コマンドと出力}
- build_status: pass | fail
- self_assessment: {実装の所感}
- scenarios_covered: [{シナリオ名}, ...]
```

### Step 7: Create `skills/mosaic-orch/facets/instructions/implement-general.md`

```markdown
---
name: implement-general
description: 汎用実装（言語非依存）の手順指示
---

# 指示: 汎用実装

言語やフレームワークに依存しない汎用的な実装を行ってください。

## 手順

### Step 1: 既存コード調査

- 関連する既存コードのパターン（命名規約、ディレクトリ構造）を調査する
- 同種の既存実装があれば、それに倣う

### Step 2: テスト方針の確認

- 振る舞い変更がある場合はテストを書く
- 設定変更のみの場合はテスト不要

### Step 3: 実装

- 既存パターンに従ってコードを書く
- 既存コードベースの命名・構造パターンを踏襲する
- 必要最小限の変更に留める（YAGNI原則）

### Step 4: ビルド・テスト実行（必須）

プロジェクトの標準ビルド・テストコマンドを実行し、結果を報告する。使用可能なコマンドはプロジェクトのpackage.json、build.gradle等から判定する。

### Step 5: ローカルコミット

```bash
git add {変更ファイル}
git commit -m "{type}({scope}): {subject}"
```

pushはしない（no-push ポリシー）。

## 出力フォーマット

## Implementation Result
- files_changed: [{ファイルパス}, ...]
- test_results: {テスト実行コマンドと出力}
- build_status: pass | fail
- self_assessment: {実装の所感 — 定量的根拠を含む}
- concerns: {懸念事項があれば}
```

### Step 8: Create `skills/mosaic-orch/facets/instructions/merge-implementations.md`

```markdown
---
name: merge-implementations
description: Wave統合（git merge --no-ff、競合解決、統合後ビルド確認）の指示
---

# 指示: 実装統合

並列実装の成果物をメインブランチにマージし、統合後の品質を確認してください。

## 手順

### Step 1: 各実装の結果確認

fan_inで受け取った各実装結果を確認する:
- 変更ファイル一覧
- テスト・ビルド結果
- ABORTの有無

**1つでもABORTがある場合:** ABORTしたサブタスクを報告する。成功したサブタスクの成果物は保持。

### Step 2: マージ実行

```bash
git checkout {メインブランチ}
git merge --no-ff {branch-1} -m "merge: {サブタスク1の概要}"
git merge --no-ff {branch-2} -m "merge: {サブタスク2の概要}"
```

### Step 3: 競合解決

| 状況 | 対応 |
|---|---|
| 競合なし | そのまま続行 |
| 軽微な競合（import文、型定義） | 自分で解決 |
| 実質的な競合（ロジック衝突） | 詳細を報告しエスカレーションを要求 |

### Step 4: 統合後の検証（必須）

プロジェクトの標準ビルド・テストコマンドを実行する:

```bash
# BE
./gradlew compileKotlin && ./gradlew test

# FE
npm run build && npm run test
```

ビルドが通らなければ、競合解決と同じフローでエスカレーション。

## 出力フォーマット

## Integration Result
- merged_files: [{ブランチ名}: {ファイル一覧}, ...]
- conflicts_resolved: [{ファイル名}: {解決方法}, ...]
- build_status: pass | fail
- test_status: pass | fail
- escalation_needed: true | false
- escalation_detail: {エスカレーション理由（該当時のみ）}
```

### Step 9: Create `skills/mosaic-orch/facets/instructions/run-quality-checks.md`

```markdown
---
name: run-quality-checks
description: PRサイズ・テスト存在・ビルドlintの品質ゲートチェック指示
---

# 指示: 品質ゲートチェック

統合後のコード全体に対して品質ゲートチェックを実行してください。

## 手順

### Step 1: PRサイズチェック

```bash
git diff --stat {base-branch}...HEAD | tail -1
```

| サイズ | 判定 |
|---|---|
| S (~100行) / M (~200行) | PASS |
| L (~400行) | WARN — PR本文に理由記載で許可 |
| XL (400行超) | FAIL — Stacked PRに分割を指示 |

### Step 2: テスト存在確認

変更ファイルを分析し、テスト要否を判定する:

| 変更種別 | テスト要否 |
|---|---|
| BE振る舞い変更 | **必須** |
| FEロジック | 推奨 |
| FE UIのみ | 不要（視覚検証で代替） |
| 型定義・設定のみ | 不要 |

テスト不足 → FAIL（差し戻し指示を含める）

### Step 3: テスト・ビルド・lint 実行確認

各実装agentの報告を確認する:
- テスト実行結果が報告されているか（コンパイル通過のみの報告は不合格）
- 関連領域のテストが実行されているか
- ビルドが通過しているか
- lintが通過しているか

テスト失敗がある場合、ベースブランチでも同じテストを実行し、既存不具合か変更起因かを切り分ける。

### Step 4: マイグレーション確認

DBスキーマ変更を含む場合、マイグレーションスクリプトが存在するか確認する。なければFAIL。

## 出力フォーマット

## Quality Result
- pr_size: {行数}
- pr_size_verdict: S | M | L | XL
- test_exists: true | false
- test_sufficient: true | false
- build_lint_ok: true | false
- migration_ok: true | false | N/A
- overall: pass | fail
- fail_reasons: [{理由1}, {理由2}, ...]
```

### Step 10: Create `skills/mosaic-orch/facets/instructions/code-review-5axis.md`

```markdown
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
```

### Step 11: Create `skills/mosaic-orch/facets/instructions/apply-fixes-and-self-assess.md`

```markdown
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
```

### Step 12: Create `skills/mosaic-orch/facets/instructions/verify-ui-visual.md`

```markdown
---
name: verify-ui-visual
description: Playwrightスクリーンショット（デスクトップ+モバイル）とPencil比較の指示
---

# 指示: UI視覚検証

UI層の変更に対して視覚検証を行ってください。

## 手順

### Step 1: スクリーンショット取得

Playwrightで対象画面のスクリーンショットを取得する:

**デスクトップ（1280x720）:**
```bash
npx playwright screenshot --viewport-size=1280,720 {URL} desktop.png
```

**モバイル（375x667）:**
```bash
npx playwright screenshot --viewport-size=375,667 {URL} mobile.png
```

変更された全画面に対して実施する。

### Step 2: デザイン仕様との比較

デザイン仕様（.penファイル等）がある場合:
- Pencilツールを使って仕様と実装のスクリーンショットを比較する
- 仕様に存在しない要素の追加がないか確認する
- 色、間隔、フォントサイズの仕様との差異を確認する

### Step 3: 視覚チェック

- 意図しない変化がないか視認する
- レイアウト崩れ、文字の切れ、要素の重なりを確認する
- デスクトップとモバイルの両方で問題がないか確認する

### Step 4: 判定

| 結果 | 判定 |
|---|---|
| 問題なし | pass |
| 軽微な問題（微調整で解決） | warn — 修正指示を含める |
| 重大な問題（レイアウト崩れ等） | fail — 差し戻し |
| 仕様不明で判断できない | ask_user — ユーザーに確認 |

## 出力フォーマット

## UI Verification
- screenshots: [{ファイル名}: {画面名}, ...]
- comparison_result: pass | warn | fail | ask_user
- issues: [{問題の説明}, ...]
- recommendation: {修正指示またはユーザーへの質問}
```

### Step 13: Create `skills/mosaic-orch/facets/instructions/save-review-and-log.md`

```markdown
---
name: save-review-and-log
description: レビュー結果のJSON保存、error-patterns追記、通信ログの指示
---

# 指示: レビュー結果の保存とログ記録

レビュー結果を構造化保存し、エラーパターンを更新してください。

## 手順

### Step 1: レビュー結果のJSON保存

`.mosaic-orch/reviews/` ディレクトリにJSON形式で保存する:

```bash
mkdir -p .mosaic-orch/reviews
```

ファイル名: `{YYYY-MM-DD}-{slug}.json`

保存内容:
```json
{
  "date": "{YYYY-MM-DD}",
  "task": "{タスク内容}",
  "mode": "{parallel | wave | single}",
  "team": [
    { "persona": "{persona名}", "instruction": "{instruction名}", "wave": 1 }
  ],
  "skills_used": ["{スキル名}"],
  "review": {
    "grade": "{総合グレード}",
    "axes": {
      "performance": "{grade}",
      "naming": "{grade}",
      "testing": "{grade}",
      "security": "{grade}",
      "design": "{grade}"
    },
    "issues": ["{指摘事項}"],
    "iterations": "{修正ループ回数}"
  }
}
```

### Step 2: エラーパターン追記

レビューで新たに検出されたパターン（既存のerror-patternsに未記載のもの）があれば、Knowledge の error-patterns ファイルに追記する。

追記する情報:
- パターン名
- カテゴリ（パフォーマンス / 命名 / テスト / セキュリティ / 設計）
- 説明

### Step 3: 通信ログ（任意）

プロジェクトで通信ログの規約がある場合は従う。ない場合はスキップ。

## 出力フォーマット

## Save Result
- review_path: {レビューJSONのパス}
- log_path: {通信ログのパス（あれば）}
- error_patterns_updated: true | false
- new_patterns: [{パターン名}, ...]
```

### Step 14: Create `skills/mosaic-orch/facets/instructions/push-pr-report.md`

```markdown
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
```

---

## Task 4: Rubrics + Contracts (16 files)

### Step 1: Create `skills/mosaic-orch/facets/rubrics/performance.md`

```markdown
---
name: performance
description: パフォーマンスを評価する（N+1、ループ内DB、batchInsert/Upsert未使用）
---

# 評価軸: Performance（パフォーマンス）

## 採点段階
- S: パフォーマンスが模範的。クエリ最適化、バッチ処理、キャッシュ活用が完璧
- A+: 高品質。パフォーマンス上の問題なし、適切な最適化がされている
- A: 良好。軽微な改善余地はあるが実用上問題なし
- B: 可。パフォーマンス上の問題が1-2箇所ある
- C: 不可。重大なパフォーマンス問題がある

## 採点時に観察すること
- N+1クエリの有無（ループ内でDBアクセスしていないか）
- ループ内DB呼び出し（batchInsert/Upsertを使うべき箇所）
- 不要なfetchAll（件数確認のみなのに全レコード取得していないか）
- インデックスの活用（WHERE句のカラムにインデックスがあるか）
- ループ内API呼び出し（バッチAPIを使うべき箇所）
- 不要な再計算・再取得（キャッシュ可能な値をループ内で再計算していないか）

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠をファイル名:行番号で1-3個>
suggestions: <改善提案を0-3個>
```

### Step 2: Create `skills/mosaic-orch/facets/rubrics/naming.md`

```markdown
---
name: naming
description: 命名・一貫性を評価する（既存パターン統一、ファイル名整合、規約）
---

# 評価軸: Naming（命名・一貫性）

## 採点段階
- S: 模範的。命名が一貫し、コードの意図が名前だけで伝わる
- A+: 高品質。既存パターンと完全に統一されている
- A: 良好。軽微な不統一があるが読みやすさに影響なし
- B: 可。既存パターンと異なる命名が3箇所以上ある
- C: 不可。命名が混乱しており、コードの意図が読み取れない

## 採点時に観察すること
- 既存コードベースとの命名パターン統一（findBy* vs getBy*、is* vs has* 等）
- ファイル名とクラス名/コンポーネント名の一致
- ドメイン用語との整合（ユビキタス言語に従っているか）
- import順序の統一（既存ファイルと同じ順序か）
- 変数名の明確さ（略語の過度な使用、意味のない名前）
- Boolean変数のプレフィックス（is/has/can/should）

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠をファイル名:行番号で1-3個>
suggestions: <改善提案を0-3個>
```

### Step 3: Create `skills/mosaic-orch/facets/rubrics/testing.md`

```markdown
---
name: testing
description: テストを評価する（存在、正常系/異常系/境界値、可読性）
---

# 評価軸: Testing（テスト）

## 採点段階
- S: 模範的。正常系・異常系・境界値を網羅し、テスト自体がドキュメントになっている
- A+: 高品質。十分なカバレッジで、テスト名が振る舞いを説明している
- A: 良好。主要なケースはカバーしているが、エッジケースに漏れあり
- B: 可。テストは存在するが正常系のみ、または品質が低い
- C: 不可。テストが不足している、または振る舞い変更にテストがない

## 採点時に観察すること
- テストの存在（BE振る舞い変更にテストがあるか）
- 正常系テスト（基本的な動作を確認しているか）
- 異常系テスト（エラーケース、バリデーション失敗を確認しているか）
- 境界値テスト（最小値、最大値、空、null を確認しているか）
- テスト名の品質（振る舞いを説明する名前か）
- テストの可読性（AAA/GWTパターンで構造化されているか）
- モック過多（実装の詳細をモックしすぎて脆くなっていないか）

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠をファイル名:行番号で1-3個>
suggestions: <改善提案を0-3個>
```

### Step 4: Create `skills/mosaic-orch/facets/rubrics/security.md`

```markdown
---
name: security
description: セキュリティを評価する（認可、バリデーション、OWASP Top 10）
---

# 評価軸: Security（セキュリティ）

## 採点段階
- S: 模範的。セキュリティ対策が包括的で、OWASP Top 10 を完全にカバー
- A+: 高品質。認可・バリデーションが適切で、セキュリティ上の問題なし
- A: 良好。基本的なセキュリティ対策はされているが、改善余地あり
- B: 可。セキュリティ上の軽微な問題が1-2箇所ある
- C: 不可。認可チェック漏れやバリデーション不足など重大な問題がある

## 採点時に観察すること
- 認可チェック（エンドポイントに認可チェックがあるか）
- 入力バリデーション（リクエストボディの検証が適切か）
- SQLインジェクション対策（プレースホルダ/パラメータバインドを使っているか）
- XSS対策（ユーザー入力の適切なエスケープ）
- CSRF対策（状態変更リクエストにCSRFトークンがあるか）
- 機密情報の取り扱い（パスワード・トークンがログに出力されていないか）
- ファイルアップロードの検証（MIMEタイプ、サイズ制限）
- HTTPヘッダー（セキュリティ関連ヘッダーの設定）

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠をファイル名:行番号で1-3個>
suggestions: <改善提案を0-3個>
```

### Step 5: Create `skills/mosaic-orch/facets/rubrics/design.md`

```markdown
---
name: design
description: 設計・構造を評価する（関心の分離、依存方向、過剰抽象化）
---

# 評価軸: Design（設計・構造）

## 採点段階
- S: 模範的。設計が明確で、関心の分離・依存方向が完璧
- A+: 高品質。設計上の問題なし、適切な抽象化レベル
- A: 良好。軽微な設計上の改善余地はあるが全体として適切
- B: 可。責務混在や不適切な依存が1-2箇所ある
- C: 不可。設計上の重大な問題がある（循環依存、過剰抽象化等）

## 採点時に観察すること
- 関心の分離（1クラス・1関数が担う責務が明確か）
- 依存方向（ドメインが外部に依存していないか、依存逆転の原則）
- 過剰抽象化（YAGNI: 1箇所からしか使われないのにインターフェース化していないか）
- 循環依存（モジュール間で循環参照が発生していないか）
- レイヤー構造の遵守（Controller→Service→Repository の方向）
- 変更の必要十分性（過不足なく目的を達成しているか）
- 技術的負債の兆候（後で困る設計になっていないか）

## 出力フォーマット
grade: {S|A+|A|B|C}
evidence: <採点の根拠をファイル名:行番号で1-3個>
suggestions: <改善提案を0-3個>
```

### Step 6: Create `skills/mosaic-orch/contracts/task-analysis.md`

```markdown
---
name: task-analysis
description: タスク分析の出力契約
---

# Output Contract: task-analysis

## 期待形式
"## Analysis" 見出しの下にモード情報、"## Wave 1 Subtasks" と "## Wave 2 Subtasks" にサブタスク一覧。

## パース規則（エンジンが抽出）
- mode: "## Analysis" セクション内の "- mode:" 直後のテキスト。正規表現 /^(parallel|wave)$/
- has_wave2: "- has_wave2:" 直後のテキスト。正規表現 /^(true|false)$/
- has_fe: "- has_fe:" 直後のテキスト。正規表現 /^(true|false)$/
- wave1_subtasks: "## Wave 1 Subtasks" セクション内の "### Subtask" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - persona: "- persona:" 直後のテキスト
  - instruction: "- instruction:" 直後のテキスト
  - description: "- description:" 直後のテキスト
  - skills: "- skills:" 直後のテキスト（配列として解析）
- wave2_subtasks: "## Wave 2 Subtasks" セクション内を同様に解析。セクションがない場合は空配列

## 検証項目
- mode が "parallel" または "wave" であること（必須）
- has_wave2 が "true" または "false" であること（必須）
- has_fe が "true" または "false" であること（必須）
- wave1_subtasks の件数が 1 以上であること（必須）
- 各 subtask に persona が空でないこと（必須）
- 各 subtask に instruction が空でないこと（必須）
- has_wave2 が true の場合、wave2_subtasks の件数が 1 以上であること（必須）
```

### Step 7: Create `skills/mosaic-orch/contracts/duplicate-check.md`

```markdown
---
name: duplicate-check
description: 重複チェックの出力契約
---

# Output Contract: duplicate-check

## 期待形式
"## Duplicate Check" 見出しの下に重複有無とリスト。

## パース規則（エンジンが抽出）
- has_duplicate: "- has_duplicate:" 直後のテキスト。正規表現 /^(true|false)$/
- existing_prs: "- existing_prs:" 直後のテキスト（配列として解析、空の場合は空配列）
- recommendation: "- recommendation:" 直後のテキスト。正規表現 /^(proceed|ask_user)$/

## 検証項目
- has_duplicate が "true" または "false" であること（必須）
- recommendation が "proceed" または "ask_user" であること（必須）
- has_duplicate が true の場合、existing_prs が空でないこと（必須）
```

### Step 8: Create `skills/mosaic-orch/contracts/git-setup.md`

```markdown
---
name: git-setup
description: Gitブランチセットアップの出力契約
---

# Output Contract: git-setup

## 期待形式
"## Git Setup" 見出しの下にIssue番号とブランチ名。

## パース規則（エンジンが抽出）
- issue_number: "- issue_number:" 直後のテキスト（数値）
- branch_name: "- branch_name:" 直後のテキスト
- base_branch: "- base_branch:" 直後のテキスト
- stacked_branches: "- stacked_branches:" 直後のテキスト（配列として解析、空の場合は空配列）

## 検証項目
- issue_number が正の整数であること（必須）
- branch_name が空でないこと（必須）
- base_branch が空でないこと（必須）
```

### Step 9: Create `skills/mosaic-orch/contracts/implementation-result.md`

```markdown
---
name: implementation-result
description: 実装結果の出力契約
---

# Output Contract: implementation-result

## 期待形式
"## Implementation Result" 見出しの下に変更ファイル一覧とテスト結果。

## パース規則（エンジンが抽出）
- files_changed: "- files_changed:" 直後のテキスト（配列として解析）
- test_results: "- test_results:" 直後のテキスト（複数行の場合あり）
- build_status: "- build_status:" 直後のテキスト。正規表現 /^(pass|fail)$/
- self_assessment: "- self_assessment:" 直後のテキスト

## 検証項目
- files_changed が空でないこと（必須）
- test_results が空でないこと（必須 — テスト実行なしは不合格）
- build_status が "pass" または "fail" であること（必須）
- self_assessment が空でないこと（必須）
```

### Step 10: Create `skills/mosaic-orch/contracts/integration-result.md`

```markdown
---
name: integration-result
description: 統合結果の出力契約
---

# Output Contract: integration-result

## 期待形式
"## Integration Result" 見出しの下にマージ結果と競合情報。

## パース規則（エンジンが抽出）
- merged_files: "- merged_files:" 直後のテキスト（配列として解析）
- conflicts_resolved: "- conflicts_resolved:" 直後のテキスト（配列として解析、空の場合は空配列）
- build_status: "- build_status:" 直後のテキスト。正規表現 /^(pass|fail)$/

## 検証項目
- merged_files が空でないこと（必須）
- build_status が "pass" または "fail" であること（必須）
```

### Step 11: Create `skills/mosaic-orch/contracts/quality-result.md`

```markdown
---
name: quality-result
description: 品質ゲートの出力契約
---

# Output Contract: quality-result

## 期待形式
"## Quality Result" 見出しの下にPRサイズとテスト存在とビルド結果。

## パース規則（エンジンが抽出）
- pr_size: "- pr_size:" 直後のテキスト（数値）
- pr_size_verdict: "- pr_size_verdict:" 直後のテキスト。正規表現 /^(S|M|L|XL)$/
- test_exists: "- test_exists:" 直後のテキスト。正規表現 /^(true|false)$/
- build_lint_ok: "- build_lint_ok:" 直後のテキスト。正規表現 /^(true|false)$/
- overall: "- overall:" 直後のテキスト。正規表現 /^(pass|fail)$/

## 検証項目
- pr_size_verdict が "S", "M", "L", "XL" のいずれかであること（必須）
- test_exists が "true" または "false" であること（必須）
- build_lint_ok が "true" または "false" であること（必須）
- overall が "pass" または "fail" であること（必須）
```

### Step 12: Create `skills/mosaic-orch/contracts/dev-review-verdict.md`

```markdown
---
name: dev-review-verdict
description: 5軸コードレビューの総合判定契約
---

# Output Contract: dev-review-verdict

## 期待形式
"## Grade" 見出しの直下に S/A+/A/B/C のいずれか。
"## Axes" に5軸の個別評価。"## Evidence" に根拠。"## Issues" に修正必須項目。"## Suggestions" に改善提案。

## パース規則（エンジンが抽出）
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- axes: "## Axes" セクション内の各行を解析:
  - performance: "- performance:" 直後の最初の単語、正規表現 /^(S|A\+|A|B|C)/
  - naming: "- naming:" 直後の最初の単語
  - testing: "- testing:" 直後の最初の単語
  - security: "- security:" 直後の最初の単語
  - design: "- design:" 直後の最初の単語
- evidence: "## Evidence" から "## Issues" までのテキスト
- issues: "## Issues" から "## Suggestions" までのテキスト、箇条書きを配列化
- suggestions: "## Suggestions" から末尾まで、箇条書きを配列化

## 検証項目
- grade が正規表現にマッチすること（必須）
- axes の5軸すべてが存在し、正規表現にマッチすること（必須）
- evidence が空でないこと（必須）
- grade が A+ 未満の場合、issues が空でないこと（必須）
```

### Step 13: Create `skills/mosaic-orch/contracts/fix-verdict.md`

```markdown
---
name: fix-verdict
description: レビュー修正後の自己採点契約
---

# Output Contract: fix-verdict

## 期待形式
"## Grade" 見出しの直下に S/A+/A/B/C のいずれか。
"## Evidence" に修正内容と自己採点の根拠。"## Fixed Files" に修正ファイル一覧。

## パース規則（エンジンが抽出）
- grade: "## Grade" 直下の最初の非空行、正規表現 /^(S|A\+|A|B|C)$/
- evidence: "## Evidence" から "## Fixed Files" までのテキスト
- fixed_files: "## Fixed Files" セクション内の箇条書きを配列化。各行からファイルパスを抽出

## 検証項目
- grade が正規表現にマッチすること（必須）
- evidence が空でないこと（必須）
- fixed_files が空でないこと（必須）
```

### Step 14: Create `skills/mosaic-orch/contracts/ui-verification.md`

```markdown
---
name: ui-verification
description: UI視覚検証の出力契約
---

# Output Contract: ui-verification

## 期待形式
"## UI Verification" 見出しの下にスクリーンショット情報と比較結果。

## パース規則（エンジンが抽出）
- screenshots: "- screenshots:" 直後のテキスト（配列として解析）
- comparison_result: "- comparison_result:" 直後のテキスト。正規表現 /^(pass|warn|fail|ask_user)$/

## 検証項目
- screenshots が空でないこと（必須）
- comparison_result が "pass", "warn", "fail", "ask_user" のいずれかであること（必須）
```

### Step 15: Create `skills/mosaic-orch/contracts/save-result.md`

```markdown
---
name: save-result
description: レビュー結果保存の出力契約
---

# Output Contract: save-result

## 期待形式
"## Save Result" 見出しの下に保存先パスと更新情報。

## パース規則（エンジンが抽出）
- review_path: "- review_path:" 直後のテキスト
- log_path: "- log_path:" 直後のテキスト（空の場合あり）
- error_patterns_updated: "- error_patterns_updated:" 直後のテキスト。正規表現 /^(true|false)$/

## 検証項目
- review_path が空でないこと（必須）
- error_patterns_updated が "true" または "false" であること（必須）
```

### Step 16: Create `skills/mosaic-orch/contracts/completion-report.md`

```markdown
---
name: completion-report
description: 最終報告の出力契約
---

# Output Contract: completion-report

## 期待形式
"## Completion Report" 見出しの下にPR URL、Issue URL、サマリー、チーム報告。

## パース規則（エンジンが抽出）
- pr_url: "- pr_url:" 直後のテキスト
- issue_url: "- issue_url:" 直後のテキスト
- summary: "- summary:" 直後のテキスト
- team_report: "- team_report:" 直後のテキスト（複数行の場合あり）

## 検証項目
- pr_url が空でないこと（必須）
- issue_url が空でないこと（必須）
- summary が空でないこと（必須）
```

---

## Task 5: Workflow YAML + SKILL.md Update + Verification

### Step 1: Create `skills/mosaic-orch/workflows/dev-orchestration.yaml`

```yaml
name: dev-orchestration
version: "1"
description: 開発タスクをチーム分解・並列実装・5軸レビューで品質担保して納品する

inputs:
  - name: task
    type: string
    required: true

defaults:
  permission: acceptEdits

stages:
  # Stage 1: タスク分析 + サブタスク分解 + persona/instruction選定
  - id: analyze
    kind: task
    facets:
      persona: architect
      knowledge: [team-roster, skill-catalog]
      instructions: [analyze-dev-task]
    input: ${workflow.inputs.task}
    output_contract: task-analysis

  # Stage 2: 重複チェック
  - id: check-dup
    kind: task
    facets:
      persona: project-manager
      instructions: [check-duplicates]
    input: ${workflow.inputs.task}
    output_contract: duplicate-check

  # Stage 3: Issue + ブランチ作成
  - id: setup-git
    kind: task
    facets:
      persona: project-manager
      policies: [git-conventions]
      instructions: [setup-git-branch]
    input: |
      Task: ${workflow.inputs.task}
      Analysis: ${analyze.output}
    output_contract: git-setup

  # Stage 4: Wave1 並列実装
  - id: implement-wave1
    kind: fan_out
    from: ${analyze.output.wave1_subtasks}
    as: subtask
    facets:
      persona: ${subtask.persona}
      policies: [coding-standards, no-push, tdd]
      knowledge: [error-patterns]
      instructions: [${subtask.instruction}]
    input: |
      Task: ${subtask.description}
      Skills: ${subtask.skills}
      Branch: ${setup-git.output.branch_name}
    output_contract: implementation-result

  # Stage 5: Wave1 統合
  - id: integrate-wave1
    kind: fan_in
    from: ${implement-wave1.outputs}
    facets:
      persona: integrator
      policies: [coding-standards]
      instructions: [merge-implementations]
    output_contract: integration-result

  # Stage 6: Wave2 並列実装（条件付き）
  - id: implement-wave2
    kind: fan_out
    when: ${analyze.output.has_wave2} == 'true'
    from: ${analyze.output.wave2_subtasks}
    as: subtask
    facets:
      persona: ${subtask.persona}
      policies: [coding-standards, no-push, tdd]
      knowledge: [error-patterns]
      instructions: [${subtask.instruction}]
    input: |
      Task: ${subtask.description}
      Skills: ${subtask.skills}
      Branch: ${setup-git.output.branch_name}
      Wave1 Result: ${integrate-wave1.output}
    output_contract: implementation-result

  # Stage 7: Wave2 統合（条件付き）
  - id: integrate-wave2
    kind: fan_in
    when: ${analyze.output.has_wave2} == 'true'
    from: ${implement-wave2.outputs}
    facets:
      persona: integrator
      policies: [coding-standards]
      instructions: [merge-implementations]
    output_contract: integration-result

  # Stage 8: 品質ゲート
  - id: quality-gate
    kind: task
    facets:
      persona: qa-engineer
      policies: [tdd]
      instructions: [run-quality-checks]
    input: |
      Analysis: ${analyze.output}
      Implementation: ${integrate-wave1.output}
    output_contract: quality-result

  # Stage 9: 5軸コードレビュー
  - id: review
    kind: task
    facets:
      persona: code-reviewer
      rubrics: [performance, naming, testing, security, design]
      instructions: [code-review-5axis]
    input: |
      Analysis: ${analyze.output}
      Quality Gate: ${quality-gate.output}
    output_contract: dev-review-verdict
    permission: default

  # Stage 10: レビュー修正ループ（A+未満の場合）
  - id: fix
    kind: task
    when: ${review.output.grade} < 'A+'
    facets:
      persona: ${analyze.output.wave1_subtasks[0].persona}
      policies: [coding-standards, no-push]
      rubrics: [performance, naming, testing, security, design]
      instructions: [apply-fixes-and-self-assess]
    input: |
      Review Result: ${review.output}
    loop_until: ${self.grade} >= 'A+'
    max_iterations: 3
    output_contract: fix-verdict

  # Stage 11: UI視覚検証（FE変更時のみ）
  - id: ui-verify
    kind: task
    when: ${analyze.output.has_fe} == 'true'
    facets:
      persona: qa-engineer
      instructions: [verify-ui-visual]
    input: |
      Analysis: ${analyze.output}
    output_contract: ui-verification

  # Stage 12: レビュー結果保存 + ログ
  - id: save-results
    kind: task
    facets:
      persona: project-manager
      knowledge: [error-patterns]
      instructions: [save-review-and-log]
    input: |
      Task: ${workflow.inputs.task}
      Analysis: ${analyze.output}
      Review: ${review.output}
    output_contract: save-result

  # Stage 13: push + PR作成 + 結果報告
  - id: finalize
    kind: task
    facets:
      persona: project-manager
      policies: [git-conventions]
      instructions: [push-pr-report]
    input: |
      Task: ${workflow.inputs.task}
      Analysis: ${analyze.output}
      Git Setup: ${setup-git.output}
      Review Grade: ${review.output.grade}
      Quality: ${quality-gate.output}
    output_contract: completion-report
```

### Step 2: Update SKILL.md description

In `skills/mosaic-orch/SKILL.md`, update the description to remove "Not for: 開発タスク(intendant推奨)" and add dev-orchestration as a supported workflow.

Find the current description block:
```
description: >
  Facetベース(persona/policy/knowledge/instruction/rubric)のドメイン非依存オーケストレーター。
  Stage/Fan-out/Fan-in/Loopをサポートする宣言的Workflow YAMLで、複数サブエージェントを合成する。
  Use when: 多段レビューループ、並列分解タスク、faceted-prompting流の構造化プロンプト実行。
  Not for: 単発の軽い質問、開発タスク(intendant推奨)、直接コーディング。
```

Replace with:
```
description: >
  Facetベース(persona/policy/knowledge/instruction/rubric)のドメイン非依存オーケストレーター。
  Stage/Fan-out/Fan-in/Loopをサポートする宣言的Workflow YAMLで、複数サブエージェントを合成する。
  Use when: 多段レビューループ、並列分解タスク、faceted-prompting流の構造化プロンプト実行、開発タスク(dev-orchestration workflow)。
  Not for: 単発の軽い質問、直接コーディング。
```

### Step 3: Verify with dry-run

After all files are created, run verification:

```bash
# Verify all files exist
ls skills/mosaic-orch/facets/personas/{backend-lead,backend-domain,frontend-lead,frontend-component,architect,tester,e2e-tester,integrator,content-creator,project-manager,qa-engineer,code-reviewer}.md
ls skills/mosaic-orch/facets/policies/{coding-standards,no-push,tdd,git-conventions}.md
ls skills/mosaic-orch/facets/knowledge/{team-roster,skill-catalog,error-patterns}.md
ls skills/mosaic-orch/facets/instructions/{analyze-dev-task,check-duplicates,setup-git-branch,implement-backend,implement-frontend,implement-e2e,implement-general,merge-implementations,run-quality-checks,code-review-5axis,apply-fixes-and-self-assess,verify-ui-visual,save-review-and-log,push-pr-report}.md
ls skills/mosaic-orch/facets/rubrics/{performance,naming,testing,security,design}.md
ls skills/mosaic-orch/contracts/{task-analysis,duplicate-check,git-setup,implementation-result,integration-result,quality-result,dev-review-verdict,fix-verdict,ui-verification,save-result,completion-report}.md
ls skills/mosaic-orch/workflows/dev-orchestration.yaml

# Dry-run the workflow
/mosaic-orch dev-orchestration --dry-run "ソート機能をAPIとUIに追加する"
```

Expected dry-run output should show:
- 13 stages resolved with correct facet references
- Dynamic facet expansion in implement-wave1/wave2 stages
- Conditional stages (implement-wave2, integrate-wave2, ui-verify) correctly identified
- All output contracts resolved to existing files
