---
name: mcp-catalog
description: 利用可能なMCPツール一覧と選定ガイド。ユーザー環境依存のため、analyze時にToolSearchで存在確認して使う。
---

# MCP Catalog

MCPツールはユーザー環境ごとに異なる。analyze stage では ToolSearch で利用可能なMCPを検出し、各サブタスクに適切なMCPを割り当てる。

## 検出方法

```
ToolSearch で "mcp__" をキーワード検索し、利用可能なMCPプレフィックスを特定する。
```

## よくあるMCPと用途

| MCPプレフィックス | 説明 | 適用タスク |
|---|---|---|
| `mcp__context7__` | ライブラリの最新ドキュメント参照 | FE/BE実装でライブラリAPI使用時 |
| `mcp__pencil__` | UIデザイン作成・検証（.penファイル） | FEデザイン・UI検証時 |
| `mcp__powerpoint-server__` | プレゼンテーション生成 | ドキュメント・報告時 |

## 選定の原則

1. **ToolSearch で存在を確認**してから割り当てる（存在しないMCPを割り当てない）
2. 1サブタスクあたり0〜2個に絞る
3. MCP未検出の場合は割り当てない（mcpsフィールドを省略）
4. MCPはSkillsと違い**呼ばなくてもContractViolationにはしない**（あくまで「利用可能」の通知）
