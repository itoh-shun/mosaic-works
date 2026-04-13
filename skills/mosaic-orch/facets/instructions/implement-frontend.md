---
name: implement-frontend
description: React FE実装の具体的手順指示
---

# 指示: フロントエンド実装

React/TypeScript/MUIでのフロントエンド実装を行ってください。

## 実装前の設計確認（5分以内）

コードを書く前に以下を確認する:

1. **既存コンポーネントの確認**: 同種のUIがどう実装されているか、既存コンポーネントを2-3箇所読む
2. **Props設計**: 新しいコンポーネントのProps型を先に決める（実装前に型で考える）
3. **状態管理の方針**: ローカルstate / 上位からのprops / グローバル状態のどれを使うか
4. **レスポンシブ対応**: デスクトップとモバイルの両方で確認が必要か判断する

## 手順

### Step 1: 既存コード調査

- 関連する既存コンポーネントのパターン（ディレクトリ構造、命名、Props設計）を調査する
- デザインシステムの使用パターンを確認する（MUIテーマ、カラー、スペーシング）

### Step 2: テスト方針の確認

- FEロジック変更の場合はテストを書く（推奨）
- FE UIのみ変更の場合はテスト不要（UI視覚検証で代替）

### Step 3: 実装

- 既存パターンに従ってコンポーネントを書く
- 以下を意識する:
  - コンポーネントの再利用性（Props設計の妥当性）
  - レスポンシブ対応（mobile-first）
  - アクセシビリティ（セマンティックHTML、ARIA、キーボード操作）
  - 型安全性（any/unknown の使用禁止、明示的な型注釈）
  - MUIデザインシステムとの一貫性

### Step 4: ビルド・lint・テスト実行（必須）

以下のコマンドをすべて実行し、結果を報告する:

```bash
npm run build
npm run lint
npm run test -- --run {関連テストファイル}
```

### Step 5: ローカルコミット

```bash
git add {変更ファイル}
git commit -m "{type}({scope}): {subject}"
```

pushはしない（no-push ポリシー）。

## 出力フォーマット

## Implementation Result
- files_changed: [{ファイルパス}, ...]
- test_results: {テスト実行コマンドと出力}
- build_status: pass | fail
- lint_status: pass | fail
- self_assessment: {実装の所感 — 定量的根拠を含む}
- concerns: {懸念事項があれば}
