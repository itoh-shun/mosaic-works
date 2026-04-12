# Error Handling Reference — mosaic-orch

## エラー分類

| エラー名 | 発生層 | 原因 | 対応 |
|---|---|---|---|
| SchemaError | L2 INIT | YAML不正、必須フィールド欠落、型不一致 | 即ABORT。YAML修正を案内 |
| VariableUnresolved | L2 RESOLVE | ${...}参照先不在 | 即ABORT。利用可能な変数キーを報告 |
| FacetNotFound | L4 Composer | facets/{kind}/{name}.md 不在 | 即ABORT。検索パスを報告 |
| DispatchTimeout | L5 Dispatcher | Task tool 応答なし | 1回リトライ → 失敗でStageFailure |
| ContractViolation | Contracts | 出力が契約を満たさない | 2回同Stage再実行 → 失敗でStageFailure |
| StageFailure | L3 | 上記いずれかの伝播 | loop_untilあればループ、なければABORT |
| LoopExhausted | L3 | max_iterations到達 | フラグ付きで次Stage。ABORTしない |

## ABORT テンプレート

```
❌ ABORT
Workflow: {name}
Failed stage: {stage_id} (iteration {i} of {max})
Error: {error_type}
Details: {human_readable_detail}

Trace: .mosaic-orch/runs/{slug}/
最終成功Stage: {last_ok_stage_id}
```

## ContractViolation のデバッグ

1. `.mosaic-orch/runs/{slug}/stages/{stage_id}/response.md` を確認
2. 期待形式と実出力を比較
3. よくある原因:
   - サブエージェントが見出し形式を間違えている（`## Grade` vs `# Grade`）
   - 箇条書きのプレフィックスが違う（`- ` vs `* `）
   - 空行が足りない
4. 対策: instruction facet に出力フォーマットをより明示的に記載する
