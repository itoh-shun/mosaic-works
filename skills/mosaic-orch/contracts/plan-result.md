---
name: plan-result
description: タスク計画の出力契約（ファイル割り当て・テスト戦略・受入基準を含む）
---

# Output Contract: plan-result

## 期待形式
"## Analysis" 見出しの下にモード情報、"## Wave 1 Subtasks" と "## Wave 2 Subtasks" にサブタスク一覧、"## Criteria Coverage" に受入基準カバレッジテーブル。

## パース規則（エンジンが抽出）
- mode: "## Analysis" セクション内の "- mode:" 直後のテキスト。正規表現 /^(parallel|wave)$/
- has_wave2: "- has_wave2:" 直後のテキスト。正規表現 /^(true|false)$/
- has_fe: "- has_fe:" 直後のテキスト。正規表現 /^(true|false)$/
- wave1_subtasks: "## Wave 1 Subtasks" セクション内の "### Subtask" で始まる見出しごとにブロック分割し配列化。各ブロックから:
  - persona: "- persona:" 直後のテキスト
  - instruction: "- instruction:" 直後のテキスト
  - description: "- description:" 直後のテキスト
  - files_create: "- files_create:" 直後のテキスト（配列として解析）
  - files_modify: "- files_modify:" 直後のテキスト（配列として解析）
  - skills: "- skills:" 直後のテキスト（配列として解析）
  - mcps: "- mcps:" 直後のテキスト（配列として解析、空の場合は空配列）
  - testing_strategy: "- testing_strategy:" 直後のテキスト
  - acceptance_criteria: "- acceptance_criteria:" 直後のテキスト（配列として解析）
  - estimated_complexity: "- estimated_complexity:" 直後のテキスト。正規表現 /^(small|medium|large)$/
- wave2_subtasks: "## Wave 2 Subtasks" セクション内を同様に解析。セクションがない場合は空配列
- criteria_coverage: "## Criteria Coverage" セクション全体のテキスト

## 検証項目
- mode が "parallel" または "wave" であること（必須）
- has_wave2 が "true" または "false" であること（必須）
- has_fe が "true" または "false" であること（必須）
- wave1_subtasks の件数が 1 以上であること（必須）
- 各 subtask に persona が空でないこと（必須）
- 各 subtask に instruction が空でないこと（必須）
- 各 subtask に files_create または files_modify が 1 件以上あること（必須）
- 各 subtask に testing_strategy が空でないこと（必須）
- 各 subtask に estimated_complexity が small/medium/large のいずれかであること（必須）
- has_wave2 が true の場合、wave2_subtasks の件数が 1 以上であること（必須）
- criteria_coverage が空でないこと（必須）
