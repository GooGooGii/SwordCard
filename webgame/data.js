// SwordCard Web — 資料層（移植自 scripts/game_data.gd，act 1 餘杭篇）
// 卡片：{id, n:名, o:角色, c:費用, t:attack|skill|power, r:basic|uncommon|rare, fx:[...], ex:exhaust}
"use strict";

const CARDS = {};
function C(id, n, o, c, t, r, fx, ex) { CARDS[id] = { id, n, o, c, t, r, fx, ex: !!ex }; }

// ── 李逍遙 ──
C("lxy_yujian", "御劍術", "li", 1, "attack", "basic", [{ k: "damage", a: 7 }]);
C("lxy_wanjian", "萬劍訣", "li", 2, "attack", "uncommon", [{ k: "damage_all", a: 5, hits: 3 }]);
C("lxy_feilong", "飛龍探雲手", "li", 1, "skill", "basic", [{ k: "damage", a: 4 }, { k: "draw", a: 1 }, { k: "energy", a: 1 }, { k: "steal", a: 8 }]);
C("lxy_tianshi", "天師符法", "li", 1, "attack", "uncommon", [{ k: "damage_all", a: 9 }]);
C("lxy_jiushen", "酒神咒", "li", 3, "attack", "rare", [{ k: "damage", a: 28 }, { k: "self_damage", a: 8 }]);
C("lxy_xianfeng", "仙風雲體", "li", 1, "skill", "uncommon", [{ k: "block", a: 8 }, { k: "draw", a: 1 }]);
C("lxy_zuimeng", "醉夢望月", "li", 2, "power", "uncommon", [{ k: "power", a: 2 }]);
C("lxy_jianqi", "劍氣成牆", "li", 1, "skill", "basic", [{ k: "block", a: 8 }]);
C("lxy_linghuo", "靈火符", "li", 1, "attack", "uncommon", [{ k: "damage", a: 6 }, { k: "vulnerable", a: 1 }]);
C("lxy_xiaoyao_you", "逍遙遊", "li", 0, "skill", "rare", [{ k: "draw", a: 1 }, { k: "energy", a: 1 }]);
C("lxy_liepo", "裂魄斬", "li", 1, "attack", "uncommon", [{ k: "damage", a: 10 }, { k: "weak", a: 1 }]);
C("lxy_qingfeng", "清風御劍", "li", 1, "skill", "uncommon", [{ k: "block", a: 5 }, { k: "draw", a: 2 }]);
C("lxy_jiulong", "九龍訣", "li", 3, "attack", "rare", [{ k: "damage", a: 12, hits: 3 }]);
C("lxy_zuilong", "醉龍翻江", "li", 2, "attack", "rare", [{ k: "damage", a: 18 }, { k: "self_damage", a: 5 }, { k: "draw", a: 1 }]);
C("lxy_qiliao", "氣療術", "li", 1, "skill", "basic", [{ k: "heal", a: 6 }]);
C("lxy_bingxin", "冰心訣", "li", 1, "skill", "basic", [{ k: "cure_debuff" }, { k: "block", a: 3 }]);
C("lxy_wanjianguizong", "萬劍歸宗", "li", 1, "attack", "uncommon", [{ k: "damage_all", a: 4, hits: 3 }]);
C("lxy_jianshen", "人劍合一", "li", 2, "power", "rare", [{ k: "power", a: 2 }, { k: "block", a: 6 }]);
C("lxy_tiangangqi", "天罡氣", "li", 1, "skill", "uncommon", [{ k: "block", a: 9 }, { k: "draw", a: 1 }]);
C("lxy_tianjian", "天劍出鞘", "li", 2, "attack", "rare", [{ k: "damage_all", a: 20 }]);
C("lxy_xiaoyao_shenjian", "逍遙神劍", "li", 3, "attack", "rare", [{ k: "damage", a: 10, hits: 2 }, { k: "draw", a: 2 }]);
C("lxy_zhenyuan", "真元凝聚", "li", 1, "skill", "uncommon", [{ k: "draw", a: 2 }, { k: "heal", a: 4 }]);
C("lxy_jianjue", "信手一劍", "li", 0, "attack", "basic", [{ k: "damage", a: 4 }]);
C("lxy_huijian", "乘風引氣", "li", 0, "attack", "uncommon", [{ k: "damage", a: 3 }, { k: "draw", a: 1 }]);
C("lxy_yufengbu", "御風步", "li", 0, "skill", "basic", [{ k: "block", a: 4 }]);
C("lxy_xujian", "蓄劍式", "li", 1, "skill", "uncommon", [{ k: "next_attack_mult", a: 2 }]);
C("lxy_jianyi", "靈犀訣", "li", 2, "power", "rare", [{ k: "power_per_turn", a: 1 }]);
C("lxy_qingyan_zhuying", "青煙竹影", "li", 2, "attack", "uncommon", [{ k: "damage", a: 4, hits: 4 }]);
C("lxy_yujianxinjue", "御劍心訣", "li", 1, "power", "rare", [{ k: "draw_on_attack", a: 1 }]);

