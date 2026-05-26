class_name EventRunner
extends RefCounted

# 事件分支樹走訪器（Phase 1）
#
# 純無狀態 helper：吃 EventData.VARIANTS[variant]["tree"]（若存在），
# 提供「節點查詢 / 選項過濾 / 葉節點偵測」三組純函式。
#
# 不負責：
#   - UI 渲染（show_event_node 自己依 visible_choices 結果建按鈕）— P2
#   - 葉節點 effects 結算（EffectResolver 接管，並新增 gain_card_pool 等 kinds）— P6
#   - 戰鬥分支跳轉（main.gd 自己看 outcome.kind == "battle" 走 pending_event_return）— P3
#
# Schema 規格詳見 docs/EVENT_BRANCHING.md「統一 Schema」段。簡述：
#
#   event_data["tree"] = {
#       "root": <node>,
#       "nodes": { node_id: <node>, ... },
#   }
#   <node> = {
#       "prompt": String,                      # 該節點情境描述（取代或補充 flavor）
#       "choices": Array[<choice>],
#   }
#   <choice> = {
#       "id": String,
#       "label": String,
#       "kind_hint": String,                   # 給 UI 徽章用：reward / punish / battle / gamble / mixed / neutral
#       "requires": Dictionary (optional),     # 過濾條件，全部要過才顯示
#       "next": String (optional),             # 跳到 nodes[next]
#       "outcome": Dictionary (optional),      # 葉節點直接結算（與 next 二擇一）
#   }
#
# context 物件（呼叫方建構，呼叫前注入當下狀態）：
#   {
#       "character_id": String,                # active 角色 id
#       "gold": int,
#       "power_bonus": int,                    # run_state.power_bonus
#       "observe_tokens": int,                 # RunState.observe_tokens（P5 加入；目前用 fallback 99）
#       "relic_ids": Array[String],
#       "deck_size": int,
#   }

const LEAF_KINDS: Array = ["reward", "punish", "battle", "gamble", "mixed", "neutral"]
const ROOT_ID: String = "root"

# 此 event 是否有新版 tree schema。沒有 tree 的 fallback 走舊扁平 schema（show_event_node 既有行為）。
static func has_tree(event_data: Dictionary) -> bool:
	if not event_data.has("tree"):
		return false
	var tree: Dictionary = event_data["tree"] as Dictionary
	return tree.has("root")

# 取某節點。node_id = "" 或 "root" → tree.root；否則 tree.nodes[node_id]。
# 找不到回傳空 dict（呼叫方應 assert 處理）。
static func get_node(event_data: Dictionary, node_id: String = ROOT_ID) -> Dictionary:
	if not has_tree(event_data):
		return {}
	var tree: Dictionary = event_data["tree"] as Dictionary
	if node_id.is_empty() or node_id == ROOT_ID:
		return tree.get("root", {}) as Dictionary
	var nodes: Dictionary = tree.get("nodes", {}) as Dictionary
	return nodes.get(node_id, {}) as Dictionary

# 取節點下「玩家當下可見」的選項（過濾掉 requires 不符的）。
# 回傳的是原 dict 的 reference — 呼叫方不應改它。
static func visible_choices(node: Dictionary, context: Dictionary) -> Array:
	var result: Array = []
	var choices: Array = node.get("choices", []) as Array
	for entry: Variant in choices:
		if not (entry is Dictionary):
			continue
		var choice: Dictionary = entry as Dictionary
		if eval_requires(choice.get("requires", {}) as Dictionary, context):
			result.append(choice)
	return result

