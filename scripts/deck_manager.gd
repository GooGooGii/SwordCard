class_name DeckManager
extends RefCounted

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var exhausted_pile: Array[CardData] = []

func setup(cards: Array[CardData]) -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhausted_pile.clear()
	for card in cards:
		draw_pile.append(card.clone())
	draw_pile.shuffle()

func draw(count: int) -> Array[CardData]:
	var drawn: Array[CardData] = []
	for i: int in range(count):
		if draw_pile.is_empty():
			_reshuffle_discard()
		if draw_pile.is_empty():
			break
		var card: CardData = draw_pile.pop_back() as CardData
		hand.append(card)
		drawn.append(card)
	return drawn

func discard_hand() -> void:
	for card in hand:
		discard_pile.append(card)
	hand.clear()

func discard_card(card: CardData) -> void:
	if hand.has(card):
		hand.erase(card)
	discard_pile.append(card)

func exhaust_card(card: CardData) -> void:
	if hand.has(card):
		hand.erase(card)
	exhausted_pile.append(card)

# 能力牌（STS 風格）：打完即本場消失，不進任何 pile。
# 不影響 run_state.deck 持久副本（每場 setup() 重新從那邊 clone）。
func consume_card(card: CardData) -> void:
	if hand.has(card):
		hand.erase(card)
	# 不 append 任何 pile — 本場戰鬥不會再見到

func _reshuffle_discard() -> void:
	if discard_pile.is_empty():
		return
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