// ── 趙靈兒 ──
C("zl_guanyin", "觀音咒", "zhao", 1, "skill", "basic", [{ k: "heal", a: 6 }]);
C("zl_wuqi", "五氣朝元", "zhao", 2, "skill", "uncommon", [{ k: "heal", a: 7 }, { k: "block", a: 6 }]);
C("zl_xuanbing", "玄冰咒", "zhao", 1, "attack", "uncommon", [{ k: "damage_all", a: 6 }, { k: "weak_all", a: 2 }]);
C("zl_leizhou", "雷咒", "zhao", 1, "attack", "basic", [{ k: "damage", a: 10 }]);
C("zl_mengshe", "夢蛇靈印", "zhao", 2, "power", "rare", [{ k: "power", a: 2 }, { k: "heal", a: 4 }, { k: "draw", a: 1 }]);
C("zl_fengling", "風靈符", "zhao", 0, "skill", "uncommon", [{ k: "draw", a: 1 }]);
C("zl_tianlei", "天雷破", "zhao", 2, "attack", "uncommon", [{ k: "damage", a: 18 }]);
C("zl_lingguang", "靈光護體", "zhao", 1, "skill", "basic", [{ k: "block", a: 8 }]);
C("zl_huanyu", "幻雨咒", "zhao", 1, "skill", "uncommon", [{ k: "block", a: 7 }, { k: "weak", a: 1 }]);
C("zl_nvwa", "女媧靈息", "zhao", 2, "power", "rare", [{ k: "heal", a: 6 }, { k: "power", a: 2 }]);
C("zl_shuiling", "水靈封印", "zhao", 2, "attack", "uncommon", [{ k: "damage_debuff_bonus", a: 5, per: 3 }]);
C("zl_leiguang", "紫電連珠", "zhao", 1, "attack", "basic", [{ k: "damage", a: 4, hits: 2 }, { k: "weak", a: 1 }]);
C("zl_lingxi", "靈息吐納", "zhao", 1, "skill", "uncommon", [{ k: "draw", a: 2 }, { k: "heal", a: 4 }]);
C("zl_shenlei", "神雷降世", "zhao", 3, "attack", "rare", [{ k: "damage", a: 20 }, { k: "stun", a: 1, chance: 0.6 }]);
C("zl_jingang", "金剛咒", "zhao", 1, "skill", "basic", [{ k: "block", a: 8 }]);
C("zl_bingzhou", "冰咒", "zhao", 1, "attack", "basic", [{ k: "damage", a: 6 }, { k: "weak", a: 1 }]);
C("zl_yanzhou", "炎咒", "zhao", 1, "attack", "basic", [{ k: "damage", a: 8 }, { k: "vulnerable", a: 1 }]);
C("zl_bingxin", "冰心訣", "zhao", 1, "skill", "basic", [{ k: "cure_debuff" }, { k: "block", a: 3 }]);
C("zl_ganlin", "甘霖咒", "zhao", 1, "skill", "uncommon", [{ k: "heal", a: 6 }, { k: "block", a: 6 }]);
C("zl_diliebeng", "地裂崩", "zhao", 3, "attack", "rare", [{ k: "damage_all", a: 15 }]);
C("zl_fengxuebing", "風雪冰天", "zhao", 1, "attack", "uncommon", [{ k: "damage_all", a: 8 }, { k: "weak_all", a: 2 }]);
C("zl_kuanglei", "狂雷破", "zhao", 2, "attack", "rare", [{ k: "damage_all", a: 11, hits: 2 }]);
C("zl_sanmeizhenhuo", "三昧真火", "zhao", 2, "attack", "rare", [{ k: "damage_all", a: 10 }, { k: "vulnerable_all", a: 2 }]);
C("zl_wuleizhou", "五雷咒", "zhao", 3, "attack", "rare", [{ k: "damage_all", a: 6, hits: 5 }]);
C("zl_xuanfengzhou", "旋風咒", "zhao", 1, "skill", "uncommon", [{ k: "block", a: 10 }, { k: "weak_all", a: 1 }]);
C("zl_xiaoleizhou", "小雷咒", "zhao", 0, "attack", "basic", [{ k: "damage", a: 4 }]);
C("zl_yinlingfu", "引靈符", "zhao", 0, "skill", "uncommon", [{ k: "draw", a: 1 }, { k: "block", a: 2 }]);
C("zl_huguangzhou", "琉璃護光", "zhao", 0, "skill", "basic", [{ k: "block", a: 4 }]);
C("zl_lianzhuzhou", "連珠雷咒", "zhao", 1, "attack", "uncommon", [{ k: "damage", a: 5, hits: 2 }]);
C("zl_juling", "聚靈訣", "zhao", 1, "skill", "uncommon", [{ k: "block_multiply", a: 2 }]);
C("zl_lingguangpuzhao", "靈光普照", "zhao", 1, "power", "uncommon", [{ k: "block_per_turn", a: 5 }]);
C("zl_wuleihongding", "五雷轟頂", "zhao", 2, "power", "rare", [{ k: "turn_damage_all", a: 6 }]);
C("zl_lingxijue", "靈息訣", "zhao", 1, "power", "rare", [{ k: "draw_on_skill", a: 1 }]);
C("zl_wanlingshi", "萬靈噬", "zhao", 2, "attack", "rare", [{ k: "damage_debuff_bonus_all", a: 6, per: 4 }]);

