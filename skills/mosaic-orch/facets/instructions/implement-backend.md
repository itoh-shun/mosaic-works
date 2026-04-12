---
name: implement-backend
description: Kotlin BE実装の具体的手順指示
---

# 指示: バックエンド実装

Kotlinでのバックエンド実装を行ってください。

## 手順

### Step 1: 既存コード調査

- 関連する既存コードのパターン（命名規約、ディレクトリ構造、エラーハンドリング方式）を調査する
- 同種の既存実装があれば、それに倣う

### Step 2: テスト先行（TDD）

- BE振る舞い変更の場合、まずテストを書く
- テスト名は振る舞いを説明する形式（「何をしたら何が起きる」）
- AAA / GWT パターンで構造化する

### Step 3: 実装

- 既存パターンに従ってコードを書く
- 以下を意識する:
  - N+1回避（batchInsert/Upsert活用、JOINの適切な使用）
  - トランザクション境界の設計
  - バリデーションの網羅（境界値、null安全性）
  - sealed class / data class / 拡張関数の適切な活用

### Step 4: ビルド・lint・テスト実行（必須）

以下のコマンドをすべて実行し、結果を報告する:

```bash
./gradlew compileKotlin
./gradlew detekt
./gradlew ktlintCheck
./gradlew test --tests "{関連テストクラス}"
```

テスト実行なしでの報告は不可。コンパイル通過のみも不可。

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
