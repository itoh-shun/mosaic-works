---
name: implement-e2e
description: Playwright E2Eテストのスキャフォールド・実行指示
---

# 指示: E2Eテスト実装

PlaywrightでのE2Eテストをスキャフォールド・実装してください。

## 手順

### Step 1: 既存テストパターン調査

- Input に Codebase Context が含まれている場合、それを基に調査範囲を絞る
- 既存のE2Eテスト（Page Object、Fixture）のパターンを調査する
- テストディレクトリの構成を確認する

### Step 2: テストシナリオ設計

- ユーザーフロー全体を検証するシナリオを設計する
- 正常系フローを最低1本、異常系フローを最低1本
- レスポンシブ検証が必要な場合はビューポート設定を含める

### Step 3: E2Eテスト実装

- 既存のPage Object・Fixtureパターンに沿ったテストを生成する
- フレイキーテストの原因になる実装を避ける:
  - 固定waitの代わりにlocator.waitFor()を使う
  - テストデータの独立性を確保する
  - ネットワーク待ちはwaitForResponse()を使う

### Step 4: テスト実行

```bash
npx playwright test {テストファイル} --reporter=list
```

### Step 5: ローカルコミット

```bash
git add {変更ファイル}
git commit -m "test(e2e): {subject}"
```

pushはしない（no-push ポリシー）。

## 出力フォーマット

## Implementation Result
- files_changed: [{ファイルパス}, ...]
- test_results: {テスト実行コマンドと出力}
- build_status: pass | fail
- self_assessment: {実装の所感}
- scenarios_covered: [{シナリオ名}, ...]