// ── 林月如 ──
C("lyr_qijianzhi", "氣劍指", "lin", 1, "attack", "basic", [{ k: "damage_all", a: 8 }]);
C("lyr_yiyang", "一陽指", "lin", 2, "attack", "uncommon", [{ k: "damage", a: 18 }]);
C("lyr_zhanlong", "斬龍訣", "lin", 3, "attack", "rare", [{ k: "damage_all", a: 30 }]);
C("lyr_qiankun", "乾坤一擲", "lin", 0, "attack", "rare", [{ k: "consume_energy_damage_all", a: 9 }]);
C("lyr_fanji", "回鋒劍", "lin", 1, "skill", "basic", [{ k: "block", a: 8 }, { k: "damage", a: 5 }]);
C("lyr_bianying", "劍影重重", "lin", 1, "attack", "basic", [{ k: "damage", a: 4, hits: 2 }, { k: "vulnerable", a: 1 }]);
C("lyr_shenfa", "月影身法", "lin", 1, "skill", "uncommon", [{ k: "block", a: 7 }, { k: "draw", a: 1 }]);
C("lyr_juesha", "索命一劍", "lin", 2, "attack", "uncommon", [{ k: "damage", a: 14 }, { k: "vulnerable", a: 2 }]);
C("lyr_lianhuan", "亂雲連斬", "lin", 1, "attack", "uncommon", [{ k: "damage", a: 3, hits: 3 }]);
C("lyr_jinchan", "四兩撥千斤", "lin", 1, "skill", "rare", [{ k: "block", a: 5 }, { k: "draw", a: 2 }]);
C("lyr_xuanjian", "旋劍花舞", "lin", 1, "attack", "basic", [{ k: "damage", a: 5, hits: 2 }]);
C("lyr_kuaijian", "流光快劍", "lin", 0, "attack", "uncommon", [{ k: "damage", a: 6 }]);
C("lyr_poqian", "破軍劍", "lin", 2, "attack", "uncommon", [{ k: "damage", a: 20 }, { k: "draw", a: 1 }]);
C("lyr_tianv", "飛花亂舞", "lin", 1, "attack", "uncommon", [{ k: "damage", a: 4 }, { k: "vulnerable", a: 1 }, { k: "draw", a: 1 }]);
C("lyr_tieyi", "鐵衣功", "lin", 2, "skill", "rare", [{ k: "block", a: 15 }]);
C("lyr_ningshen", "凝神歸元", "lin", 1, "skill", "basic", [{ k: "heal", a: 8 }]);
C("lyr_fenghuan", "鳳鳴反擊", "lin", 1, "power", "uncommon", [{ k: "thorns", a: 3 }]);
C("lyr_yuehua", "月華護體", "lin", 1, "skill", "uncommon", [{ k: "block", a: 6 }, { k: "thorns", a: 1 }]);
C("lyr_lielong", "烈龍衝擊", "lin", 3, "attack", "rare", [{ k: "damage", a: 24 }, { k: "stun", a: 1, chance: 0.6 }]);
C("lyr_qijuejianqi", "七訣劍氣", "lin", 1, "attack", "uncommon", [{ k: "damage_all", a: 9 }, { k: "vulnerable_all", a: 1 }, { k: "draw", a: 1 }]);
C("lyr_tongqianbiao", "銅錢鏢", "lin", 1, "attack", "uncommon", [{ k: "damage", a: 4, hits: 3 }]);
C("lyr_wanlikuang", "萬里狂沙", "lin", 2, "skill", "rare", [{ k: "vulnerable_all", a: 3 }, { k: "draw", a: 1 }]);
C("lyr_yuanlinggui", "元靈歸心術", "lin", 2, "skill", "uncommon", [{ k: "heal", a: 6 }, { k: "block", a: 12 }]);
C("lyr_jici", "驚鴻一點", "lin", 0, "attack", "basic", [{ k: "damage", a: 4 }]);
C("lyr_huaci", "拈花一劍", "lin", 0, "attack", "uncommon", [{ k: "damage", a: 3 }, { k: "draw", a: 1 }]);
C("lyr_qiebushan", "凌波微步", "lin", 0, "skill", "basic", [{ k: "block", a: 4 }]);
C("lyr_shuangjianci", "鴛鴦雙劍", "lin", 1, "attack", "uncommon", [{ k: "damage", a: 5, hits: 2 }]);
C("lyr_shuangren", "霜刃反擊", "lin", 1, "skill", "uncommon", [{ k: "thorns", a: 8 }]);
C("lyr_jianwu", "劍舞架式", "lin", 1, "power", "uncommon", [{ k: "block_per_attack", a: 3 }]);
C("lyr_tiegu", "鐵骨樁", "lin", 1, "power", "uncommon", [{ k: "self_block_bonus", a: 2 }]);
C("lyr_suohun", "索魂十三劍", "lin", 2, "attack", "uncommon", [{ k: "damage_debuff_bonus", a: 6, per: 3 }]);

