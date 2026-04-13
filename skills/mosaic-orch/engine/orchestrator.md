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

0. **ユーザーオーバーライドの読み込み**:
   `~/.mosaic-orch/overrides.md` が存在する場合、Read で読み込む。
   ファイルが存在しない場合はスキップする（エラーにしない）。
   
   **オーバーライド可能な範囲:**
   - デフォルト permission モードの変更
   - 全 stage に適用する追加ポリシーの指定
   - 特定 workflow 名に対するカスタム挙動
   - Dispatcher のタイムアウト値やリトライ回数の調整
   
   **オーバーライド不可（安全性のため）:**
   - V1〜V16 の静的検証ルールの無効化
   - Stage の追加・削除・並び替え
   - Output Contract の検証スキップ
   - Loop Monitor の無効化

1. workflowPath を Read して YAML をパースする
2. yaml-schema.md の静的検証ルール（V1〜V16）を全て実行する
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
8. stageHistory = []（遷移履歴。Loop Monitor 用）
9. loopMonitors = workflow.loop_monitors || []
10. startTime = 現在時刻（COMPLETE/ABORT 時の duration 計算用）
11. stagesRunCount = 0（実際に実行された stage カウンタ）

→ [RESOLVE_STAGE] に進む

### RESOLVE_STAGE

1. stageIndex >= stages.length なら → [COMPLETE]
2. currentStage = stages[stageIndex]
3. **when のみ先行展開**: currentStage.when がある場合、when フィールドのみを variable-resolver で展開する
   - VariableUnresolved → ABORT
4. run-recorder.recordEvent(runDir, { event: "stage_start", stage_id: currentStage.id })

→ [CHECK_WHEN] に進む

> **注意**: input, from, loop_until, skills の展開は CHECK_WHEN 通過後（RUN_STAGE の直前）に行う。
> これにより、when=false でスキップされる stage の変数参照が未解決でも ABORT しない。

### CHECK_WHEN

1. currentStage.when が未定義 → [RUN_STAGE] に進む
2. when 条件を評価する（stage-runner.md の比較演算ルールを使う）
3. true → [RUN_STAGE] に進む
4. false → [SKIP] に進む

### SKIP

1. run-recorder.recordEvent(runDir, { event: "stage_skip", stage_id: currentStage.id, reason: "when=false" })
2. → [ADVANCE] に進む

### RUN_STAGE

0. **残りの変数展開**: currentStage の input, from, loop_until, skills を variable-resolver で展開する
   - skills が `${...}` 形式の単一変数参照の場合: 配列に展開する（例: `${subtask.skills}` → `["tdd", "owasp-security"]`）
   - VariableUnresolved → ABORT
1. stage-runner に委譲する:
   ```
   stageRunner.run(
     stage: currentStage,
     input: 展開済み input,
     permission: currentStage.permission || defaults.permission || permission,
     timeout: currentStage.timeout || defaults.timeout,
     dryRun: dryRun,
     runDir: runDir,
     workflowName: workflow.name,
     stageIndex: stageIndex,
     totalStages: stages.length
   )
   ```
2. 結果を受け取る:
   - 成功 → output を context に追加:
     - task/fan_in: `context[stage.id] = { output: result }`
     - fan_out: `context[stage.id] = { outputs: resultArray }`
   - StageFailure → ABORT

3. stagesRunCount += 1
4. run-recorder.recordEvent(runDir, { event: "stage_complete", stage_id: currentStage.id })

→ [CHECK_LOOP] に進む（stage-runner が loop_until を内部処理するため、Orchestrator レベルでは loop はない）

### CHECK_LOOP

loop_until は stage-runner 内部で処理される。Orchestrator はこの状態を通過するだけ。

- result に loop_exhausted=true がある場合:
  run-recorder.recordEvent(runDir, { event: "loop_exhausted", stage_id: currentStage.id })

→ [ADVANCE] に進む

### ADVANCE

1. stageHistory に currentStage.id を追加する
2. **Loop Monitor チェック**（loopMonitors が空でない場合のみ）:
   各 monitor に対して:
   a. stageHistory の末尾が monitor.cycle パターンを threshold 回以上繰り返しているか判定する
      - 例: cycle=[review, fix], threshold=3 → 履歴末尾に review,fix,review,fix,review,fix が含まれるか
   b. 閾値に達した場合:
      1. run-recorder.recordEvent(runDir, { event: "loop_monitor_triggered", cycle: monitor.cycle, count: cycleCount })
      2. monitor.judge.persona を facet-loader で解決して system prompt を取得
      3. monitor.judge.instruction の `{cycle_count}` を実際のサイクル数に置換する
      4. Dispatcher で judge サブエージェントを起動する
      5. judge の出力を monitor.judge.decisions で評価する:
         - decisions を上から順にチェックし、judge 出力に decision.contains が含まれていたらマッチ
         - マッチした decision の goto に従う:
           - `"COMPLETE"` → [COMPLETE]
           - `"ABORT"` → [ABORT]
           - stage ID → stageIndex をセットし [RESOLVE_STAGE] に戻る
         - どの decision にもマッチしない場合: WARN を出力し、通常の next 評価に進む
3. currentStage に `next` フィールドがあるか確認する
4. `next` がある場合:
   a. next の rules を上から順に評価する（stage-runner.md の比較演算ルールを使う）
   b. 最初にマッチした rule の `goto` を取得:
      - `goto` が `"COMPLETE"` → [COMPLETE] に進む
      - `goto` が `"ABORT"` → [ABORT] に進む
      - `goto` が stage ID → その stage の index を stageIndex にセットし、[RESOLVE_STAGE] に戻る
   c. どの rule にもマッチしなかった場合 → stageIndex += 1
5. `next` がない場合:
   stageIndex += 1
6. → [RESOLVE_STAGE] に戻る

### COMPLETE

1. 最後に成功した Stage の output を final output とする
2. run-recorder.recordFinal(runDir, finalOutput)
2.5. run-recorder.recordMosaic(workflowName, lastReviewGrade or "N/A", "complete", {
     project: basename(cwd),
     stages_run: stagesRunCount,
     total_stages: stages.length,
     duration_s: (現在時刻 - startTime) を秒に変換
   })
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
1.5. run-recorder.recordMosaic(workflowName, "N/A", "abort", {
     project: basename(cwd),
     stages_run: stagesRunCount,
     total_stages: stages.length,
     duration_s: (現在時刻 - startTime) を秒に変換
   })
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
