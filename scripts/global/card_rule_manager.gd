class_name CardRuleManager extends Node


const CardType = DataManager.CardType

## Для ключа запрещено всё, что в его списке, т.е. в 
## - в PRODUCTION нельзя положить PRODUCTION
## - в MONSTER нельзя положить LOCATION и PRODUCTION
const FORBIDDEN_FOR_STACK = {
	CardType.PRODUCTION: [CardType.PRODUCTION],
	CardType.LOCATION: [CardType.PRODUCTION],
	CardType.MONSTER: [CardType.LOCATION, CardType.PRODUCTION]
}

const FORBIDDEN_TO_BE_MOVED = [
	CardType.ORDER
]

# Карта b помещается на карту a
static func can_stack(card_a: Card, card_b: Card) -> bool:
	var forbidden_types = FORBIDDEN_FOR_STACK.get(card_a.card_type, [])
	if card_b.card_type in forbidden_types: return false
	
	# Пока что всё остальное можно
	return true

static func forbidden_to_be_moved(card: Card) -> bool:
	return card.card_type in FORBIDDEN_TO_BE_MOVED
