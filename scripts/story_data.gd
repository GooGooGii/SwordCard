class_name StoryData
extends RefCounted
# 旅程敘事層（IMPROVEMENT_PLAN P1-3）：
# - ACT_INTROS：每幕首次進地圖前的開場字卡（2-3 句：目的＋鉤子）
# - BOSS_OUTROS：擊敗 boss 後劇情圖上的一行定場文字（無圖時做純文字字卡 fallback）
# - ending_line()：終幕拜月教主的結局文字，依 event_flags 出變體
# 文案依 PAL1 正史（docs/PAL1_CANON.md）；改幕結構時同步本檔。

const ACT_INTROS: Dictionary = {
	1: {"title": "餘杭山間", "lines": [
		"渡口傳言：仙靈島上有仙女、有靈藥。",
		"客棧少年背上木劍，為治嬸嬸的沉痾踏上山路。",
		"山間盜匪橫行、妖物出沒——求藥之旅，從第一步起就不太平。",
	]},
	2: {"title": "仙靈島", "lines": [
		"霧鎖碧波，水月宮靜立湖心。",
		"傳聞黑苗人的船隊已在暗處集結，島上的安寧只剩最後幾日。",
		"求藥之人啊，切莫遲疑。",
	]},
	3: {"title": "蘇州城", "lines": [
		"護送靈兒南下的路，先經蘇州。",
		"林家堡比武招親的帖子貼滿街口，市井之間卻也藏著賊人與妖祟。",
	]},
	4: {"title": "將軍塚", "lines": [
		"城外將軍塚，百年亡將不得安眠。",
		"陰風捲殘旗、磷火引路——要往南去，先得從亡者的國度借道。",
	]},
	5: {"title": "試煉窟", "lines": [
		"地脈深處藏著五靈奧義，石壁上的法陣靜候有緣人。",
		"試煉窟不殺闖入者——它只試煉。",
	]},
	6: {"title": "鎖妖塔", "lines": [
		"鎖妖塔千年封印、萬妖囚牢。",
		"塔中亦囚著靈兒身世的真相。",
		"塔倒之日，方知人蛇殊途。",
	]},
	7: {"title": "苗疆蠱土", "lines": [
		"南疆十萬大山，蠱毒瘴氣之鄉。",
		"巫王已死、巫后蒙冤，拜月教的影子罩住整片苗疆。",
		"阿奴的家鄉，正在等一個說法。",
	]},
	8: {"title": "拜月決戰", "lines": [
		"水底迷宮的盡頭，拜月教主靜候多時。",
		"他要以水魔獸重塑人間——",
		"這一戰沒有退路，也不需要退路。",
	]},
}

# boss_id 對照 scripts/ascension.gd 的 BOSS_IDS
const BOSS_OUTROS: Dictionary = {
	"miao_chieftain": "黑苗頭領伏誅，仙靈島的硝煙散去——但被擄走的人，還在更遠的地方。",
	"red_eye_demon": "蛇妖斂形遁去，巢穴歸於死寂。",
	"centipede_lord": "石長老轟然崩解，試煉窟的迴音久久不息。",
	"witch_queen": "火麒麟長嘯歸山，靈獸的試煉就此作結。",
	"tomb_general": "赤鬼王化作飛灰，將軍塚的亡魂終得安眠。",
	"zombie_general": "屍王倒下，邪氣如潮水般退去。",
	"zhenyu_mingwang": "明王法相歸寂，鎖妖塔的封印露出了它守護千年的秘密。",
	"moon_worshipper": "拜月教徒潰散奔逃，教壇的月徽碎了一地。",
	"baiyue_lord": "拜月教主沉入水底，水魔獸的咆哮歸於寂靜。十里坡的少年走到了這裡——仙劍之路，至此功成。",
}

static func act_intro(act: int) -> Dictionary:
	return ACT_INTROS.get(act, {}) as Dictionary

static func boss_outro(boss_id: String) -> String:
	return String(BOSS_OUTROS.get(boss_id, ""))

# 終幕結局變體：依長尾旗標收束（優先序由上而下）。rs = RunState。
static func ending_line(rs) -> String:
	var base: String = String(BOSS_OUTROS.get("baiyue_lord", ""))
	if rs == null:
		return base
	if rs.has_event_flag("nuwa_jade"):
		return "女媧玉的靈光護住眾生，水魔獸隨教主一同消逝。靈兒望著平靜的湖面，輕聲說：回家吧。"
	if rs.has_event_flag("fox_spared"):
		return "水波平息時，遠處似有狐影回望一眼，倏然隱去。一路結下的善因善果，俱在這一戰了結。"
	return base