// ── 阿奴 ──
C("anu_yufeng", "御蜂術", "anu", 1, "attack", "basic", [{ k: "damage_all", a: 3, hits: 3 }]);
C("anu_wanyi", "萬蟻蝕象", "anu", 1, "skill", "uncommon", [{ k: "poison_all", a: 4 }]);
C("anu_baozhagu", "毒卵迸裂", "anu", 2, "attack", "uncommon", [{ k: "poison_burst", a: 3 }]);
C("anu_lingxue", "靈血咒", "anu", 1, "skill", "basic", [{ k: "heal", a: 5 }, { k: "block", a: 3 }]);
C("anu_jiedu", "解毒咒", "anu", 1, "skill", "basic", [{ k: "cure_debuff" }, { k: "draw", a: 1 }]);
C("anu_guling", "金蠶結甲", "anu", 1, "skill", "uncommon", [{ k: "block", a: 9 }]);
C("anu_wangyou", "忘憂蠱", "anu", 2, "skill", "uncommon", [{ k: "poison", a: 4 }, { k: "vulnerable", a: 2 }]);
C("anu_duwu", "毒霧繚繞", "anu", 1, "skill", "uncommon", [{ k: "poison", a: 2 }, { k: "weak", a: 1 }]);
C("anu_guxue", "以血飼毒", "anu", 2, "power", "rare", [{ k: "power", a: 1 }, { k: "poison", a: 5 }]);
C("anu_baizu", "百足蠱", "anu", 2, "skill", "uncommon", [{ k: "poison", a: 8 }]);
C("anu_duzhen", "毒針連射", "anu", 1, "attack", "uncommon", [{ k: "damage", a: 5 }, { k: "poison", a: 2 }]);
C("anu_sanmao", "斑蝥噬心", "anu", 2, "skill", "uncommon", [{ k: "poison", a: 5 }, { k: "weak", a: 2 }]);
C("anu_gushen", "蠱神附體", "anu", 3, "power", "rare", [{ k: "power", a: 3 }, { k: "poison", a: 4 }]);
C("anu_cuifeng", "淬鋒蠱刃", "anu", 1, "power", "uncommon", [{ k: "power", a: 2 }]);
C("anu_wuyuezhan", "巫月斬", "anu", 1, "attack", "uncommon", [{ k: "damage", a: 5, hits: 2 }]);
C("anu_xuerenwu", "血刃亂舞", "anu", 2, "attack", "rare", [{ k: "damage", a: 4, hits: 3 }]);
C("anu_sanshigu", "三屍蠱", "anu", 2, "skill", "rare", [{ k: "poison", a: 10 }]);
C("anu_shuhun", "聖姑庇佑", "anu", 1, "power", "uncommon", [{ k: "power", a: 1 }, { k: "draw", a: 1 }]);
C("anu_wangushitian", "萬蠱噬天", "anu", 3, "skill", "rare", [{ k: "poison", a: 12 }, { k: "weak", a: 3 }]);
C("anu_wanyi_ls", "萬蟻蝕骨", "anu", 1, "skill", "rare", [{ k: "poison", a: 8 }]);
C("anu_yanshazhou", "燃殺咒", "anu", 2, "attack", "uncommon", [{ k: "damage", a: 14 }, { k: "poison", a: 3 }]);
C("anu_guzhang", "蠱瘴瀰漫", "anu", 1, "power", "uncommon", [{ k: "poison_engine", a: 3 }]);
C("anu_sandu", "散蠱", "anu", 0, "skill", "basic", [{ k: "poison", a: 2 }]);
C("anu_yindu", "引蠱", "anu", 0, "attack", "uncommon", [{ k: "damage", a: 3 }, { k: "draw", a: 1 }]);
C("anu_huguzhao", "逆影遁法", "anu", 0, "skill", "basic", [{ k: "block", a: 4 }]);
C("anu_lianduzhen", "攢針亂射", "anu", 1, "attack", "uncommon", [{ k: "damage", a: 3, hits: 2 }, { k: "poison", a: 1 }]);
C("anu_cuihua", "毒入膏肓", "anu", 1, "skill", "rare", [{ k: "poison_multiply", a: 2 }]);
C("anu_gudaocui", "五毒淬刃", "anu", 1, "power", "uncommon", [{ k: "poison_on_attack", a: 1 }]);
C("anu_minghe_yindu", "冥河引渡", "anu", 2, "attack", "rare", [{ k: "damage_all", a: 8 }, { k: "poison_all", a: 3 }]);
C("anu_suoming_egui", "幽魂噬影", "anu", 1, "attack", "uncommon", [{ k: "damage", a: 9 }, { k: "weak", a: 2 }]);
C("anu_youming_shigu", "幽冥蝕骨", "anu", 2, "skill", "uncommon", [{ k: "poison", a: 7 }, { k: "vulnerable", a: 2 }]);
C("anu_guihuo_liaoyuan", "鬼火燎原", "anu", 3, "attack", "rare", [{ k: "damage_all", a: 7, hits: 2 }, { k: "poison_all", a: 2 }]);
C("anu_huadie_guimeng", "化蝶歸夢", "anu", 1, "skill", "uncommon", [{ k: "weak_all", a: 2 }, { k: "draw", a: 1 }]);
C("anu_guxue_shixin", "蠱血噬心", "anu", 2, "attack", "rare", [{ k: "damage_poison_bonus", a: 6, per: 2 }]);

// ── 無門（共同牌）──
C("cl_xunjiezhan", "迅捷斬", "cl", 0, "attack", "uncommon", [{ k: "damage", a: 7 }]);
C("cl_hanfengjue", "寒鋒訣", "cl", 0, "attack", "uncommon", [{ k: "damage", a: 3 }, { k: "draw", a: 1 }]);
C("cl_hushenjue", "金鐘護體", "cl", 0, "skill", "uncommon", [{ k: "block", a: 6 }]);
C("cl_qiaojin", "借力卸勁", "cl", 0, "skill", "uncommon", [{ k: "block", a: 2 }, { k: "draw", a: 1 }]);
C("cl_zhimingfu", "致盲符", "cl", 0, "skill", "uncommon", [{ k: "weak", a: 2 }]);
C("cl_poshi", "覷破空門", "cl", 0, "skill", "uncommon", [{ k: "vulnerable", a: 2 }]);
C("cl_jinchuangtie", "金創藥帖", "cl", 0, "skill", "uncommon", [{ k: "heal", a: 5 }], true);
C("cl_qimendunjia", "奇門遁甲", "cl", 0, "attack", "uncommon", [{ k: "damage_all", a: 8 }]);
C("cl_yunchou", "運籌帷幄", "cl", 0, "skill", "rare", [{ k: "draw", a: 3 }], true);

