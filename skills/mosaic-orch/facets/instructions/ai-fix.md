---
name: ai-fix
description: AIレビュー指摘に対する修正実施、または修正不要判断
---

# 指示: AI Review 指摘の修正

ai-review stage が REJECT 判定で出力した findings に対して、修正を実施してください。

## 重要: 前回の認識を疑う

**2回目以降の実行では、前回の修正が実際には行われていなかった可能性が高い。**
「修正済み」という自分の認識を信用せず、必ず Read tool で事実確認してください。

**まず認めること:**
- 「修正済み」と思っていたファイルは実際には修正されていない可能性がある
- 前回の作業内容の認識が間違っているかもしれない
- ゼロベースで考え直す必要がある

## 手順

### Step 1: ai-review findings の確認

Input に含まれる AI Review 結果の findings (new + persists) を列挙する。

### Step 2: 各 finding の事実確認（必須）

各 finding について:

1. **Read tool で対象ファイルを開く**（思い込みを捨てて事実確認）
2. **grep で問題箇所を検索**して実在を確認
3. 実在する場合: Step 3 へ
4. 実在しない場合: 前回修正が反映されている可能性を検証。Step 4 の「修正不要」判断へ

### Step 3: 修正の実施

1. Edit tool で修正を適用
2. 該当するテストを実行して検証
3. 変更内容を記録

### Step 4: 「修正不要」の厳格な扱い

修正不要と判断できるのは以下の条件すべてを満たす場合のみ:

- 対象ファイルを Read で確認した
- 該当箇所に問題が存在しないことを grep で確認した
- 確認結果を具体的に報告できる（ファイル:行番号、確認した内容）

**修正不要と判断する場合でも、必ず以下を出力する:**
- 確認したファイル
- 実行した検索コマンド
- なぜ修正不要と判断したか

**絶対に禁止:**
- ファイルを開かずに「修正済み」と報告
- 思い込みで判断
- ai-review が指摘した問題の放置

## 出力フォーマット（厳守 — この形式以外は Contract Violation）

## AI Fix
- action: fixed | no_fix_needed | partial
- findings_addressed: {件数}/{全件数}

## Verified Files
- {ファイルパス:行番号}: {確認した内容}

## Searches Executed
- `{grepコマンド}`: {要約}

## Fixes Applied
### Fix N
- finding_id: {対象の finding_id}
- file: {ファイルパス:行番号}
- change: {変更内容}
- test_result: {テスト実行結果}

## No Fix Needed
### Finding N
- finding_id: {対象の finding_id}
- reason: {修正不要の理由}
- evidence: {ファイル:行番号 で確認した結果}

（Fixes Applied / No Fix Needed は該当がない場合は「なし」と記載）

## Test Summary
- {実行コマンド}: {PASS/FAIL + 件数}
