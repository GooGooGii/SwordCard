extends SceneTree
#
# 出牌特效動畫「實機渲染截圖」工具
# ---------------------------------------------------------------------------
# 用途：開一場真戰鬥、直接觸發指定卡片的 _animate_* 動畫，在動畫途中某一幀
#       截圖存成 PNG，供肉眼檢視動畫大小 / 位置 / 時機（純推理看不出來）。
#
# 跑法（務必 windowed，不要 --headless；headless 無 rendering、截圖會全黑）：
#   1. 若特效圖剛新增 / 沒匯入過，先 import 一次：
#        godot --headless --path . --import
#   2. 渲染：
#        godot --path . -s render_effects.gd
#   3. 看 res://_<label>.png（用 Read 工具直接開圖）；看完自行刪除暫存 PNG。
#
# 設定：改下面 SHOTS 即可。每筆 = [card_id, frame, label]
#   - card_id : 見 CARD_ANIM（會自動對應到正確的 _animate_* 方法）
#   - frame   : 觸發動畫後等幾個 process_frame 再截圖（windowed 下約 60fps，
#               即 frame≈秒數×60）。多段動畫想抓不同時點就放多筆同卡不同 frame。
#   - label   : 輸出檔名 res://_<label>.png
# ENEMY_IDS 決定戰場上有幾隻敵人（AOE / 劍雨類要多隻才看得出涵蓋範圍）。
# ---------------------------------------------------------------------------

const WINDOW := Vector2i(1280, 720)
const ENEMY_IDS := ["bandit", "beast", "fox_spirit"]   # 1~3 隻

const SHOTS := [
	["lxy_wanjian", 14, "fx_wj_rise"],   # 萬劍訣：引劍升天
	["lxy_wanjian", 45, "fx_wj_rain"],   # 萬劍訣：劍雨
]

