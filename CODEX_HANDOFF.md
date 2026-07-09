# CODEX_HANDOFF — 遺物系統優化（2026-07-09）

## 目標
依 `docs/reference/STS_RELICS.md`（STS 全 180 件遺物參考表）優化 SwordCard 遺物系統。
總計畫與逐件規格：`docs/design/RELIC_DESIGN.md`。

## 目前階段
Development — Batch A 已完成入庫，Batch B 實作中。

## 已完成
- STS 遺物參考表＋差距分析（commit ff16824）
- **Batch A**（commit 63a5df0）：8 件純 catalog 遺物——4 件 common 專武（mu_jian / yuenv_jian / linjia_jiansui / baigu_nang，**置於各角色專武區塊末尾**，因 `run_state.gd:209` 開局送 `weapons_for_character()[0]`，換位會偷改起始武器）+ 3 件 common 通用（kaishan_fu / poyao_sha / tongqian_jian）+ 玉菩提珠（+1 靈力/回合、卡牌獎勵 -2 張）；main.gd 卡牌獎勵張數 clamp ≥1
- 11 件新遺物圖示需求已登記 `ART_TODO.md` §十六（`assets/art/relics/<id>.png`，有程序化 fallback 不阻擋）

## 進行中
- （無）Batch B 已完成並通過 fresh-context 驗收：3 件 run 層遺物（kezhan_yaopai 進商店回血 8 / qiankun_dai 每層 +8 金・商店消費後失效 / xingshen_cha 休息→下場戰鬥 +1 靈力），run_state 新欄位 floor_gold_dead / next_battle_energy_bonus（to_dict/from_dict 兩邊、init_for 重置），main.gd 與 ai_run_engine.gd 雙引擎接線。乾坤袋失效語意：**僅已持有時**消費才觸發，且買遺物路徑判定先於 add_relic（買乾坤袋那筆不會秒殺它）。醒神茶能量加成在 start_turn() 重設能量**之後**套用（main.gd:2344）——改開戰流程時勿移到前面

## 測試
`godot --headless --path . -s scripts/smoke_test.gd > _out.txt 2>&1`，檔尾須 `SwordCard smoke test passed.` 且無 `ERROR:` 行。Batch A 後已跑過：PASS，平衡 regression delta 0。

## 風險 / 未驗證
- 玉菩提珠強度（每回合 +1 靈力、rare 售價 130）恐 auto-buy——**待跑 AI 平衡驅動器**（`tools/ai_run.gd`）觀察，備案：改「前 3 回合 +1 靈力」或升 legendary 檔價
- 並行 session：另一 session 在改 `event_data.gd`/`docs/EVENT_BRANCHING.md`（未 commit，勿動）；背景任務在修 CLAUDE.md 遺物件數（本批 +11 件後其計數需再對）
- `relic_catalog.gd` 檔頭「71 件」註解過時（實際 Batch A 後 87、Batch B 後 90），由背景任務統一修

## 下一個最安全任務
Batch B 驗收（fresh-context verifier）→ commit → Batch C 工單（見 RELIC_DESIGN.md：Boss「+靈力+代價」神器系、掉落稀有度權重 45/30/20/5、條件式遺物池）