// ── 角色 ──
const CHARACTERS = {
  li: {
    id: "li", name: "李逍遙", hp: 74, style: "劍仙風流——御劍連擊、偷取與酒神系高風險高傷害。",
    passive: { kind: "first_attack_cost", label: "御劍隨心：每回合第一張攻擊牌費用 -1" },
    starter: ["lxy_yujian", "lxy_yujian", "lxy_yujian", "lxy_qiliao", "lxy_linghuo", "lxy_bingxin",
      "lxy_feilong", "lxy_jianqi", "lxy_jianqi", "lxy_wanjian", "lxy_xianfeng", "lxy_zuimeng"],
    pool: ["lxy_tianshi", "lxy_jiushen", "lxy_qingfeng", "lxy_jiulong", "lxy_zuilong", "lxy_liepo",
      "lxy_xiaoyao_you", "lxy_wanjianguizong", "lxy_jianshen", "lxy_tiangangqi", "lxy_tianjian",
      "lxy_xiaoyao_shenjian", "lxy_zhenyuan", "lxy_jianjue", "lxy_huijian", "lxy_yufengbu",
      "lxy_xujian", "lxy_jianyi", "lxy_qingyan_zhuying", "lxy_yujianxinjue"],
  },
  zhao: {
    id: "zhao", name: "趙靈兒", hp: 68, style: "五靈仙術——治療、護盾、群體削弱與長戰持續。",
    passive: { kind: "battle_start_power", a: 2, label: "靈台啟明：每場戰鬥開始攻擊提升 2" },
    starter: ["zl_leizhou", "zl_leizhou", "zl_leizhou", "zl_guanyin", "zl_guanyin", "zl_jingang",
      "zl_bingzhou", "zl_yanzhou", "zl_bingxin", "zl_wuqi", "zl_tianlei", "zl_huanyu"],
    pool: ["zl_xuanbing", "zl_mengshe", "zl_fengling", "zl_lingguang", "zl_nvwa", "zl_shuiling",
      "zl_leiguang", "zl_lingxi", "zl_shenlei", "zl_ganlin", "zl_diliebeng", "zl_fengxuebing",
      "zl_kuanglei", "zl_sanmeizhenhuo", "zl_wuleizhou", "zl_xuanfengzhou", "zl_xiaoleizhou",
      "zl_yinlingfu", "zl_huguangzhou", "zl_lianzhuzhou", "zl_juling", "zl_lingguangpuzhao",
      "zl_wuleihongding", "zl_lingxijue", "zl_wanlingshi"],
  },
  lin: {
    id: "lin", name: "林月如", hp: 72, style: "鞭劍武學——連擊、反擊荊棘與內勁治療。",
    passive: { kind: "first_block_counter", a: 4, label: "每回合第一次獲得護體時，反擊 4 點傷害" },
    starter: ["lyr_qijianzhi", "lyr_qijianzhi", "lyr_qijianzhi", "lyr_qijianzhi", "lyr_ningshen",
      "lyr_ningshen", "lyr_fanji", "lyr_fanji", "lyr_xuanjian", "lyr_xuanjian", "lyr_yiyang", "lyr_shenfa"],
    pool: ["lyr_zhanlong", "lyr_qiankun", "lyr_bianying", "lyr_juesha", "lyr_lianhuan", "lyr_jinchan",
      "lyr_kuaijian", "lyr_poqian", "lyr_tianv", "lyr_tieyi", "lyr_fenghuan", "lyr_yuehua",
      "lyr_lielong", "lyr_qijuejianqi", "lyr_tongqianbiao", "lyr_wanlikuang", "lyr_yuanlinggui",
      "lyr_jici", "lyr_huaci", "lyr_qiebushan", "lyr_shuangjianci", "lyr_shuangren", "lyr_jianwu",
      "lyr_tiegu", "lyr_suohun"],
  },
  anu: {
    id: "anu", name: "阿奴", hp: 82, style: "苗疆蠱毒——疊毒、引爆與長戰持續傷害。",
    passive: { kind: "battle_start_enemy_poison", a: 5, label: "下蠱：敵人每場戰鬥開場受到 5 層蠱毒" },
    starter: ["anu_yufeng", "anu_guzhang", "anu_duzhen", "anu_duzhen", "anu_baozhagu", "anu_wanyi",
      "anu_duwu", "anu_sandu", "anu_lingxue", "anu_lingxue", "anu_jiedu", "anu_guling"],
    pool: ["anu_wangyou", "anu_guxue", "anu_baizu", "anu_sanmao", "anu_gushen", "anu_cuifeng",
      "anu_wuyuezhan", "anu_xuerenwu", "anu_sanshigu", "anu_shuhun", "anu_wangushitian",
      "anu_wanyi_ls", "anu_yanshazhou", "anu_yindu", "anu_huguzhao", "anu_lianduzhen",
      "anu_cuihua", "anu_gudaocui", "anu_minghe_yindu", "anu_suoming_egui", "anu_youming_shigu",
      "anu_guihuo_liaoyuan", "anu_huadie_guimeng", "anu_guxue_shixin"],
  },
};

const COLORLESS_POOL = ["cl_xunjiezhan", "cl_hanfengjue", "cl_hushenjue", "cl_qiaojin",
  "cl_zhimingfu", "cl_poshi", "cl_jinchuangtie", "cl_qimendunjia", "cl_yunchou"];

