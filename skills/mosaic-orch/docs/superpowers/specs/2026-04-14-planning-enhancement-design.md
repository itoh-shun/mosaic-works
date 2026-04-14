# mosaic-orch Planning Enhancement — TAKT-Parity Design

## Goal

mosaic-orch の Planning 力を TAKT 以上に引き上げる。design/plan stage の instruction と contract を大幅強化し、AI 設計レビュー（design-review）と計画検証（plan-review）の 2 stage を追加する。

## Architecture

15-stage workflow を 17-stage に拡張。design → design-review → plan → plan-review の 4 段計画パイプラインにより、実装前に設計の穴とスコープクリープを検出する。TAKT の plan + supervisor pipeline と同等の検証力を持ちつつ、TAKT にない「実装前の計画段階での問題検出」を実現する。

## Stage Flow (17 stages)

```
[design]* → [design-review]† → [plan]* → [plan-review]† → [check-dup] → [setup-git] → [setup-worktree]
    ↑           |                  ↑           |
    └─ NEEDS_REVISION             └─ NEEDS_REVISION
                 ↓                              ↓
              APPROVE → plan              APPROVE → check-dup

* = gate: approval (human)
† = AI review with loop-back
```

| # | ID | Kind | Status | Gate | 役割 |
|---|-----|------|--------|------|------|
| 1 | design | task | **REWRITE** | approval | ファイルレベル設計+実装ガイドライン+スコープ規律 |
| 2 | design-review | task | **NEW** | — | AI設計レビュー（5軸: 完全性/ファイル設計/スコープ/実現可能性/依存整合性） |
| 3 | plan | task | **REWRITE** | approval | per-subtask ファイル割り当て+テスト戦略+受入基準 |
| 4 | plan-review | task | **NEW** | — | 要件カバレッジ照合+ファイル衝突検出+スコープクリープ検出 |
| 5 | check-dup | task | existing | — | |
| 6 | setup-git | task | existing | — | |
| 7 | setup-worktree | task | existing | — | |
| 8 | implement-wave1 | fan_out | existing | — | |
| 9 | integrate-wave1 | fan_in | existing | — | |
| 10 | implement-wave2 | fan_out | existing | — | |
| 11 | integrate-wave2 | fan_in | existing | — | |
| 12 | quality-gate | task | existing | — | |
| 13 | review | task | existing | — | |
| 14 | fix | task | existing | — | |
| 15 | ui-verify | task | existing | — | |
| 16 | save-results | task | existing | — | |
| 17 | finalize | task | existing | approval | |

## Loop Monitors (追加分)

```yaml
- cycle: [design, design-review]
  threshold: 2
  judge:
    persona: architect
    instruction: design → design-review のサイクルが {cycle_count} 回繰り返されました。設計が収束しているか判断してください。

- cycle: [plan, plan-review]
  threshold: 2
  judge:
    persona: architect
    instruction: plan → plan-review のサイクルが {cycle_count} 回繰り返されました。計画が収束しているか判断してください。
```

---

## File Changes

### REWRITE: facets/instructions/design-spec.md

TAKTのplanner persona + plan instruction と同等以上の深さ。追加要素:

1. **情報の優先順位**: タスク指示書 > ソースコード > その他ドキュメント。推測禁止、ファクトチェック必須。
2. **ファイル構成テーブル**: Action (create/modify) + Path + Responsibility。1モジュール1責務、200-400行目安。
3. **設計パターン決定**: pattern + apply_to + reason。
4. **実装ガイドライン**: implementer が設計判断に迷わないための具体指針。
5. **スコープ規律**: in_scope / out_of_scope / deletion_policy を明示。指示外の改善禁止。
6. **受入基準**: チェックリスト形式。plan-review がこれを使って要件×計画を照合する。

### REWRITE: contracts/design-result.md

既存フィールド (codebase_context, impact_layer, task_type, has_fe, scope, constraints, approach, pattern_reuse, risks, dependencies) は維持。追加:

- file_structure: "## File Structure" テーブルをパース。各行から action, path, responsibility を抽出。
- design_patterns: "## Design Patterns" セクションを配列化。各エントリから pattern, apply_to, reason。
- implementation_guidelines: "## Implementation Guidelines" セクションのテキスト。
- scope_boundaries: "## Scope Boundaries" セクションから in_scope, out_of_scope, deletion_policy。
- acceptance_criteria: "## Acceptance Criteria" セクションのチェックリストを配列化。
- open_questions: "## Open Questions" セクションのリストを配列化（空の場合は空配列）。

検証追加:
- file_structure の件数が 1 以上であること（必須）
- acceptance_criteria の件数が 1 以上であること（必須）
- scope_boundaries の in_scope が空でないこと（必須）

### NEW: facets/instructions/review-design.md

5軸設計レビュー instruction:

