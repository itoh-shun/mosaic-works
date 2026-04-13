---
name: research-result
description: リサーチ結果の出力契約
---

# Output Contract: research-result

## 期待形式
"## Keywords" に関連キーワード一覧。
"## References" に参考リソース一覧。
"## Summary" に調査結果の要約。

## パース規則（エンジンが抽出）
- keywords: "## Keywords" から "## References" までの箇条書きを配列化。各要素は { term, description }
- references: "## References" から "## Summary" までの箇条書きを配列化。各要素は { name, url, description }
- summary: "## Summary" から末尾までのテキスト

## 検証項目
- keywords の件数が 3 以上であること（必須）
- references の件数が 2 以上であること（必須）
- summary が空でないこと（必須）
- summary が 200 文字以上であること（推奨）
