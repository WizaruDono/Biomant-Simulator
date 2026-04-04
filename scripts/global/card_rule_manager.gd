class_name CardRuleManager extends Node


const CT = DataManager.CardType

## В ключ запрещено класть всё, что в его списке, т.е. в 
## - в PRODUCTION нельзя положить PRODUCTION и LOCATION
## - в MONSTER нельзя положить LOCATION и PRODUCTION
const FORBIDDEN_FOR_STACK = {
	CT.PRODUCTION: [CT.PRODUCTION, CT.LOCATION],
	CT.MONSTER: [CT.LOCATION, CT.PRODUCTION],
	CT.LOCATION: [CT.PRODUCTION, CT.LOCATION], 
	CT.MONSTER_PART: [CT.LOCATION], 
	CT.ENVIRONMENT: [CT.LOCATION], 
	CT.RES: [CT.LOCATION], 
	CT.ITEM: [CT.LOCATION], 
	CT.RECEPT: [CT.LOCATION], 
	CT.NPC: [CT.LOCATION], 
	CT.ORDER: [CT.PRODUCTION, CT.LOCATION, CT.UPGRADE], 
	CT.UPGRADE: [CT.LOCATION]
}

const FORBIDDEN_TO_BE_MOVED = [
	CT.ORDER
]

# Карта b помещается на карту a
static func can_stack(card_a: Card, card_b: Card) -> bool:
	var forbidden_types = FORBIDDEN_FOR_STACK.get(card_a.card_type, [])
	if card_b.card_type in forbidden_types: 
		print_rich("[color=red]DEBUG: FORBIDDEN[/color] ", card_b, ' into ', card_a)
		return false
	
	# Пока что всё остальное можно
	print_rich("[color=green]DEBUG: ALLOWED[/color] ", card_b, ' into ', card_a)
	return true

static func forbidden_to_be_moved(card: Card) -> bool:
	return card.card_type in FORBIDDEN_TO_BE_MOVED
