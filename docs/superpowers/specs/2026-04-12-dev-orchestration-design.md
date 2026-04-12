# dev-orchestration — intendant移植 設計仕様

- **日付**: 2026-04-12
- **ステータス**: Draft
- **前提**: `docs/superpowers/specs/2026-04-12-mosaic-orch-design.md`(mosaic-orchフレームワーク仕様)
- **関連**: intendant, TAKT, Kapelleチーム

---

## 0. Executive Summary

intendantの開発オーケストレーション全機能(9手順)を、mosaic-orchフレームワーク準拠で再実装する。

**成果物**:
1. **フレームワーク拡張**: 動的Facet参照(`${...}`をfacet名にも適用)— engine 2ファイルに軽微追記
2. **dev-orchestration.yaml**: 13 stagesの宣言的Workflow YAML
3. **開発用Facet/Contract一式**: personas 12 + policies 4 + knowledge 3 + instructions 14 + rubrics 5 + contracts 11 = 49ファイル

**intendantとの違い**:
- SKILL.md 580行の手続き的フロー → YAML 90行の宣言的Workflow
- Kapelle人物名(深沢/朝比奈/黒川...) → 役割名(backend-lead/frontend-lead/architect...)
- TAKT経由の実装委譲 → mosaic-orchの fan_out/fan_in + 動的facet
- 5軸レビューがPolicy内混在 → Rubric Facetとして独立
- Git/PR操作が手順内に埋込み → instruction/policyに分離(差し替え可能)

---

## 1. フレームワーク拡張: 動的Facet参照

### 1.1 概要

Workflow YAMLのfacetフィールドで`${...}`変数参照を使えるようにする。

```yaml
facets:
  persona: ${subtask.persona}              # "backend-lead" 等に展開
  instructions: [${subtask.instruction}]   # "implement-backend" 等に展開
```

### 1.2 変更箇所

| ファイル | 変更内容 |
|---|---|
| `engine/stage-runner.md` | facetsフィールドも変数展開してからcomposerに渡す旨を追記 |
| `engine/composer.md` | facet名を facet-loader に渡す前に variable-resolver で展開する旨を追記 |

**SoC影響**: なし。variable-resolverは既にcomposerより下位。依存方向は変わらない。

### 1.3 展開タイミング

```
Orchestrator(L2)
  → variable-resolver: stage全体の ${...} を展開(input, when, loop_until)
  → Stage Runner(L3)
    → variable-resolver: facets内の ${...} を展開  ← 追加
    → Composer(L4): 展開済みfacet名でfacet-loaderを呼ぶ
```

### 1.4 エラー処理

facet名に展開された値に対応するファイルが存在しない場合: FacetNotFound(既存エラー処理で対応済み)。

---

## 2. Workflow ステージ構成

### 2.1 ステージ一覧(13 stages)

| # | Stage ID | kind | 対応intendant手順 | 条件 |
|---|---|---|---|---|
| 1 | `analyze` | task | 1+2 タスク分解+選定 | 常時 |
| 2 | `check-dup` | task | 3a 重複チェック | 常時 |
| 3 | `setup-git` | task | 3b-d Issue/ブランチ | 常時 |
| 4 | `implement-wave1` | fan_out | 4 Wave1実装 | 常時 |
| 5 | `integrate-wave1` | fan_in | 4.5 統合 | 常時 |
| 6 | `implement-wave2` | fan_out | 4 Wave2実装 | `when: has_wave2` |
| 7 | `integrate-wave2` | fan_in | 4.5 統合 | `when: has_wave2` |
| 8 | `quality-gate` | task | 5 品質ゲート | 常時 |
| 9 | `review` | task | 6 コードレビュー | 常時 |
| 10 | `fix` | task | 6c レビュー修正 | `when: grade < A+` + `loop_until` |
| 11 | `ui-verify` | task | 7 UI検証 | `when: has_fe` |
| 12 | `save-results` | task | 8 結果保存+ログ | 常時 |
| 13 | `finalize` | task | 9 push+PR+報告 | 常時 |

### 2.2 実行フロー

```
analyze → check-dup → setup-git → implement-wave1 → integrate-wave1
                                 → implement-wave2 → integrate-wave2  (条件付き)
         → quality-gate → review → fix (条件付きloop) → ui-verify (条件付き)
         → save-results → finalize
```

- 単一メンバー分岐は不要。1サブタスクでも fan_out(要素数1)で統一
- Wave2は最大1つ(実運用上Wave3以降は発生しない)
- fix stageはloop_until(max_iterations: 3)でA+到達まで繰り返す

### 2.3 analyze stageの出力構造(task-analysis contract)

