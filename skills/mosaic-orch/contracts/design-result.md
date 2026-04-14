---
name: design-result
description: 設計仕様の出力契約（ファイル構成・スコープ規律・受入基準を含む）
---

# Output Contract: design-result

## 期待形式
"## Codebase Context" にプロジェクト診断結果、"## Requirements" に要件分析、"## Architecture" にアーキテクチャ設計、"## File Structure" にファイル構成テーブル、"## Design Patterns" に設計パターン、"## Implementation Guidelines" に実装指針、"## Scope Boundaries" にスコープ規律、"## Acceptance Criteria" に受入基準。

## パース規則（エンジンが抽出）
- codebase_context: "## Codebase Context" セクション全体のテキスト（後続 stage への参照用）
- impact_layer: "## Requirements" セクション内の "- impact_layer:" 直後のテキスト。正規表現 /^(FE|BE|both|non-engineering)$/
- task_type: "- task_type:" 直後のテキスト。正規表現 /^(feature|bugfix|refactor|test|docs|content)$/
- has_fe: "- has_fe:" 直後のテキスト。正規表現 /^(true|false)$/
- scope: "- scope:" 直後のテキスト
- constraints: "- constraints:" 直後のテキスト
- approach: "## Architecture" セクション内の "- approach:" 直後のテキスト
- pattern_reuse: "- pattern_reuse:" 直後のテキスト。正規表現 /^(true|false)$/
- risks: "- risks:" 直後のテキスト
- dependencies: "- dependencies:" 直後のテキスト
- file_structure: "## File Structure" セクション内のテーブル行をパース。各行から:
  - action: 第1カラム（create | modify）
  - path: 第2カラム（ファイルパス）
  - responsibility: 第3カラム（責務説明）
- design_patterns: "## Design Patterns" セクション内の "- pattern:" で始まるブロックを配列化。各ブロックから:
  - pattern: "- pattern:" 直後のテキスト
  - apply_to: "apply_to:" 直後のテキスト
  - reason: "reason:" 直後のテキスト
- implementation_guidelines: "## Implementation Guidelines" セクション全体のテキスト
- scope_boundaries: "## Scope Boundaries" セクション内から:
  - in_scope: "- in_scope:" 直後のテキスト
  - out_of_scope: "- out_of_scope:" 直後のテキスト
  - deletion_policy: "- deletion_policy:" 直後のテキスト
- acceptance_criteria: "## Acceptance Criteria" セクション内の "- [ ]" で始まる各行を配列化
- open_questions: "## Open Questions" セクション内の "- " で始まる各行を配列化（「なし」のみの場合は空配列）

## 検証項目
- codebase_context が空でないこと（必須）
- impact_layer が "FE", "BE", "both", "non-engineering" のいずれかであること（必須）
- task_type が "feature", "bugfix", "refactor", "test", "docs", "content" のいずれかであること（必須）
- has_fe が "true" または "false" であること（必須）
- scope が空でないこと（必須）
- approach が空でないこと（必須）
- file_structure の件数が 1 以上であること（必須）
- implementation_guidelines が空でないこと（必須）
- scope_boundaries の in_scope が空でないこと（必須）
- acceptance_criteria の件数が 1 以上であること（必須）
