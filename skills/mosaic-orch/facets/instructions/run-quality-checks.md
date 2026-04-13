---
name: run-quality-checks
description: PRサイズ・テスト存在・ビルドlintの品質ゲートチェック指示
---

# 指示: 品質ゲートチェック

統合後のコード全体に対して品質ゲートチェックを実行してください。

## 手順

### Step 1: PRサイズチェック

```bash
git diff --stat {base-branch}...HEAD | tail -1
```

| サイズ | 判定 |
|---|---|
| S (~100行) / M (~200行) | PASS |
| L (~400行) | WARN — PR本文に理由記載で許可 |
| XL (400行超) | FAIL — Stacked PRに分割を指示 |

### Step 2: テスト存在確認

変更ファイルを分析し、テスト要否を判定する:

| 変更種別 | テスト要否 |
|---|---|
| BE振る舞い変更 | **必須** |
| FEロジック | 推奨 |
| FE UIのみ | 不要（視覚検証で代替） |
| 型定義・設定のみ | 不要 |

テスト不足 → FAIL（差し戻し指示を含める）

### Step 3: テスト・ビルド・lint 実行確認

各実装agentの報告を確認する:
- テスト実行結果が報告されているか（コンパイル通過のみの報告は不合格）
- 関連領域のテストが実行されているか
- ビルドが通過しているか
- lintが通過しているか

テスト失敗がある場合、ベースブランチでも同じテストを実行し、既存不具合か変更起因かを切り分ける。

### Step 4: マイグレーション確認

DBスキーマ変更を含む場合、マイグレーションスクリプトが存在するか確認する。なければFAIL。

## 詳細チェック手順

### PRサイズ判定
| サイズ | 行数 | 判定 |
|---|---|---|
| S | ~100 | ✅ PASS |
| M | ~200 | ✅ PASS |
| L | ~400 | ⚠️ PR本文に理由記載で許可 |
| XL | 400超 | ❌ FAIL → 分割を検討 |

### テスト確認
1. 振る舞い変更があるか確認: `git diff --name-only` で変更ファイルを列挙
2. テストファイルが含まれているか確認
3. テストが実行されたか確認（実装者の報告に「テスト結果」があるか）
4. テスト失敗がある場合、ベースブランチでも同じテストを実行して切り分け

### ビルド確認
- BE変更: `./gradlew :server:core:compileKotlin` or 該当モジュール
- FE変更: `cd ui && npm run build`
- Lint: `detekt` / `ktlintCheck` / `npm run lint`
- 上記コマンドの出力を報告に含めること

## 出力フォーマット

## Quality Result
- pr_size: {行数}
- pr_size_verdict: S | M | L | XL
- test_exists: true | false
- test_sufficient: true | false
- build_lint_ok: true | false
- migration_ok: true | false | N/A
- overall: pass | fail
- fail_reasons: [{理由1}, {理由2}, ...]
