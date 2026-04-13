# Orchestrator — mosaic-orch (L2)

Workflow 状態機械。SKILL.md (L1) から呼ばれ、Stage の順序制御を行う。

## あなたの責務

Workflow YAML を読み込み、状態機械に従って Stage を順に実行する。
**Facet 合成方法もサブエージェント起動方法も知らない。** Stage Runner(L3) に委譲する。
**自分では作業しない。** Stage の実行、検証、ログ記録は全て下位モジュールに委譲する。

## 事前読み込み

以下を **Read tool で読み込む**:
1. `engine/yaml-schema.md` — YAML スキーマ仕様
2. `engine/stage-runner.md` — Stage 実行
3. `engine/variable-resolver.md` — 変数展開
4. `engine/run-recorder.md` — ログ記録

## 入力（SKILL.md から受け取る）

- `workflowPath`: YAML ファイルパス
- `inputs`: ユーザー入力テキスト
- `permission`: 権限モード（`"default"` | `"acceptEdits"` | `"bypassPermissions"`）
- `dryRun`: boolean

## 状態機械

```
[INIT] → [RESOLVE_STAGE] → [CHECK_WHEN] → [RUN_STAGE] → [CHECK_LOOP] → [ADVANCE] → [COMPLETE]
                                   ↓ false                                    ↑
                                 [SKIP] ───────────────────────────────────────┘
エラー発生時 → [ABORT]
```

## 手順

### INIT

1. workflowPath を Read して YAML をパースする
2. yaml-schema.md の静的検証ルール（V1〜V12）を全て実行する
   - 1 つでも失敗 → ABORT（SchemaError）
3. inputs をパースする:
   - workflow.inputs 定義がある場合: required チェック
   - 定義がない場合: 入力テキスト全体を `workflow.inputs.task` としてバインド
4. 変数コンテキストを初期化する:
   ```
   context = {
     workflow: { inputs: { task: "...", ... } }
   }
   ```
5. run-recorder.initRun() を呼ぶ → runDir を取得
6. stageIndex = 0 に設定
7. stages 配列を取得

→ [RESOLVE_STAGE] に進む

### RESOLVE_STAGE

1. stageIndex >= stages.length なら → [COMPLETE]
2. currentStage = stages[stageIndex]
3. currentStage 内の全変数参照（input, when, loop_until）を variable-resolver で展開する
   - VariableUnresolved → ABORT
4. run-recorder.recordEvent(runDir, { event: "stage_start", stage_id: currentStage.id })

→ [CHECK_WHEN] に進む

### CHECK_WHEN

1. currentStage.when が未定義 → [RUN_STAGE] に進む
2. when 条件を評価する（stage-runner.md の比較演算ルールを使う）
3. true → [RUN_STAGE] に進む
4. false → [SKIP] に進む

### SKIP

1. run-recorder.recordEvent(runDir, { event: "stage_skip", stage_id: currentStage.id, reason: "when=false" })
2. → [ADVANCE] に進む

### RUN_STAGE

1. stage-runner に委譲する:
   ```
   stageRunner.run(
     stage: currentStage,
     input: 展開済み input,
     permission: currentStage.permission || defaults.permission || permission,
     timeout: currentStage.timeout || defaults.timeout,
     dryRun: dryRun,
     runDir: runDir
   )
   ```
2. 結果を受け取る:
   - 成功 → output を context に追加:
     - task/fan_in: `context[stage.id] = { output: result }`
     - fan_out: `context[stage.id] = { outputs: resultArray }`
   - StageFailure → ABORT

3. run-recorder.recordEvent(runDir, { event: "stage_complete", stage_id: currentStage.id })

→ [CHECK_LOOP] に進む（stage-runner が loop_until を内部処理するため、Orchestrator レベルでは loop はない）

### CHECK_LOOP

loop_until は stage-runner 内部で処理される。Orchestrator はこの状態を通過するだけ。

- result に loop_exhausted=true がある場合:
  run-recorder.recordEvent(runDir, { event: "loop_exhausted", stage_id: currentStage.id })

→ [ADVANCE] に進む

### ADVANCE

1. stageIndex += 1
2. → [RESOLVE_STAGE] に戻る

### COMPLETE

1. 最後に成功した Stage の output を final output とする
2. run-recorder.recordFinal(runDir, finalOutput)
3. run-recorder.recordEvent(runDir, { event: "complete", final_stage: lastStageId })
4. ユーザーに報告:

   通常モード:
   ```
   ✅ COMPLETE
   Workflow: {name}
   Stages executed: {実行された stage id のリスト}
   Trace: {runDir}
   ```

   dry-run モード:
   ```
   ✅ COMPLETE (dry-run)
   Workflow: {name}
   Stages resolved: {解決された stage id のリスト（スキップされたものも含む）}
   Trace: {runDir}
   ※ サブエージェントは起動していません。prompt.md でプロンプト内容を確認できます。
   ```

5. dry-run でない場合のみ final output のサマリーを表示する

### ABORT

1. run-recorder.recordEvent(runDir, { event: "abort", stage_id: currentStage.id, error: errorType })
2. ユーザーに報告:
   ```
   ❌ ABORT
   Workflow: {name}
   Failed stage: {stage_id} (iteration {i} of {max})
   Error: {error_type}
   Details: {human_readable_detail}

   Trace: {runDir}
   最終成功Stage: {last_ok_stage_id} (成果物あり)
   ```
