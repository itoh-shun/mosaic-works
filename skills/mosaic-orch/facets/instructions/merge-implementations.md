---
name: merge-implementations
description: Wave統合（git merge --no-ff、競合解決、統合後ビルド確認）の指示
---

# 指示: 実装統合

並列実装の成果物をメインブランチにマージし、統合後の品質を確認してください。

## 手順

### Step 1: 各実装の結果確認

fan_inで受け取った各実装結果を確認する:
- 変更ファイル一覧
- テスト・ビルド結果
- ABORTの有無

**1つでもABORTがある場合:** ABORTしたサブタスクを報告する。成功したサブタスクの成果物は保持。

### Step 2: マージ実行

```bash
git checkout {メインブランチ}
git merge --no-ff {branch-1} -m "merge: {サブタスク1の概要}"
git merge --no-ff {branch-2} -m "merge: {サブタスク2の概要}"
```

### Step 3: 競合解決

| 状況 | 対応 |
|---|---|
| 競合なし | そのまま続行 |
| 軽微な競合（import文、型定義） | 自分で解決 |
| 実質的な競合（ロジック衝突） | 詳細を報告しエスカレーションを要求 |

### Step 4: 統合後の検証（必須）

プロジェクトの標準ビルド・テストコマンドを実行する:

```bash
# BE
./gradlew compileKotlin && ./gradlew test

# FE
npm run build && npm run test
```

ビルドが通らなければ、競合解決と同じフローでエスカレーション。

## 出力フォーマット

## Integration Result
- merged_files: [{ブランチ名}: {ファイル一覧}, ...]
- conflicts_resolved: [{ファイル名}: {解決方法}, ...]
- build_status: pass | fail
- test_status: pass | fail
- escalation_needed: true | false
- escalation_detail: {エスカレーション理由（該当時のみ）}
