class_name BanterData
extends RefCounted
# 隊友戰鬥台詞（IMPROVEMENT_PLAN P2-9）。
# 三個觸發點：switch_in（切人上場）/ ally_down（隊友倒下後接替上場）/ victory（戰鬥勝利）。
# pair 台詞 key = "incoming|outgoing"（切入者|被換下者），語感對齊 PAL1 角色性格：
# 逍遙痞、月如嗆、靈兒柔、阿奴活潑。同場戰鬥同一句不重複（caller 傳 used 字典）。

const SWITCH_IN: Dictionary = {
	"li_xiaoyao": ["看我的！", "御劍之術，正要請教！", "換我來會會你！"],
	"zhao_linger": ["我來幫大家。", "靈兒不會退的。", "五靈聽我號令。"],
	"lin_yueru": ["就知道少不了我！", "林家堡的劍，不是擺著看的。", "都讓開，看姑娘我的！"],
	"anu": ["阿奴上啦！", "蠱蠱們，開飯囉！", "哼，嚐嚐阿奴的毒針！"],
}

const SWITCH_IN_PAIR: Dictionary = {
	"li_xiaoyao|lin_yueru": ["月如先歇歇，這風頭借我出一回！"],
	"lin_yueru|li_xiaoyao": ["李逍遙你讓開，看姑娘我的！"],
	"li_xiaoyao|zhao_linger": ["靈兒退後，我來！"],
	"zhao_linger|li_xiaoyao": ["逍遙哥哥歇一歇，換靈兒來。"],
	"anu|zhao_linger": ["靈兒姊姊別怕，阿奴上啦！"],
	"anu|lin_yueru": ["月如姊姊看好囉！"],
	"lin_yueru|anu": ["小阿奴退下，姊姊替你出氣！"],
	"zhao_linger|anu": ["阿奴乖，讓靈兒姊姊來。"],
}

# 隊友倒下、接替者被迫上場時：speaker = 接替上場者
const ALLY_DOWN: Dictionary = {
	"li_xiaoyao": ["可惡——撐住，剩下的交給我！", "你給我躺好，這筆帳我來討！"],
	"zhao_linger": ["不要……我一定會救你回來！", "對不起……接下來換我守護大家。"],
	"lin_yueru": ["敢動我的人？拿命來！", "閉上眼歇著，看我替你報仇！"],
	"anu": ["嗚……你們會付出代價的！", "阿奴生氣了——真的生氣了！"],
}

const VICTORY: Dictionary = {
	"li_xiaoyao": ["呼……還好沒丟臉。", "嘿，這就是御劍術！"],
	"zhao_linger": ["大家都沒事吧？", "結束了……走吧。"],
	"lin_yueru": ["就這點本事也敢攔路？", "哼，手下敗將。"],
	"anu": ["耶！阿奴最厲害！", "嘻嘻，蠱蠱吃飽了～"],
}

# 取一句未用過的台詞；trigger ∈ switch_in / ally_down / victory。
# used：caller 持有的「本場已用句子」集合（key = 句子本身）。取到後 caller 自行標記。
static func line_for(trigger: String, incoming_id: String, outgoing_id: String, used: Dictionary) -> String:
	var candidates: Array = []
	if trigger == "switch_in" and not outgoing_id.is_empty():
		candidates += (SWITCH_IN_PAIR.get("%s|%s" % [incoming_id, outgoing_id], []) as Array)
	var pool: Dictionary = {}
	match trigger:
		"switch_in": pool = SWITCH_IN
		"ally_down": pool = ALLY_DOWN
		"victory": pool = VICTORY
	candidates += (pool.get(incoming_id, []) as Array)
	var fresh: Array = []
	for line: Variant in candidates:
		if not used.has(String(line)):
			fresh.append(line)
	if fresh.is_empty():
		return ""
	return String(fresh[randi() % fresh.size()])
