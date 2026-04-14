---
name: design-result
description: 設計仕様の出力契約
---

# Output Contract: design-result

## 期待形式
"## Codebase Context" 見出しの下にプロジェクト診断結果、"## Requirements" 見出しの下に要件分析、"## Architecture" 見出しの下にアーキテクチャ設計。

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

## 検証項目
- codebase_context が空でないこと（必須）
- impact_layer が "FE", "BE", "both", "non-engineering" のいずれかであること（必須）
- task_type が "feature", "bugfix", "refactor", "test", "docs", "content" のいずれかであること（必須）
- has_fe が "true" または "false" であること（必須）
- scope が空でないこと（必須）
- approach が空でないこと（必須）