| # | 観点 | チェック内容 | REJECT条件 |
|---|------|------------|-----------|
| 1 | 完全性 | 全要件が acceptance_criteria に反映されているか | 要件の漏れ |
| 2 | ファイル設計 | 1モジュール1責務、200-400行目安 | 巨大ファイル/責務混在 |
| 3 | スコープ | scope_boundaries が明確、暗黙の拡大なし | 指示外の改善が in_scope に含まれる |
| 4 | 実現可能性 | implementation_guidelines が具体的、技術選定に矛盾なし | 抽象的すぎるガイドライン |
| 5 | 依存整合性 | file_structure の依存方向が正しい、循環依存なし | 循環依存 |

出力: verdict (APPROVE/NEEDS_REVISION) + score (S/A+/A/B/C) + findings (finding_id付き)

### NEW: contracts/design-review-result.md

- verdict: APPROVE | NEEDS_REVISION
- score: S | A+ | A | B | C
- findings: "## Findings" セクションの "### Finding" ブロックを配列化。各ブロックから finding_id, axis, severity, detail, recommendation。

検証:
- verdict が APPROVE または NEEDS_REVISION であること
- verdict が NEEDS_REVISION の場合、findings が 1 件以上あること

### REWRITE: facets/instructions/plan-tasks.md

既存の subtask decomposition + persona/instruction/skill 選定は維持。追加:

1. **per-subtask ファイル割り当て**: design の file_structure テーブルを参照し、各subtaskに files_create / files_modify を割り当て。1ファイルが複数subtaskにまたがらない。
2. **テスト戦略**: 各subtaskに testing_strategy を必須化。「何をどうテストするか」を具体的に。
3. **受入基準分配**: design の acceptance_criteria を subtask に分配。全criteria がいずれかの subtask にマッピングされること。
4. **複雑度見積もり**: estimated_complexity (small/medium/large)。

### REWRITE: contracts/plan-result.md

既存フィールド (mode, has_wave2, has_fe, subtask.persona/instruction/description/skills/mcps) は維持。追加:

- subtask.files_create: 配列
- subtask.files_modify: 配列
- subtask.testing_strategy: テキスト
- subtask.acceptance_criteria: 配列
- subtask.estimated_complexity: small | medium | large
- criteria_coverage: "## Criteria Coverage" セクションのテキスト

検証追加:
- 各 subtask に files_create または files_modify が 1 件以上あること
- 各 subtask に testing_strategy が空でないこと
- 各 subtask に estimated_complexity が small/medium/large のいずれかであること

### NEW: facets/instructions/review-plan.md

4軸計画検証 instruction:

| # | 観点 | チェック内容 | REJECT条件 |
|---|------|------------|-----------|
| 1 | 要件カバレッジ | design の acceptance_criteria が全て subtask に割り当てられているか | 未割り当ての criteria |
| 2 | ファイル衝突 | 同一ファイルが複数 subtask に割り当てられていないか | 衝突ファイルあり |
| 3 | スコープクリープ | subtask の files が design の file_structure に含まれるか | 計画外ファイルあり |
| 4 | Wave依存整合 | Wave2 が Wave1 成果物に正しく依存しているか | 逆依存/矛盾 |

出力: verdict (APPROVE/NEEDS_REVISION) + criteria_coverage (covered/total) + requirements traceability table + file conflict check + scope check + wave dependency check + findings (finding_id付き)

### NEW: contracts/plan-review-result.md

- verdict: APPROVE | NEEDS_REVISION
- criteria_coverage: "covered/total" テキスト
- conflicts_found: true | false
- findings: finding_id 付き

検証:
- verdict が APPROVE または NEEDS_REVISION であること
- verdict が NEEDS_REVISION の場合、findings が 1 件以上あること

### UPDATE: workflows/dev-orchestration.yaml

15 → 17 stages。design-review (stage 2) と plan-review (stage 4) を挿入。loop_monitors に 2 サイクル追加。全変数参照の整合性を維持。

---

## TAKT Comparison

| 項目 | TAKT | mosaic-orch (強化後) | 優位 |
|------|------|---------------------|------|
| 計画粒度 | ファイルレベル | ファイルレベル | 同等 |
| 設計レビュー | ai_review (1軸: AIアンチパターン) | design-review (5軸) | **mosaic-orch** |
| 計画検証 | supervisor (実装後) | plan-review (実装前) | **mosaic-orch** |
| スコープ制御 | supervisor が削除差分チェック | plan-review がファイル計画×設計照合 | **mosaic-orch** |
| 人間承認 | なし（全自動） | design + plan に承認ゲート | **mosaic-orch** |
| ループ検出 | loop_monitor (ai_review/ai_fix) | loop_monitor (design/review + plan/review + review/fix) | 同等 |
| 要件追跡 | finding_id (実装後) | finding_id (計画段階) + acceptance_criteria traceability | **mosaic-orch** |
| 並列実行 | parallel movements | fan_out/fan_in | 同等 |
