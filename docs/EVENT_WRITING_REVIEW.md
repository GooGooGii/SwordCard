# 奇遇事件編劇審查報告（2026-07-08）

> 審查範圍：`scripts/event_data.gd` 全部 32 個事件（含 tree 分支版與舊制扁平版兩套文本）。
> 方法：4 個並行編劇 agent 分段細讀，主對話交叉驗證旗標鏈與正史引用（對照 `docs/PAL1_CANON.md`）。
> 評分 10 分制，以 tree 版為主體。全池均分約 **8.0**——高於一般 roguelike 事件文本水準。

## 修正狀態（2026-07-09，commit `dae585d`）

本報告列出的問題已於次日全面修正，行號已漂移、評語反映的是修正前狀態：

- **P0-1 正史錯誤** ✅：唐鈺×阿奴改回青梅竹馬（＋阿奴專屬分支）；揚州→蘇州（＋node_chase 官銀揭曉）。
- **P0-2 孤兒旗標** ✅：六旗標全數接上消費（fox_slain→鬼林狐群尋仇、healer_grudge→藥廬放簾、
  yamen_grudge→酒館畫影、thief_backer_grudge→富戶打手、waner_clue→拜月壇血指路收束、
  yao_freed→妖女壇前報恩並點破鎖鏈出處）。花妖「更深的東西」以文字落地為拜月教邪息。
- **P1-1 期望值失衡** ✅：靜立/跪受/敬香布包/抹囑/血祭/血契/一日之師七處修平。
- **P1-2 靈兒 flavor 凝視視角** ✅：七處改寫為血脈感知視角（煉丹爐補「以己為祭」暗韻、醉劍仙改「仙靈島的氣味」）。
- **P2-1 自創聲明** ✅：jianling_whisper（定位為專案原創劍靈、與龍葵切割）、jiang_waner_grief 補註解。
- **P2-2 flavor-tree 脫節** ✅：補 20+ 條角色變體/專屬分支（詳見 commit）；並依使用者要求完成全池
  「角色邏輯體檢」——劍/酒選項鎖 `requires.character`，靈兒（仙術）/阿奴（蠱/巫醫/飛刀）給等價變體。
- 文件過時 ✅：EVENT_BRANCHING.md 更新為 32/32；spring 頂部註解修正。
- battlefield root 選項過載 ✅：9→7（blade_communion 移除、搦鬼戰移入「未竟」節點，`f6ca917`）。
- 未處理：雙軌文本冗餘（舊扁平 schema 移除與否）留待後續決策。
- 新規範：**設 flag 必須有消費點，否則不設**（本次已全池達成，新增事件時遵守）。

## 一、逐事件評分總表