```markdown
## Analysis
- mode: parallel | wave
- has_wave2: true | false
- has_fe: true | false

## Wave 1 Subtasks
### Subtask 1
- persona: backend-lead
- instruction: implement-backend
- description: APIエンドポイントの実装
- skills: [kotlin-specialist, tdd]

### Subtask 2
- persona: e2e-tester
- instruction: implement-e2e
- description: E2Eテストスキャフォールド
- skills: [playwright-scaffolder]

## Wave 2 Subtasks
### Subtask 1
- persona: frontend-lead
- instruction: implement-frontend
- description: UI実装(Wave1のAPI完了後)
- skills: [react-patterns]
```

### 2.4 動的選定テーブル(analyze-dev-task instruction内)

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

---

## 3. Facet一覧

### 3.1 Personas (12)

| persona名 | 役割 |
|---|---|
| `backend-lead` | BE実装(Kotlin/Ktor/Exposed) |
| `backend-domain` | BE複雑ドメインロジック |
| `frontend-lead` | FE実装(React/TypeScript/MUI) |
| `frontend-component` | UIコンポーネント |
| `architect` | 設計判断・リファクタ |
| `tester` | ユニットテスト追加 |
| `e2e-tester` | Playwright E2Eテスト |
| `integrator` | Wave統合・競合解決 |
| `content-creator` | コンテンツ制作 |
| `project-manager` | Git/PR管理・報告 |
| `qa-engineer` | 品質ゲート・UI検証 |
| `code-reviewer` | 5軸コードレビュー |

### 3.2 Policies (4)

| policy名 | 内容 |
|---|---|
| `coding-standards` | 既存パターン準拠、命名規約、型安全 |
| `no-push` | 実装中はgit pushしない。pushはfinalize stageのみ |
| `tdd` | テスト先行。BE振る舞い変更は必須、FEロジックは推奨 |
| `git-conventions` | ブランチ名 `{type}/mo-{YYYYMMDD}-{slug}`、コミットメッセージ規約 |

### 3.3 Knowledge (3)

| knowledge名 | 内容 | 元intendantリソース |
|---|---|---|
| `team-roster` | 役割別の能力マップ・得意領域 | themes/theme-data.md |
| `skill-catalog` | 利用可能Skill一覧+トリガー | skill-catalog.md |
| `error-patterns` | 過去レビュー頻出パターン | error-patterns.md |

### 3.4 Instructions (14)

| instruction名 | 使用Stage | 内容 |
|---|---|---|
| `analyze-dev-task` | analyze | タスク分析、サブタスク分解、persona/instruction選定、Wave振り分け |
| `check-duplicates` | check-dup | `gh pr list --search`, `gh issue list --search` |
| `setup-git-branch` | setup-git | `gh issue create`, `git pull`, `git checkout -b`, Stacked PR手順 |
| `implement-backend` | implement | Kotlin BE実装(compileKotlin, detekt, ktlintCheck, テスト実行) |
| `implement-frontend` | implement | React FE実装(npm run build, lint, テスト実行) |
| `implement-e2e` | implement | Playwright E2Eスキャフォールド+実行 |
| `implement-general` | implement | 汎用実装(言語非依存) |
| `merge-implementations` | integrate | git merge --no-ff、競合解決、統合後ビルド確認 |
| `run-quality-checks` | quality-gate | diff --stat PRサイズ、テスト存在、ビルドlint |
| `code-review-5axis` | review | 5軸レビュー(rubrics使用)、ファイル:行番号で指摘 |
| `apply-fixes-and-self-assess` | fix | 指摘修正 + 同rubricで自己採点 |
| `verify-ui-visual` | ui-verify | Playwrightスクリーンショット(デスクトップ+モバイル)、Pencil比較 |
| `save-review-and-log` | save-results | .mosaic-orch/reviews/ JSON保存, error-patterns追記, 通信ログ |
| `push-pr-report` | finalize | git push, gh pr create, gh pr ready, ユーザー報告テンプレート |

### 3.5 Rubrics (5) — intendantの5軸レビューを独立Facet化

| rubric名 | 評価対象 | 採点段階 |
|---|---|---|
| `performance` | N+1、ループ内DB、batchInsert/Upsert未使用 | C/B/A/A+/S |
| `naming` | 既存パターン統一、ファイル名整合、規約 | C/B/A/A+/S |
| `testing` | 存在、正常系/異常系/境界値、可読性 | C/B/A/A+/S |
| `security` | 認可、バリデーション、OWASP Top 10 | C/B/A/A+/S |
| `design` | 関心の分離、依存方向、過剰抽象化 | C/B/A/A+/S |

---

## 4. Contracts一覧 (11)

