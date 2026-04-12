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