| 事件 | 分數 | 一句話評語 |
|---|---|---|
| caiyi_butterfly 蝶戀 | 9 | 全檔情感巔峰；siphon「奪道行反而完成她心願」是編劇級選項（:4880） |
| spirit_clan_ruins 靈族遺跡 | 9 | 「你來，是為了記得，還是為了取走？」一句立起全事件道德軸（:2208） |
| yokai_pact 妖契 | 9 | 敘事深度最高；但斬鏈救她後無下落無 flag，情感線斷尾（:1305） |
| ghost_forest 鬼林迷霧 | 9 | 系統設計最佳；fox_spared 跨事件回報是全池模範（:1974） |
| tavern_acquaintance 酒館舊識 | 9 | 跨事件敘事樞紐（狐妖報恩＋marked_by_bandits 種鉤）；tree 版獨缺阿奴 |
| sword_tomb 劍冢英靈 | 9 | 結構最深（試煉戰→承志三層）；「自知不配退開」還給獎勵是價值觀高光（:2792） |
| shilipo_sword_god 十里坡劍神 | 9 | 迷因用得端正，蜂王梗踩點；「陪練到天亮」是共感式 punish 好例 |
| drunk_swordsman 醉臥劍仙 | 9 | 正史含金量最高；「老子等的就是你這張臉」（:3203） |
| broken_temple 廢棄山神廟 | 8.5 | 最佳懸念反轉；但 node_recent 看穿危險卻不能撤退（:1121） |
| spring 幽泉清聲 | 8.5 | 第一批標竿；跨事件伏擊（marked_by_bandits）唯一完整消費端 |
| xianling_shrine 仙靈島水月宮 | 8.5 | 正史錨點最準；三角 flavor 寫了但 tree 無對應分支 |
| shushan_vault 蜀山秘府 | 8.5 | rare 事件規格立住；「離開」首次成為主題性正解（:5204） |
| moonlit_pool 月光浸水潭 | 8 | 雙月意象佳；zhao_lineage 三合一無代價 |
| talisman_cache 符匣殘光 | 8 | 主題執行一致；但 erase_warning 是優勢解，「貪者反噬」數值上是空話（:297） |
| ancestor_relic 先靈遺骨 | 8 | 乾花意象教科書級；阿奴禁忌 flavor 鋪好卻無機制出口（:614/:664） |
| wandering_sage 雲遊隱士 | 8 | demand_destiny 是「代價設計」正確示範；apprentice 三獎疊太滿 |
| immortal_ruins 仙人遺址 | 8 | 「還沒停下的修行」意象佳；跪受傳承獎勵疊滿反成優勢解（:2073） |
| baiyue_altar 拜月教壇 | 8 | 人形缺口是最佳恐怖筆觸（:2486）；「舊祭血瞞天過海」零代價 |
| miao_healer 苗疆藥師 | 8 | 條件檢查最嚴謹；但零衝突，功能上是掛皮補給站 |
| yinlong_cave 隱龍窟幽怨 | 8 | 道德三軸乾淨；fox_slain 種了無報應，道德不對稱 |
| aqi_reunion 阿七的笛聲 | 8 | 自創聲明規範（:4339）；阿奴哭戲重量夠；全無 downside |
| bijian_zhaoqin 比武招親 | 8 | 雙主角視角巧；月如自己視角下 leave 文案出戲（:4711） |
| jiang_waner_grief 婉兒之死 | 8 | 反類型死亡誠實有力；leave_silent 扣 power 制度性懲罰冷漠（:5000）；缺自創聲明 |
| shrine 山路異光 | 7.5 | 離場句佳；stand_quietly 零風險雙獎勵碾壓其他選項（:338） |
| treasure_chest 寶箱機關 | 7.5 | 全池最淺（純資源交換）；阿奴骨針解毒是角色選項標竿（:548） |
| alchemy_furnace 煉丹爐火 | 7.5 | 「以己為材」恐怖底色佳；靈兒 flavor 與主題完全脫節（:1692） |
| flower_spirit 花妖魅影 | 7.5 | node_pity 是小事件難得的道德分支；「更深的東西」伏筆拋了沒接（:4061） |
| tangyu_sparring 石壁前的少年 | 7.5 | punish 文案全檔典範（:4552）；**唐鈺×阿奴青梅竹馬寫反是最大正史錯誤**（:4453） |
| forgotten_altar 棄祭壇 | 7 | 「歸來食一碗熱飯」全批最佳單句（:1491）；好人選項數值全面佔優 |
| ancient_battlefield 古戰場遺跡 | 7 | 「未竟」斷劍好；root 8 選項過載、3 個 reward 同構 |
| lingmiao 靈廟顯靈 | 7 | 「替流淚的人補一炷香」佳；血祭期望值壓過靜坐 |
| yangzhou_officer 揚州府緝盜 | 7 | 官差人物立得好；**揚州不在 PAL1 地圖**，改「蘇州」一字即歸隊（:3444） |
| flower_thief 採花賊當道 | 6 | 三女角 flavor 是亮點；thief_backer_grudge 是死伏筆（:4132） |
| jianling_whisper 劍靈低語 | 6.5 | 文筆全段最柔；但劍靈身分無正史依據、強烈龍葵（仙劍三）既視感、缺自創聲明（:4222） |

## 二、優點（值得保持的六件事）