// ── 敵人（act 1 餘杭山間 + boss）──
// actions: {intent, fx:[{k,a,...}]}；img 為 assets/enemies/ 檔名
const ENEMIES = {
  bandit: {
    id: "bandit", name: "山賊頭目", hp: 70, img: "bandit", facingLeft: true,
    actions: [
      { intent: "劈砍", fx: [{ k: "damage", a: 15 }] },
      { intent: "防守", fx: [{ k: "block", a: 10 }] },
      { intent: "猛擊", fx: [{ k: "damage", a: 21 }] },
    ],
  },
  beast: {
    id: "beast", name: "山林妖獸", hp: 80, img: "beast", scale: 1.1, facingLeft: true,
    actions: [
      { intent: "撕咬", fx: [{ k: "damage", a: 17 }] },
      { intent: "怒吼", fx: [{ k: "damage", a: 12 }] },
      { intent: "撲擊", fx: [{ k: "damage", a: 26 }] },
    ],
  },
  thief: {
    id: "thief", name: "小偷", hp: 62, img: "thief", facingLeft: true,
    actions: [
      { intent: "探雲手", fx: [{ k: "damage", a: 8 }] },
      { intent: "防守", fx: [{ k: "block", a: 7 }] },
      { intent: "劫財", fx: [{ k: "damage", a: 12 }, { k: "vulnerable", a: 1 }] },
    ],
  },
  wild_bee: {
    id: "wild_bee", name: "十里坡野蜂", hp: 48, img: "wild_bee", scale: 0.78, facingLeft: true,
    actions: [
      { intent: "螫刺", fx: [{ k: "damage", a: 8 }] },
      { intent: "亂舞", fx: [{ k: "damage", a: 6 }, { k: "weak", a: 1 }] },
      { intent: "振翅", fx: [{ k: "block", a: 7 }] },
    ],
  },
  bee_cocoon: {
    id: "bee_cocoon", name: "蜂蛹", hp: 30, img: "bee_cocoon", scale: 0.72, facingLeft: true,
    passive: { kind: "enrage_after", turns: 2, a: 5, label: "破繭倒數：出手兩次後狂暴（力量 +5）" },
    actions: [
      { intent: "蠕動撞", fx: [{ k: "damage", a: 6 }] },
      { intent: "結繭", fx: [{ k: "block", a: 12 }] },
      { intent: "孵化毒針", fx: [{ k: "damage", a: 8 }, { k: "poison", a: 2 }] },
    ],
  },
  leaf_sprite: {
    id: "leaf_sprite", name: "綠葉小妖", hp: 26, img: "leaf_sprite", scale: 0.78,
    actions: [
      { intent: "葉刃", fx: [{ k: "damage", a: 8 }] },
      { intent: "孢子", fx: [{ k: "poison", a: 2 }] },
      { intent: "光合護", fx: [{ k: "block", a: 8 }] },
    ],
  },
  viper: {
    id: "viper", name: "毒蛇", hp: 42, img: "serpent_demon", scale: 0.85, facingLeft: true,
    actions: [
      { intent: "毒牙穿甲（無視護體）", fx: [{ k: "damage", a: 7, pierce: true }, { k: "poison", a: 2 }] },
      { intent: "盤繞", fx: [{ k: "block", a: 6 }] },
    ],
  },
  green_snake: {
    id: "green_snake", name: "綠松蛇", hp: 44, img: "serpent_demon", scale: 0.85, facingLeft: true, tint: "hue-rotate(95deg) saturate(.8)",
    actions: [
      { intent: "毒咬", fx: [{ k: "damage", a: 4 }, { k: "poison", a: 1 }] },
      { intent: "纏繞", fx: [{ k: "block", a: 6 }] },
    ],
  },
  grass_spider: {
    id: "grass_spider", name: "草蛛", hp: 38, img: "wild_bee", scale: 0.82, facingLeft: true, tint: "hue-rotate(-60deg) brightness(.85)",
    actions: [
      { intent: "吐絲", fx: [{ k: "damage", a: 5 }, { k: "weak", a: 1 }] },
      { intent: "棘網", fx: [{ k: "block", a: 5 }, { k: "enemy_thorns", a: 3 }] },
    ],
  },
  lantern_ghost: {
    id: "lantern_ghost", name: "燈籠怪", hp: 40, img: "grave_fire", scale: 0.85, facingLeft: true,
    actions: [
      { intent: "燈火", fx: [{ k: "damage", a: 6 }] },
      { intent: "熱浪", fx: [{ k: "damage", a: 5 }, { k: "vulnerable", a: 1 }] },
      { intent: "燈影", fx: [{ k: "block", a: 6 }] },
    ],
  },
  red_eye_demon: {
    id: "red_eye_demon", name: "蛇妖男", hp: 95, img: "red_eye_demon", scale: 1.25, facingLeft: true, isBoss: true,
    actions: [
      { intent: "妖蛇噬咬", fx: [{ k: "damage", a: 14 }, { k: "poison", a: 2 }] },
      { intent: "蛇息纏身", fx: [{ k: "weak", a: 2 }] },
      { intent: "尾掃", fx: [{ k: "damage", a: 17 }, { k: "vulnerable", a: 1 }] },
      { intent: "盤身絞殺", fx: [{ k: "damage", a: 10, hits: 2 }] },
    ],
    phase2: {
      name: "狐妖女", img: "red_eye_demon_phase2",
      actions: [
        { intent: "狐火魅襲", fx: [{ k: "damage", a: 21 }, { k: "weak", a: 1 }] },
        { intent: "妖狐幻爪", fx: [{ k: "damage", a: 26 }] },
        { intent: "魅香", fx: [{ k: "poison", a: 4 }, { k: "vulnerable", a: 2 }] },
        { intent: "血怒漸盛", fx: [{ k: "enemy_strength", a: 4 }] },
      ],
    },
  },
};

// 遭遇組（依地圖層數分級）
const ENCOUNTERS = {
  easy: [["bandit"], ["thief"], ["wild_bee", "grass_spider"], ["viper", "green_snake"],
    ["lantern_ghost", "leaf_sprite"], ["wild_bee"]],
  mid: [["beast"], ["bandit"], ["bee_cocoon", "wild_bee"], ["viper", "green_snake", "grass_spider"],
    ["thief", "lantern_ghost"]],
  hard: [["beast"], ["bandit", "thief"], ["lantern_ghost", "leaf_sprite", "green_snake"],
    ["bee_cocoon", "viper", "grass_spider"]],
  elitePool: ["bandit", "beast", "thief"],
  boss: "red_eye_demon",
};

// ── 遺物 ──
const RELICS = {
  liehuoling: { id: "liehuoling", n: "烈火令", r: "common", icon: "令", d: "攻擊牌每段傷害 +1。" },
  nuwashi: { id: "nuwashi", n: "女媧石", r: "common", icon: "石", d: "每場戰鬥勝利後回復 6 點生命。" },
  guijiafu: { id: "guijiafu", n: "龜甲符", r: "common", icon: "符", d: "每場戰鬥開始時獲得 6 點護體。" },
  shedan: { id: "shedan", n: "蛇膽", r: "common", icon: "膽", d: "每場戰鬥開始時，全體敵人中 2 層蠱毒。" },
  jiuhulu: { id: "jiuhulu", n: "酒葫蘆", r: "common", icon: "壺", d: "休息時額外回復 10 點生命。" },
  qiandai: { id: "qiandai", n: "錢袋", r: "common", icon: "錢", d: "戰鬥報酬額外 +15 銅錢。" },
  chunjun: { id: "chunjun", n: "純鈞劍", r: "rare", icon: "劍", d: "每回合第一張攻擊牌費用 -1。" },
  yinhundie: { id: "yinhundie", n: "引魂蝶", r: "rare", icon: "蝶", d: "每回合開始時多抽 1 張牌。" },
};

