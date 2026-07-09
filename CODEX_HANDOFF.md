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

## AI 平衡 run 觀察（2026-07-09，li_xiaoyao / seed 20260709 / focus / A0）
- 4 幕全通、李逍遙無險（末段滿血輾壓）。**新遺物「有用但不破格」，未讓 run 失衡。**
- 遇到 4/11 件（客棧腰牌進商店 +8HP、烈火令、銅錢劍、+既有），皆如預期生效；乾坤袋/醒神茶/木劍/破妖砂等本 seed 未出現。
- **玉菩提珠整趟未遇到**（4 商店 4 boss 池都沒滾到 rare 通用），auto-buy 疑慮**仍未實測結論**。
- **真正裂縫是 gold 通膨**（4 幕後剩近 3000 金、買滿仍有餘）——pre-existing，見 `docs/BALANCE_REPORT.md` §六，非新遺物造成。

## 風險 / 未驗證
- 玉菩提珠強度未實測（有機 run 沒抽到）。分析上仍偏強：+1 靈力/回合是全遊戲僅 legendary 神器有的效果，rare 130 金＋僅 -2 卡獎（clamp≥1）代價恐偏低。**待使用者裁決**：跑定點對照（需小改 driver 加 grant-relic env）或直接套備案（前 3 回合 +1 靈力／升 legendary 檔價）
- 並行 session：另一 session 在改 `event_data.gd`/`docs/EVENT_BRANCHING.md`（未 commit，勿動）；背景任務在修 CLAUDE.md 遺物件數（本批 +11 件後其計數需再對）
- `relic_catalog.gd` 檔頭「71 件」註解過時（實際 Batch A 後 87、Batch B 後 90），由背景任務統一修

## Batch C（2026-07-09 完成，fresh-context 驗收 10/10 PASS）
- **C1 Boss 池神器 ×3**（忘憂散/朱漆酒葫蘆/聖靈珠，legendary、boss_id 空）：每回合 +1 靈力＋run 層代價（禁休息回血/戰鬥治療-2/商店+30）。Boss 三選一新組成：專屬神器→Boss 池補位→generals。附帶修掉既有隱患：heal_bonus 負值原本會讓治療變扣血，已在 effect_resolver/battle_controller 補 `maxi(0,...)`、card_format 預覽同步
- **C2 稀有度權重**：掉落與商店改 45/30/20/5 權重抽（`RelicCatalog.weighted_pick`，對 pool 內實際存在稀有度歸一化），不再均勻抽
- **C3 條件式遺物池**：`RelicData.pool_requires`＋`RelicCatalog.pool_eligible(relic, deck)`；攝魂蠱鈴(毒卡≥4)/逍遙令(0費≥3)/業火爐(消耗≥2) 只在牌組符合時進掉落/商店池；Boss 三選一與事件不過濾
- 待辦：C2 上線後找機會跑同 seed AI run 對照（前測基線＝2026-07-09 seed 20260709 4 幕全通）

## 美術後處理管線（2026-07-10 完成，端到端實測 PASS）
- **`tools/art_post.py`**：批次「去背（rembg isnet-anime）→ 4x 放大（Real-ESRGAN anime）→ 縮回 --max-size」，輸出 RGBA PNG。用法見檔頭 docstring；`--gpu 1` 指定 RTX 4050 給 ESRGAN
- 依賴（已裝於本機 Python 3.12）：`rembg[gpu,cli]` + `onnxruntime-gpu==1.22.0` + `nvidia-{cublas,cudnn,cufft,cuda-runtime}-cu12`（cu13 無 Windows wheel，勿升）；`tools/bin/realesrgan/`（gitignored，下載連結見腳本 docstring）
- 坑：cudnn 子庫走 PATH 搜尋，腳本已自動把 site-packages `nvidia/cudnn/bin` 前置進 PATH；沒裝 GPU wheels 會安靜回退 CPU（功能不變）
- 實測：白底遺物圖 → 透明背景 1024×1024，去背 GPU 0.46s/張，整批單張 ≈ 數秒
- 調研結論（工具選型）：次優先為 MIT 特效庫（GODOT-VFX-LIBRARY / godotshaders.com）強化出牌特效；ComfyUI+水墨 LoRA 第三；Spine/DragonBones 不採

## 幕間難度縮放（2026-07-09/10，commit 9eb93c7，同 seed 驗證完成）
- 反曲線修正：幕 3 起敵 HP +12%/幕、傷害 +5%/幕（`BattleController.ACT_HP_STEP`/`ACT_DMG_STEP`）；前兩幕不動；召喚/接續 boss 也套；意圖預測補齊 strength×mult（修 A2+ 預測偏低既有 bug）
- 同 seed 333 對照（agent 親玩 8 幕通關）：幕 3 boss 1回合0傷→2回合18傷 ✓、phase-2 boss 全數 2+ 回合有實傷 ✓、受傷中位數 0→3.5、無牆。詳見 BALANCE_REPORT §十
- **殘餘缺口**：幕 4 赤鬼王 / 幕 6 鎮獄明王（單階段 boss）仍被最佳化爆發 1 回合斬。**不要用加 HP 解**（違反既有爆發獎勵決策）；正解＝給這兩隻補 phase 2（phase-2 boss 天然免疫一回合斬，已驗證）。赤鬼王概念圖已有（ART_TODO §6C）

## 下一個最安全任務
幕 4/6 單階段 boss 補 phase 2（赤鬼王/鎮獄明王，數據驅動的內容工單）；或收斂 gold 通膨（BALANCE_REPORT §六，獨立輪）