1. **log 文案的「動作＋餘韻」雙拍結構**成為全池統一筆法（「潭水還是滿的」「往後都是」「山野有靈，這筆債記下了」），離場句尤其講究——leave 不是放棄按鈕而是有尊嚴的選擇。
2. **punish 選項全部用敘事成本包裝**（愧疚、酒癮、被注視、「水面再不映你的影子」），沒有一個是裸數值稅；「節制/知進退獲獎勵」（sword_tomb 退開、drunk_swordsman 引酒緩行、shushan_vault 不貪）形成一貫的道德語言。
3. **角色專屬選項多數貼人設且錨定正史**：酒劍仙師承、林天南家訓、靈族古文、苗疆巫醫骨針；阿奴普遍寫成「巫醫/通妖/務實」而非窄化純毒師，正確執行了 CLAUDE.md 的叮囑。
4. **跨事件記憶已有兩條成功鏈**：`fox_spared`（隱龍窟放狐→酒館報恩）與 `marked_by_bandits`（酒館打聽失敗→幽泉遇伏），證明系統與筆法都能支撐 run 級敘事。
5. **條件選項有情境智慧**：`hp_below` 絕境賭命、`deck_archetype` 毒流通妖、`min_deck_size`/`has_potion_slot` 防呆——事件會回應玩家狀態。
6. **情感事件達到「選項=人格測驗」水準**：蝶戀、婉兒之死、阿七的笛聲的選項數值差異小、人格差異大，是正確的情感事件節制。

## 三、缺點（六個系統性問題，按傷害排序）

### P0-1 正史單點錯誤：唐鈺×阿奴關係寫反
`PAL1_CANON.md:30` 明載唐鈺與阿奴**青梅竹馬**（大理城），但 tangyu_sparring 的 anu flavor（`event_data.gd:4453`）把兩人寫成初見陌生人。這是把正史最現成的情感金礦（比翼鳥 CP）白白扔掉，且是「寫錯」而非「沒寫」。
另一處：yangzhou_officer 的「揚州」不在 PAL1 地圖（canon 地點為餘杭/蘇州/苗疆線），改「蘇州府緝盜」一字歸隊。

### P0-2 孤兒旗標（惡行無痕）
已 grep 全檔確認：`fox_slain`（:3355）、`healer_grudge`（:2963）、`yamen_grudge`（:3529）、`thief_backer_grudge`（:4131）四個旗標**只有 set 沒有任何 requires 消費**。現況是「善有善報（fox_spared 報恩）、惡無惡報」——道德天平系統性偏向作惡無後果，直接削弱支柱 3。同類死伏筆：flower_spirit「更深的東西」（:4061）、婉兒血指北方（:5057）、yokai_pact 斬鏈救人無下落（:1305）。

### P1-1 「美德全佔優」破壞取捨（支柱 3）
多處好人選項數值上也全面碾壓：forgotten_altar 敬香（:1385）、shrine 靜立（:338）、immortal_ruins 跪受（:2073）、baiyue_altar 舊祭血（:2510）。當「貪者反噬」的警告沒有數值後盾、褻瀆選項既缺德又虧本，道德選擇就退化成美德測驗。正確示範已在池內：wandering_sage 的 demand_destiny（真代價）、moonlit_pool 的 dive（獎勵伴隨 -max_hp）。
反向同病：兩處 gamble 期望值過高——lingmiao 血祭（:3690）壓過靜坐、shushan_vault lowhp_blood_pact lose 太輕（:5197）近乎白撿。

### P1-2 趙靈兒 flavor 套路化（「被凝視」而非「感知」）
spring:15 / talisman:198 / shrine:319 / sage:726 / moonlit:888 / alchemy:1692 至少六處走「出浴/衣衫/臉紅/肢體被輕觸」的凝視視角。其他三角的 flavor 在刻畫性格與師承，她在被鏡頭看。她是女媧後裔、五靈感知者——flavor 該寫她「認出」了什麼（靈痕、血脈、以己為祭的哀憫），而不是她的身體。alchemy_furnace 尤其可惜：前人以己為材煉丹，正是她終局命運的免費暗韻，現在的解衣散熱文案完全錯過。

### P2-1 自創內容聲明不一致
aqi_reunion 有規範的自創聲明註解（:4339–4341），但 jianling_whisper（劍靈身分無正史依據、強烈仙劍三龍葵既視感）與 jiang_waner_grief（婉兒非 PAL1 人物）都沒有。CLAUDE.md 允許自創但要求風格一致——聲明註解是防止未來 session 誤當正史的護欄。