// ── 藥品 ──
const POTIONS = {
  huichun_dan: { id: "huichun_dan", n: "回春丹", icon: "丹", d: "回復 15 點生命。", fx: [{ k: "heal", a: 15 }], price: 40 },
  lingli_dan: { id: "lingli_dan", n: "靈力丹", icon: "靈", d: "本回合靈力 +2。", fx: [{ k: "energy", a: 2 }], price: 40 },
  huti_fu: { id: "huti_fu", n: "護體符", icon: "護", d: "獲得 10 點護體。", fx: [{ k: "block", a: 10 }], price: 40 },
  jiedu_san: { id: "jiedu_san", n: "解毒散", icon: "解", d: "清除自身所有負面狀態。", fx: [{ k: "cure_debuff" }], price: 40 },
  pili_zi: { id: "pili_zi", n: "霹靂子", icon: "雷", d: "對單一敵人造成 12 點傷害。", fx: [{ k: "damage", a: 12 }], price: 40 },
  tianshi_fu: { id: "tianshi_fu", n: "天師符", icon: "符", d: "造成 10 點傷害＋1 層破綻＋1 層虛弱。", fx: [{ k: "damage", a: 10 }, { k: "vulnerable", a: 1 }, { k: "weak", a: 1 }], price: 40 },
};

// ── 奇遇 ──
const EVENTS = [
  {
    id: "immortal_cave", title: "仙人遺洞",
    text: "山壁間一道石縫透出微光。洞中蒲團尚溫，石案上擱著一只丹爐，爐裡靜靜躺著一粒龍眼大的丹藥。",
    choices: [
      { label: "打坐療傷（回復 12 點生命）", fx: { heal: 12 } },
      { label: "取走仙丹（獲得隨機藥品）", fx: { potion: true } },
    ],
  },
  {
    id: "peddler", title: "山間貨郎",
    text: "挑擔的貨郎見了你便堆起笑：「客官好眼力！小的這兒有苗疆來的稀罕藥，三十文，保命的買賣。」",
    choices: [
      { label: "買藥（花 30 銅錢，獲得隨機藥品）", fx: { gold: -30, potion: true }, needGold: 30 },
      { label: "搖頭走開", fx: {} },
    ],
  },
  {
    id: "wounded_escort", title: "受傷的鏢師",
    text: "官道旁倒著一名渾身是血的鏢師，懷裡死死護著一只木匣。他艱難睜眼：「少俠……救我一命，匣中之物相贈。」",
    choices: [
      { label: "撕衣裹傷相救（失去 7 點生命，獲得隨機遺物）", fx: { hp: -7, relic: true } },
      { label: "替他合眼，收殮遺物（獲得 25 銅錢）", fx: { gold: 25 } },
    ],
  },
  {
    id: "sword_stele", title: "古劍碑",
    text: "林中立著一方斑駁石碑，劍痕縱橫，似有前人在此演武。碑文曰：「劍心通明，萬法自生。」",
    choices: [
      { label: "參悟劍意（獲得一張卡牌）", fx: { cardReward: true } },
      { label: "拓印碑文售予書商（獲得 20 銅錢）", fx: { gold: 20 } },
    ],
  },
];

// ── 卡片描述自動生成（對齊 CardFormat 思路：顯示與機制同源）──
const FX_DESC = {
  damage: (e) => e.hits && e.hits > 1 ? `造成 ${e.a} 點傷害 ${e.hits} 次${e.pierce ? "（無視護體）" : ""}` : `造成 ${e.a} 點傷害${e.pierce ? "（無視護體）" : ""}`,
  damage_all: (e) => e.hits && e.hits > 1 ? `對全體敵人造成 ${e.a} 點傷害 ${e.hits} 次` : `對全體敵人造成 ${e.a} 點傷害`,
  block: (e) => `獲得 ${e.a} 點護體`,
  heal: (e) => `回復 ${e.a} 點生命`,
  draw: (e) => `抽 ${e.a} 張牌`,
  energy: (e) => `回復 ${e.a} 點靈力`,
  self_damage: (e) => `自身承受 ${e.a} 點反噬`,
  power: (e) => `本場戰鬥傷害提升 ${e.a}`,
  poison: (e) => `施加 ${e.a} 層蠱毒`,
  poison_all: (e) => `對全體敵人施加 ${e.a} 層蠱毒`,
  weak: (e) => `使敵人虛弱 ${e.a} 層`,
  weak_all: (e) => `使全體敵人虛弱 ${e.a} 層`,
  vulnerable: (e) => `施加 ${e.a} 層破綻`,
  vulnerable_all: (e) => `對全體敵人施加 ${e.a} 層破綻`,
  poison_burst: (e) => `引爆全部蠱毒，每層造成 ${e.a} 點傷害`,
  poison_multiply: (e) => `使敵人蠱毒層數變為 ${e.a} 倍`,
  poison_engine: (e) => `每回合開始對全體敵人施加 ${e.a} 層蠱毒`,
  cure_debuff: () => `清除自身全部負面狀態`,
  thorns: (e) => `獲得 ${e.a} 點荊棘（被攻擊時反彈傷害）`,
  next_attack_mult: (e) => `下一張攻擊牌傷害變為 ${e.a} 倍`,
  consume_energy_damage_all: (e) => `耗盡靈力，每點對全體敵人造成 ${e.a} 點傷害`,
  damage_debuff_bonus: (e) => `造成 ${e.a} 點傷害，敵人每層虛弱／破綻額外 +${e.per}`,
  damage_debuff_bonus_all: (e) => `對全體敵人造成 ${e.a} 點傷害，各依其虛弱／破綻每層額外 +${e.per}`,
  damage_poison_bonus: (e) => `造成 ${e.a} 點傷害，敵人每層蠱毒額外 +${e.per}（蠱毒不消耗）`,
  block_multiply: (e) => `當前護體翻 ${e.a} 倍`,
  block_per_turn: (e) => `每回合開始獲得 ${e.a} 點護體`,
  power_per_turn: (e) => `每回合開始攻擊力 +${e.a}`,
  turn_damage_all: (e) => `每回合開始對全體敵人降下 ${e.a} 點雷傷`,
  block_per_attack: (e) => `本場戰鬥每出一張攻擊牌獲得 ${e.a} 點護體`,
  self_block_bonus: (e) => `本場戰鬥每次獲得護體額外 +${e.a}`,
  draw_on_attack: (e) => `本場戰鬥每打出一張攻擊牌便抽 ${e.a} 張牌`,
  draw_on_skill: (e) => `本場戰鬥每打出一張技能牌便抽 ${e.a} 張牌`,
  poison_on_attack: (e) => `攻擊無護體的敵人時每段攻擊施加 ${e.a} 層蠱毒`,
  steal: (e) => `偷取 ${e.a} 銅錢`,
  stun: (e) => `${Math.round((e.chance || 1) * 100)}% 機率使敵人暈眩 1 回合`,
  enemy_thorns: (e) => `獲得 ${e.a} 點反甲`,
  enemy_strength: (e) => `攻擊力 +${e.a}`,
  strip_block: () => `碎甲`,
};

