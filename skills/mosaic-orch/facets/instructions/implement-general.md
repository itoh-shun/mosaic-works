---
name: implement-general
description: 汎用実装（言語非依存）の手順指示
---

# 指示: 汎用実装

言語やフレームワークに依存しない汎用的な実装を行ってください。

## 手順

### Step 1: 既存コード調査

- 関連する既存コードのパターン（命名規約、ディレクトリ構造）を調査する
- 同種の既存実装があれば、それに倣う

### Step 2: テスト環境の確認と整備

- **テストフレームワークが未導入の場合、先に導入する**:
  - Node.js: `node:test` (組込み) または Vitest
  - React: Vitest + @testing-library/react
  - Kotlin: JUnit (通常導入済み)
  - テストを書けない環境で実装を進めてはならない
- 振る舞い変更がある場合はテストを書く
- 設定変更のみの場合はテスト不要
- APIやHTTPエンドポイントの変更がある場合、**ユニットテストとHTTP統合テストの両方**を書く
- テストは Red-Green-Refactor サイクルに従う（テスト先行 → 最小実装 → リファクタ）

### Step 3: 実装

- 既存パターンに従ってコードを書く
- 既存コードベースの命名・構造パターンを踏襲する
- 必要最小限の変更に留める（YAGNI原則）

### Step 4: ビルド・テスト実行（必須）

プロジェクトの標準ビルド・テストコマンドを実行し、結果を報告する。使用可能なコマンドはプロジェクトのpackage.json、build.gradle等から判定する。

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
- self_assessment: {実装の所感 — 定量的根拠を含む}
- concerns: {懸念事項があれば}