### P2-2 雙軌文本冗餘與 flavor-tree 脫節
每事件同時保留舊扁平 outcomes 與 tree log，大量近義重複（immortal_ruins、baiyue_altar、lingmiao 最明顯），且部分兩版語義不一致（sword_tomb 舊制「直接拔劍」vs tree 版「須先證明才配取劍」:2713；shilipo 兩版獎勵池不同）。另外多個事件 character_flavors 寫了四角、tree 卻只給部分角色分支（xianling 月如、flower_spirit 三角、tavern 阿奴、yokai_pact 月如）。角色專屬選項分佈也不均（第一批 lin×2 / anu×1，而阿奴的 ancestor_relic 禁忌 flavor 鋪好了卻把機制出口給月如 :664）。

## 四、改善方案（依投報率排序）

### 第一波：單點修正（一次 session 可完成）
1. **重寫 tangyu_sparring 阿奴線**（:4453）：改為青梅竹馬重逢戲（參考 aqi_reunion 的克制筆法），並考慮給阿奴一條專屬分支（她認出這柄「有人留給他的劍」）。
2. **yangzhou_officer 改名蘇州府緝盜**（:3444–3448），順手在 node_chase 補一句揭曉（包袱是官銀/血的來歷），收掉開了不收的鉤。
3. **補自創聲明註解**：jianling_whisper（並定位劍靈身分——建議綁酒劍仙劍中舊靈，避開龍葵既視感）、jiang_waner_grief 兩處，照 aqi_reunion:4339 格式。
4. **drunk_swordsman 靈兒 flavor**（:3121）：「好看」改成半醉喃喃「仙靈島的氣味……」——輕浮換成身世伏筆。
5. **alchemy_furnace 靈兒 flavor 重寫**（:1692）：以己為材的哀憫＋她自身命運的暗韻。

### 第二波：孤兒旗標統一收口（一個新事件解決四個死伏筆）
新增一個通用「仇家上門」事件（或掛進既有事件的條件分支）：`requires` 任一負面旗標（fox_slain / healer_grudge / yamen_grudge / thief_backer_grudge）觸發對應的報應變體——狐族尋仇、藥師的冷遇（商店價格+）、官府通緝、富戶殺手。設計原則寫進 EVENT_BRANCHING.md：**「設 flag 必須有消費點，否則不設。」**
加碼（低成本高回報）：yokai_pact 斬鏈勝利補妖女獲自由 log + `yao_freed` flag（可暗指拴她的是拜月教）；婉兒血指北方接拜月教壇一句 callback（「她的血指的路，你走到了」）。

### 第三波：期望值梯度修復（支柱 3）
- shrine stand_quietly（:338）降為單獎；immortal_ruins accept_legacy（:2073）砍一項效果讓闖陣期望值反超。
- forgotten_altar：把 take_bundle 即期報酬拉高，讓「褻瀆但暴利 vs 虔敬但清貧」成真取捨。
- talisman erase_warning（:297）加輕量真實代價，讓「貪者反噬」名副其實。
- lingmiao 血祭 win_chance 降至 0.45；shushan_vault lowhp_blood_pact lose 改 max_hp -2。
- 修完可跑 `_test_balance_regression` 確認無誤傷（事件效果不進戰鬥模擬，風險低）。

### 第四波：趙靈兒 flavor 批次改寫（6 處）
統一改寫方向：「感知力視角」——她認出靈痕/血脈/因果，鏡頭從身體移回出身。出浴梗留給仙靈島正史場景一次用足。這是品味題，建議產 3 案由使用者選定筆法後批次套用。

### 維護附註
- `docs/EVENT_BRANCHING.md` 的「22/32 已轉 tree」已過時——實際全部 32 事件都有 tree 欄位；spring 頂部註解「UI 接 tree 走訪在 P2」（event_data.gd:28–32）也已過時，宜同步更新。
- 舊扁平 schema 若已不會觸發，建議規劃移除（雙軌文本是持續的維護稅）；若仍是 fallback，至少把語義矛盾的兩處（sword_tomb、shilipo）對齊。