function cardDesc(card) {
  const parts = card.fx.map((e) => (FX_DESC[e.k] ? FX_DESC[e.k](e) : e.k));
  let s = parts.join("，") + "。";
  if (card.ex) s += "打出後消耗。";
  return s;
}

// 升級數值表：依 kind 決定 + 多少
const UPGRADE_BONUS = {
  damage: 3, damage_all: 3, block: 3, heal: 3, self_damage: 0,
  poison: 2, poison_all: 2, weak: 1, weak_all: 1, vulnerable: 1, vulnerable_all: 1,
  power: 1, draw: 1, energy: 1, thorns: 2, poison_burst: 1, poison_engine: 1,
  block_per_turn: 2, power_per_turn: 1, turn_damage_all: 2, block_per_attack: 1,
  self_block_bonus: 1, consume_energy_damage_all: 2, damage_debuff_bonus: 2,
  damage_debuff_bonus_all: 2, damage_poison_bonus: 2, steal: 4,
};

// 取得卡片實際數值（含升級）；回傳深拷貝
function cardView(inst) {
  const base = CARDS[inst.cid];
  const fx = base.fx.map((e) => ({ ...e }));
  let cost = base.c;
  let boosted = false;
  if (inst.up) {
    for (const e of fx) {
      const b = UPGRADE_BONUS[e.k];
      if (b) { e.a += b; boosted = true; }
    }
    if (!boosted && cost > 0) cost -= 1; // 無數值可升的卡 → 減費
  }
  return {
    uid: inst.uid, cid: inst.cid, up: !!inst.up,
    n: base.n + (inst.up ? "+" : ""), o: base.o, c: cost, t: base.t, r: base.r,
    el: base.el || null, fx, ex: base.ex, desc: cardDesc({ ...base, fx, ex: base.ex }),
  };
}

const SINGLE_TARGET_KINDS = new Set(["damage", "poison", "weak", "vulnerable", "stun",
  "poison_multiply", "damage_debuff_bonus", "damage_poison_bonus"]);
function needsTarget(view) { return view.fx.some((e) => SINGLE_TARGET_KINDS.has(e.k)); }

// ── 五靈相剋（webgame 重製新系統）──
// 仙術攻擊卡帶 水/火/雷/風/土 屬性；敵人可有「畏」屬性，被剋制屬性擊中傷害 ×1.5。
// 屬性對照 PAL1 正史：一陽指=陽火、萬里狂沙=土、鬼火燎原=火、冥河引渡=水。
const ELEMENTS = {
  fire: { n: "火", c: "#e0743f" },
  thunder: { n: "雷", c: "#b388e0" },
  water: { n: "水", c: "#6fa8c8" },
  wind: { n: "風", c: "#7fc8a0" },
  earth: { n: "土", c: "#c8a06f" },
};
const CARD_ELEMENT = {
  // 李逍遙：符法與酒系帶屬性，御劍本體保持無屬性物理
  lxy_linghuo: "fire", lxy_tianshi: "thunder", lxy_jiushen: "fire", lxy_zuilong: "water",
  // 趙靈兒：五靈仙術全系
  zl_leizhou: "thunder", zl_tianlei: "thunder", zl_leiguang: "thunder", zl_shenlei: "thunder",
  zl_kuanglei: "thunder", zl_wuleizhou: "thunder", zl_lianzhuzhou: "thunder", zl_xiaoleizhou: "thunder",
  zl_wuleihongding: "thunder",
  zl_bingzhou: "water", zl_xuanbing: "water", zl_fengxuebing: "water", zl_shuiling: "water",
  zl_yanzhou: "fire", zl_sanmeizhenhuo: "fire",
  zl_diliebeng: "earth", zl_xuanfengzhou: "wind",
  // 林月如：劍氣化風 + PAL1 正史屬性招
  lyr_qijianzhi: "wind", lyr_qijuejianqi: "wind", lyr_yiyang: "fire", lyr_lielong: "fire",
  lyr_zhanlong: "thunder", lyr_wanlikuang: "earth",
  // 阿奴：苗疆邪術的火與冥水、御蜂乘風
  anu_yufeng: "wind", anu_yanshazhou: "fire", anu_guihuo_liaoyuan: "fire", anu_minghe_yindu: "water",
};
for (const cid of Object.keys(CARD_ELEMENT)) {
  if (CARDS[cid]) CARDS[cid].el = CARD_ELEMENT[cid];
}

// 敵人「畏」屬性（act 1）
const ENEMY_WEAKNESS = {
  beast: "fire", bee_cocoon: "fire", leaf_sprite: "fire", grass_spider: "fire",
  wild_bee: "water", lantern_ghost: "water",
  viper: "wind", green_snake: "wind",
};
for (const eid of Object.keys(ENEMY_WEAKNESS)) {
  if (ENEMIES[eid]) ENEMIES[eid].weakEl = ENEMY_WEAKNESS[eid];
}
// Boss：蛇妖男畏雷，變身狐妖女後改畏水（玩家要中途換武器）
ENEMIES.red_eye_demon.weakEl = "thunder";
ENEMIES.red_eye_demon.phase2.weakEl = "water";