| contract名 | Stage | 主要フィールド |
|---|---|---|
| `task-analysis` | analyze | `mode`, `has_wave2`, `has_fe`, `wave1_subtasks[]`, `wave2_subtasks[]` |
| `duplicate-check` | check-dup | `has_duplicate`, `existing_prs[]` |
| `git-setup` | setup-git | `issue_number`, `branch_name`, `stacked_branches[]` |
| `implementation-result` | implement | `files_changed[]`, `test_results`, `build_status`, `self_assessment` |
| `integration-result` | integrate | `merged_files[]`, `conflicts_resolved`, `build_status` |
| `quality-result` | quality-gate | `pr_size`, `pr_size_verdict`, `test_exists`, `build_lint_ok` |
| `review-verdict` | review | `grade`, `axes{}`, `issues[]` |
| `fix-verdict` | fix | `grade`, `evidence`, `fixed_files[]` |
| `ui-verification` | ui-verify | `screenshots[]`, `comparison_result` |
| `save-result` | save-results | `review_path`, `log_path`, `error_patterns_updated` |
| `completion-report` | finalize | `pr_url`, `issue_url`, `summary`, `team_report` |

---

## 5. Git/PR操作の分離設計

intendantではGit操作がSKILL.mdの手順に手続き的に埋まっていた。mosaic-orchではinstruction facetとpolicyに分離する。

### 5.1 分離マッピング

| Git操作 | intendantでの場所 | mosaic-orchでの場所 |
|---|---|---|
| ブランチ作成 | 手順3c (SKILL.md内) | `setup-git-branch` instruction |
| ローカルコミット | 暗黙(手順4内) | `no-push` policy + 各implement instruction |
| push禁止 | 禁止事項(SKILL.md冒頭) | `no-push` policy |
| push実行 | 手順9d (SKILL.md内) | `push-pr-report` instruction |
| PR作成 | 手順9d (SKILL.md内) | `push-pr-report` instruction |
| Stacked PR | 手順3d/9c (SKILL.md内) | `setup-git-branch` instruction + `push-pr-report` instruction |

### 5.2 差し替え可能性

Git操作がinstructionに閉じているため、GitHub → GitLab移行時は`setup-git-branch`と`push-pr-report`の2ファイル差し替えで済む。他のstage/facetは一切変更不要。

---

## 6. intendant禁止事項の移植

| intendant禁止事項 | mosaic-orchでの表現 |
|---|---|
| 自分でコーディングするな | orchestrator.md既存: 「自分では作業しない」 |
| 手順をスキップするな | エンジン仕様: stageは宣言順に必ず実行 |
| コミットメッセージにフレーバーを入れるな | `git-conventions` policy |
| 中間段階でgit pushするな | `no-push` policy |

---

## 7. ファイル作成一覧

### エンジン変更 (2ファイル修正)
- `engine/stage-runner.md` — 動的facet展開の追記
- `engine/composer.md` — 動的facet展開の追記

### 新規ファイル (50ファイル)
- `facets/personas/` × 12
- `facets/policies/` × 4
- `facets/knowledge/` × 3
- `facets/instructions/` × 14
- `facets/rubrics/` × 5
- `contracts/` × 11
- `workflows/dev-orchestration.yaml` × 1

### 合計: 2ファイル修正 + 50ファイル新規 = 52ファイル

---

## 8. intendantからの移植チェックリスト

| intendant機能 | 移植先 | 状態 |
|---|---|---|
| チームデータ読み込み | knowledge/team-roster.md | 新規 |
| タスク分析+分解 | instructions/analyze-dev-task.md | 新規 |
| 担当者・ピース選定 | analyze output + 動的facet | 新規 |
| 重複チェック | check-dup stage | 新規 |
| Issue確保 | setup-git stage | 新規 |
| ブランチ作成 | setup-git stage | 新規 |
| 単一メンバー実装 | (削除: fan_outで統一) | — |
| Wave並列実装 | implement-wave1/wave2 fan_out | 新規 |
| 統合フェーズ | integrate-wave1/wave2 fan_in | 新規 |
| PRサイズチェック | quality-gate stage | 新規 |
| テスト存在確認 | quality-gate stage | 新規 |
| ビルド/lint確認 | quality-gate stage | 新規 |
| 5軸コードレビュー | review stage + 5 rubrics | 新規 |
| A+必須ループ | fix stage + loop_until | 新規 |
| UI視覚検証 | ui-verify stage (条件付き) | 新規 |
| レビュー結果JSON保存 | save-results stage | 新規 |
| エラーパターン蓄積 | save-results stage | 新規 |
| 通信ログ | save-results stage | 新規 |
| Worktree cleanup | (不要: mosaic-orchはworktree非使用) | — |
| push+PR作成+Ready | finalize stage | 新規 |
| 結果報告 | finalize stage | 新規 |
| ABORTフォールバック | エンジン既存ABORT処理 | 既存 |

---

## 9. 将来拡張

- Wave3以降の対応(必要になったらstage追加)
- `--knowledge`フラグでプロジェクト固有knowledgeを動的注入
- intendantの`.intendant/reviews/`との互換読み込み
- SKILL description更新: `Not for: 開発タスク` を削除
