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