# card_id → 動畫方法（鏡像 main.gd play_card 內的 match dispatch；新增動畫時補這裡）
const CARD_ANIM := {
	"lxy_wanjian": "_animate_wan_jian_jue_effect", "lxy_wanjianguizong": "_animate_wan_jian_jue_effect",
	"lxy_yujian": "_animate_yu_jian_effect",
	"lxy_tianjian": "_animate_tian_jian_effect",
	"lxy_jianzhen": "_animate_jian_zhen_effect",
	"lxy_jiulong": "_animate_jiu_long_effect",
	"lxy_xiaoyao_shenjian": "_animate_xiaoyao_shenjian_effect",
	"lxy_jiushen": "_animate_jiu_shen_effect",
	"lxy_feilong": "_animate_fei_long_effect",
	"lxy_zuimeng": "_animate_zui_meng_effect",
	"lyr_qiankun": "_animate_qian_kun_effect",
	"lyr_qijianzhi": "_animate_qi_jian_zhi_effect", "lyr_qijuejianqi": "_animate_qi_jian_zhi_effect",
	"lyr_bianying": "_animate_bian_ying_effect",
	"lyr_lielong": "_animate_lie_long_effect",
	"lyr_wanlikuang": "_animate_wan_li_kuang_effect",
	"lyr_yiyang": "_animate_yi_yang_effect",
	"lyr_zhanlong": "_animate_zhan_long_effect",
	"lyr_fenghuan": "_animate_feng_huang_effect", "lyr_yuehua": "_animate_feng_huang_effect",
	"zl_leizhou": "_animate_lightning_effect", "zl_leiguang": "_animate_lightning_effect",
	"zl_wuleizhou": "_animate_lightning_effect", "zl_shenlei": "_animate_lightning_effect",
	"zl_tianlei": "_animate_lightning_effect", "zl_kuanglei": "_animate_lightning_effect",
	"zl_xiaoleizhou": "_animate_lightning_effect", "zl_lianzhuzhou": "_animate_lightning_effect",
	"zl_xuanbing": "_animate_ice_effect", "zl_fengxuebing": "_animate_ice_effect", "zl_bingzhou": "_animate_ice_effect",
	"zl_yanzhou": "_animate_fire_effect", "zl_sanmeizhenhuo": "_animate_fire_effect",
	"zl_diliebeng": "_animate_earth_effect", "zl_taishan": "_animate_earth_effect",
	"zl_guanyin": "_animate_heal_effect", "zl_wuqi": "_animate_heal_effect",
	"zl_ganlin": "_animate_heal_effect", "zl_shuiling": "_animate_heal_effect",
	"zl_mengshe": "_animate_meng_she_effect", "zl_mengshe_ls": "_animate_meng_she_effect",
	"zl_huihun": "_animate_hui_hun_effect",
	"zl_xuanfengzhou": "_animate_xuan_feng_effect", "zl_fengling": "_animate_xuan_feng_effect",
	"anu_yufeng": "_animate_yu_feng_effect",
	"anu_wanyi": "_animate_wan_yi_effect", "anu_wanyi_ls": "_animate_wan_yi_effect",
	"anu_baozhagu": "_animate_bao_zha_gu_effect",
	"anu_duzhen": "_animate_du_zhen_effect", "anu_lianduzhen": "_animate_du_zhen_effect", "anu_yanshazhou": "_animate_du_zhen_effect",
	"anu_wuyuezhan": "_animate_wu_yue_zhan_effect", "anu_xuerenwu": "_animate_wu_yue_zhan_effect",
	"anu_gushen": "_animate_gu_shen_effect",
	"anu_mihun": "_animate_confuse_effect", "anu_guijiang": "_animate_confuse_effect", "anu_guwang": "_animate_confuse_effect",
	"anu_guzhang": "_animate_poison_fog_effect", "anu_duwu": "_animate_poison_fog_effect", "anu_sanshigu": "_animate_poison_fog_effect",
	# P2 高光卡（2026-06-11，docs/ANIM_PLAN.md）
	"lyr_tongqianbiao": "_animate_multi_slash_effect", "lyr_lianhuan": "_animate_multi_slash_effect",
	"lyr_shuangjianci": "_animate_multi_slash_effect", "lyr_xuanjian": "_animate_multi_slash_effect",
	"lxy_qingyan_zhuying": "_animate_multi_slash_effect",
	"lyr_poqian": "_animate_heavy_sword_effect", "lyr_juesha": "_animate_heavy_sword_effect",
	"lyr_suohun": "_animate_heavy_sword_effect", "cl_chenxi_poshi": "_animate_heavy_sword_effect",
	"cl_fenjinjue": "_animate_fen_jin_effect",
	"zl_wanlingshi": "_animate_wan_ling_shi_effect",
	"anu_minghe_yindu": "_animate_ghost_flame_effect", "anu_guihuo_liaoyuan": "_animate_ghost_flame_effect",
	"anu_guxue_shixin": "_animate_poison_nova_effect", "anu_wangushitian": "_animate_poison_nova_effect",
	"anu_cuihua": "_animate_poison_nova_effect",
	"lxy_zuilong": "_animate_jiu_shen_effect",
	"zl_shuiyin": "_animate_ice_effect",
}

var main: Node

func _initialize() -> void:
	var root := get_root()
	root.size = WINDOW
	main = load("res://scripts/main.gd").new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(main)
	_run()

# 蒐集所有角色的全部卡（起始 + 獎勵 + 升級解鎖），card_id → CardData
func _card_map() -> Dictionary:
	var m := {}
	for ch in GameData.characters():
		for c in ch.starting_deck: m[c.id] = c
		for c in ch.reward_pool: m[c.id] = c
		for c in LevelSystem.all_unlocked_cards(ch.id, 99): m[c.id] = c
	return m

func _run() -> void:
	await process_frame
	await process_frame
	main.start_run(GameData.characters()[0])
	await process_frame
	var enemies := []
	for eid in ENEMY_IDS:
		enemies.append(GameData.enemy_by_id(eid))
	main.start_next_battle(enemies)
	for i in range(6): await process_frame

	var cards := _card_map()
	for shot in SHOTS:
		var cid: String = shot[0]
		var frame: int = shot[1]
		var label: String = shot[2]
		if not cards.has(cid):
			print("[probe] MISSING card ", cid); continue
		if not CARD_ANIM.has(cid):
			print("[probe] no anim method for ", cid); continue
		main.call(CARD_ANIM[cid], cards[cid])
		for i in range(frame): await process_frame
		get_root().get_texture().get_image().save_png("res://_%s.png" % label)
		print("[probe] saved _%s.png  (card=%s frame=%d)" % [label, cid, frame])
		for i in range(70): await process_frame   # 讓動畫收尾再跑下一張
	print("[probe] done; %d shot(s)" % SHOTS.size())
	quit(0)
