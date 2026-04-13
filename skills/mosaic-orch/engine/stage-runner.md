# Stage Runner — mosaic-orch (L3)

1 Stage の実行を担当する。Orchestrator(L2) から呼ばれる。

## あなたの責務

Stage 定義を受け取り、(1) Facet 合成 → (2) 入力注入 → (3) サブエージェント起動 → (4) 契約検証
のパイプラインを実行して結果を返す。
**Workflow 全体は知らない。** 次の Stage も前の Stage も関知しない。

## 事前読み込み

以下を **Read tool で読み込む**:
1. `engine/composer.md` — Facet 合成
2. `engine/dispatcher.md` — サブエージェント起動
3. `engine/contracts.md` — Output Contract 検証
4. `engine/facet-loader.md` — Facet 解決（composer.md が使う）

## 入力

- `stage`: Stage 定義オブジェクト（YAML の 1 stage 分）
- `input`: 変数展開済みの入力テキスト（Orchestrator が展開済み）
- `permission`: 権限モード
- `timeout`: タイムアウト秒
- `dryRun`: boolean
- `runDir`: ランディレクトリパス（run-recorder 用）

## Kind 別の実行フロー

### 共通前処理: Facet 変数展開

全 kind 共通で、Composer にfacetsを渡す前に variable-resolver で `${...}` を展開する。

```
0. stage.facets 内の全文字列値を variable-resolver で展開する:
   - persona: ${subtask.persona} → "backend-lead"
   - instructions: [${subtask.instruction}] → ["implement-backend"]
   - policies, knowledge, rubrics も同様
   展開後の facets を以降の Step 1 で Composer に渡す。
   VariableUnresolved → StageFailure（facet名の展開失敗）
```

### kind: task

```
1. Composer に stage.facets を渡してプロンプトを合成する
   → { systemPrompt, userMessage, sourceFiles }

1.5. stage.skills がある場合、userMessage の末尾に以下を追記する:

   ---
   ## スキル活用（必須）

   以下のスキルが利用可能です。作業中に該当する場面で **Skill tool** を使って起動してください:
   {skills リストから各スキル名を箇条書きで列挙}

   スキルの内容は事前に読み込まず、必要になった時点で Skill tool で起動してください。

2. userMessage の末尾に入力を追記する:
   ---
   ## Input
   {input}

3. run-recorder.recordStage(runDir, stage.id, { prompt: userMessage })

4. Dispatcher に単発実行を依頼する:
   → agentOutput (文字列)

5. run-recorder.recordStage(runDir, stage.id, { response: agentOutput })

6. output_contract がある場合:
   a. contracts.md の手順で検証する
   b. 成功 → extracted を返す
   c. ContractViolation →
      - リトライカウント < 2 なら同じプロンプトで再度 Step 4 から
      - リトライカウント >= 2 なら StageFailure エラー

7. output_contract がない場合:
   agentOutput をそのまま返す
```

### kind: fan_out

```
1. stage.from を input から取得する（配列であること）
   配列でなければ SchemaError

2. 配列の各要素 element に対して:
   a. fan_out の as 変数に element をバインド
   b. Composer に stage.facets を渡してプロンプトを合成する
   b2. stage.skills がある場合、userMessage の末尾に以下を追記する:

      ---
      ## スキル活用（必須）

      以下のスキルが利用可能です。作業中に該当する場面で **Skill tool** を使って起動してください:
      {skills リストから各スキル名を箇条書きで列挙}

      スキルの内容は事前に読み込まず、必要になった時点で Skill tool で起動してください。

   c. userMessage の末尾に入力を追記する:
      ---
      ## Input
      {element の内容}
   d. run-recorder.recordStage(runDir, "{stage.id}-{index}", { prompt: userMessage })

3. 全プロンプトを Dispatcher に並列実行で渡す:
   → outputs[] (文字列の配列)

4. 各 output に対して:
   a. run-recorder.recordStage(runDir, "{stage.id}-{index}", { response: output })
   b. output_contract がある場合は検証する

5. エラー処理:
   - on_error == "fail" (デフォルト): 1つでも失敗 → StageFailure
   - on_error == "continue": 成功分のみ配列に含めて返す

6. 全結果を配列として返す → ${stage.id}.outputs で参照可能
```

### kind: fan_in

```
1. stage.from を input から取得する（配列であること）

2. 配列を整形して userMessage に "## 統合対象" として追記する:
   各要素に見出しを付与:

   ## 統合対象

   ### Item 1
   {outputs[0] の内容}

   ### Item 2
   {outputs[1] の内容}

   ...

3. Composer に stage.facets を渡してプロンプトを合成する

4. userMessage の末尾に整形済み統合対象を追記する

5. 以降は kind: task の Step 3〜7 と同じ
```

## loop_until 処理

**task kind のみ対応。** fan_out / fan_in で loop_until があれば SchemaError。

```
iteration = 1
loop:
  1. 上記 kind: task の Step 1〜7 を実行する
  2. output_contract の extracted から self 変数にバインドする
     例: extracted = { grade: "B" } → self.grade = "B"
  3. stage.loop_until の条件を評価する:
     a. 変数展開（self.X を実値に置換）
     b. 比較演算を実行:
        - 文字列比較: `<`, `>`, `>=`, `<=`, `==`, `!=`
        - 順序: S > A+ > A > B > C（成績型の場合）
     c. true → ループ終了、最新の output を返す
     d. false → iteration += 1

  4. iteration > max_iterations の場合:
     最新の output を返すが、フラグ loop_exhausted=true を付与する

end loop
```

## 比較演算の詳細

`when` / `loop_until` の条件式は以下の形式のみ対応:

```
${variable} operator 'value'
```

operator: `<`, `>`, `>=`, `<=`, `==`, `!=`

文字列の大小比較は以下の成績順序を使う:
`S > A+ > A > B > C`

例: `${review.output.grade} < 'A'` は grade が B または C のとき true。
