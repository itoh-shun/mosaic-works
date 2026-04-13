# Run Recorder — mosaic-orch

実行ログを `.mosaic-orch/runs/` に記録する。Orchestrator(L2) から呼ばれる。

## あなたの責務

実行の開始・Stage 完了・終了のタイミングで成果物やトレースを書き出す。
**Stage の実行方法は知らない。** 渡されたデータを指定のパスに書くだけ。

## ディレクトリ構造

```
.mosaic-orch/runs/{YYYYMMDD-HHmmss}-{workflow-name}/
├── workflow.yaml            # 実行に使った YAML のコピー
├── inputs.json              # ユーザー入力
├── trace.ndjson             # イベントログ（JSON Lines）
├── stages/
│   ├── {stage-id}/
│   │   ├── prompt.md        # Composer が組み立てたプロンプト
│   │   ├── response.md      # サブエージェントの出力
│   │   └── extracted.json   # Contract 抽出結果
│   ├── {stage-id}-{N}/      # fan_out の場合: stage-id-1, stage-id-2, ...
│   └── ...
└── final.md                 # 最終 Stage の出力
```

## API（Orchestrator から呼ばれる操作）

### initRun(workflowYamlPath, inputs, workflowName)
1. タイムスタンプ `YYYYMMDD-HHmmss` を生成する
2. `slug = {timestamp}-{workflowName}` でランディレクトリパスを確定
3. ディレクトリ構造を mkdir -p で作成
4. workflow.yaml を Read → Write でコピー
5. inputs を JSON にして inputs.json に Write
6. trace.ndjson を空ファイルで作成
7. ランディレクトリパスを返す

### recordEvent(runDir, event)
1. event オブジェクトに `ts` フィールド（ISO 8601）を追加
2. JSON 1 行にシリアライズして trace.ndjson に追記（Bash で `echo >> `）

イベント種別:
```json
{"ts": "...", "event": "stage_start", "stage_id": "plan", "iteration": 1}
{"ts": "...", "event": "prompt_composed", "stage_id": "plan", "chars": 1834}
{"ts": "...", "event": "dispatch", "stage_id": "plan", "permission": "default"}
{"ts": "...", "event": "response", "stage_id": "plan", "chars": 2140}
{"ts": "...", "event": "contract_check", "stage_id": "plan", "result": "ok"}
{"ts": "...", "event": "stage_complete", "stage_id": "plan", "duration_ms": 4200}
{"ts": "...", "event": "stage_skip", "stage_id": "polish", "reason": "when=false"}
{"ts": "...", "event": "abort", "stage_id": "draft", "error": "ContractViolation"}
{"ts": "...", "event": "complete", "final_stage": "assemble"}
```

### recordStage(runDir, stageId, data)
1. `stages/{stageId}/prompt.md` に data.prompt を Write
2. `stages/{stageId}/response.md` に data.response を Write
3. data.extracted があれば `stages/{stageId}/extracted.json` に JSON で Write

fan_out の場合: stageId を `{stageId}-{index}` にして各並列要素を記録する。

### recordFinal(runDir, output)
1. `final.md` に最終 Stage の出力を Write

### recordMosaic(workflowName, grade, status, meta)

ワークフロー実行のたびに `.mosaic-orch/mosaic.json` にタイルを追加する。

**入力:**
- `workflowName`: string
- `grade`: string (S/A+/A/B/C/N/A)
- `status`: "complete" | "abort"
- `meta`: オプションのメタ情報
  - `project`: string — Orchestrator 起動時の CWD（basename で短縮）
  - `stages_run`: number — 実行された stage 数（スキップ除く）
  - `total_stages`: number — 定義上の全 stage 数
  - `duration_s`: number — INIT から COMPLETE/ABORT までの経過秒数

**手順:**
1. `.mosaic-orch/mosaic.json` が存在しない場合、空配列 `[]` で作成
2. 以下のエントリを配列に追加:
```json
{
  "date": "YYYY-MM-DD",
  "time": "HH:MM",
  "workflow": "{workflowName}",
  "grade": "{grade}",
  "status": "complete | abort",
  "project": "{meta.project}",
  "stages_run": {meta.stages_run},
  "total_stages": {meta.total_stages},
  "duration_s": {meta.duration_s}
}
```
3. ファイルを Write で上書き保存

## Dry-run モード

dry-run の場合:
- ランディレクトリのプレフィックスを `DRYRUN-` にする
- prompt.md は記録する（Composer の出力確認用）
- response.md は記録しない（Dispatcher が呼ばれないため）
