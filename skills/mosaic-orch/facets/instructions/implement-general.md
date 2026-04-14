---
name: implement-general
description: 汎用実装（言語非依存）の手順指示
---

# 指示: 汎用実装

言語やフレームワークに依存しない汎用的な実装を行ってください。

## 手順

### Step 1: 既存コード調査

- Input に Codebase Context が含まれている場合、それを基に調査範囲を絞る
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
- 必要最小限の変更に留める
- **型定義とAPI仕様の整合性を確認する**: フィールドが型で必須なら、APIでも必須にする（省略可能にするなら型も`?`にする）
- **型の重複を避ける**: 同じ型がserver/clientで重複する場合、共有ファイルへの移動を検討する

### Step 4: ビルド・テスト実行（必須 — スキップ厳禁）

以下を**すべて実行**し、出力をそのまま貼り付けること。実行せずに「テストを書いた」「ビルドが通る」と報告してはならない。

1. **ビルドコマンド実行**: `npm run build`, `tsc --noEmit`, `./gradlew compileKotlin` 等
   - **ビルドが失敗したらコミットしてはならない。** 先にビルドエラーを修正すること
   - tsconfig.json の設定不備（`allowImportingTsExtensions` 等）もここで検出・修正する
2. **テスト実行**: `npm test`, `node --test`, `./gradlew test` 等
   - テストが0件の場合: テストを書いてから再実行する（テスト0件でのコミッ��禁止）
   - **追加した機能そのもの**のテストが含まれていることを確認する（無関係なテストだけでは不可）
3. **APIエンドポイントを変更し��場合のHTTP統合テスト**:
   - サーバーを起動し、実際にHTTPリクエストを送るテストを書く
   - 最低限: 正常系リクエスト→期待レスポンス、異常系（404, 400）の2パターン
   - 例:
     ```typescript
     // node:test + fetch での統合テスト例
     test('GET /api/tasks returns tasks', async () => {
       const res = await fetch('http://localhost:3000/api/tasks');
       assert.equal(res.status, 200);
       const body = await res.json();
       assert(Array.isArray(body));
     });
     ```

### Step 5: ローカルコミット

**ビルドとテストが全て PASS した後にのみ**コミットする:

```bash
git add {変更ファイル}
git commit -m "{type}({scope}): {subject}"
```

pushはしない（no-push ポリシー）。

## 出力フォーマット

## Implementation Result
- files_changed: [{ファイルパス}, ...]
- test_results: {テスト実行コマンドと出力をそのまま貼り付け}
- test_count: {passしたテストの件数（数値）}
- build_status: pass | fail
- build_command: {実行したビルドコマンド}
- skills_used: [{実際にSkill toolで起動したスキル名}]
- self_assessment: {実装の所感 — 定量的根拠を含む}
- concerns: {懸念事項があれば}