# 評估 requires 條件。空 dict / 缺欄位 → 直接通過。所有條件 AND。
# 支援的鍵：
#   character:        Array[String]   — active 角色 id 必須在內
#   min_gold:         int             — run_state.gold >= N
#   has_relic:        String          — 持有此 relic id（也接受 Array → 任一持有即可）
#   min_power:        int             — run_state.power_bonus >= N
#   min_power_bonus:  int             — 同上（alias）
#   max_power:        int             — run_state.power_bonus <= N（給「殺心太重者不允」用）
#   observe_token:    bool            — true 時要求 context.observe_tokens >= 1
#   min_deck_size:    int             — deck_size >= N
static func eval_requires(requires: Dictionary, context: Dictionary) -> bool:
	if requires.is_empty():
		return true
	# character
	if requires.has("character"):
		var allowed: Array = requires["character"] as Array
		var cid: String = String(context.get("character_id", ""))
		if not allowed.is_empty() and not (cid in allowed):
			return false
	# min_gold
	if requires.has("min_gold"):
		if int(context.get("gold", 0)) < int(requires["min_gold"]):
			return false
	# has_relic（單一 id 或 Array）
	if requires.has("has_relic"):
		var owned: Array = context.get("relic_ids", []) as Array
		var need: Variant = requires["has_relic"]
		if need is String:
			if not (String(need) in owned):
				return false
		elif need is Array:
			var ok: bool = false
			for r: Variant in need as Array:
				if String(r) in owned:
					ok = true
					break
			if not ok:
				return false
	# min_power / min_power_bonus
	var min_power_key: String = ""
	if requires.has("min_power"):
		min_power_key = "min_power"
	elif requires.has("min_power_bonus"):
		min_power_key = "min_power_bonus"
	if not min_power_key.is_empty():
		if int(context.get("power_bonus", 0)) < int(requires[min_power_key]):
			return false
	# max_power
	if requires.has("max_power"):
		if int(context.get("power_bonus", 0)) > int(requires["max_power"]):
			return false
	# observe_token（true → 至少 1 個 token）
	if requires.has("observe_token") and bool(requires["observe_token"]):
		if int(context.get("observe_tokens", 0)) < 1:
			return false
	# min_deck_size
	if requires.has("min_deck_size"):
		if int(context.get("deck_size", 0)) < int(requires["min_deck_size"]):
			return false
	return true

# 葉節點：有 outcome（無論 next 是否存在；outcome 優先）
static func is_leaf(choice: Dictionary) -> bool:
	return choice.has("outcome")

# 取葉節點的分類 hint。優先 outcome.kind，其次 choice.kind_hint，預設 "neutral"。
# 給 UI 上徽章用，不影響邏輯。
static func leaf_kind(choice: Dictionary) -> String:
	if choice.has("outcome"):
		var outcome: Dictionary = choice["outcome"] as Dictionary
		if outcome.has("kind"):
			var k: String = String(outcome["kind"])
			if k in LEAF_KINDS:
				return k
	if choice.has("kind_hint"):
		var hint: String = String(choice["kind_hint"])
		if hint in LEAF_KINDS:
			return hint
	return "neutral"

# 給 UI 用的徽章文字 / 顏色提示。實際顏色由 ThemeColors 對應。
# 回傳 {text: String, color_key: String}
static func badge_for_kind(kind: String) -> Dictionary:
	match kind:
		"reward":
			return {"text": "✦ 機緣", "color_key": "ACCENT_GOLD"}
		"punish":
			return {"text": "⚠ 風險", "color_key": "HP_FILL"}
		"battle":
			return {"text": "⚔ 戰鬥", "color_key": "PANEL_NAVY"}
		"gamble":
			return {"text": "🎲 賭運", "color_key": "HIGHLIGHT_GOLD"}
		"mixed":
			return {"text": "⚖ 取捨", "color_key": "TEXT_DIM"}
		_:
			return {"text": "", "color_key": "TEXT_MUTED"}

# 給呼叫方一個方便的「從 run_state 建 context」helper。
# 不依賴 RunState 型別（呼叫方注入 dict 即可）— 保留 EventRunner 對 RunState 解耦，方便測試。
static func build_context(
	character_id: String,
	gold: int,
	power_bonus: int,
	observe_tokens: int,
	relic_ids: Array,
	deck_size: int
) -> Dictionary:
	return {
		"character_id": character_id,
		"gold": gold,
		"power_bonus": power_bonus,
		"observe_tokens": observe_tokens,
		"relic_ids": relic_ids.duplicate(),
		"deck_size": deck_size,
	}
