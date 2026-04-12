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
