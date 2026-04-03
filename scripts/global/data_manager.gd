extends Node


var r = 1

var money = 100


enum CardState {
	APPEARS, ON_FIELD, DRAGGED, HOVER_STACK, ENTER_STACK, STACK, IN_STACK, EXIT_STACK, DESTROYED
}

enum CardType {
	PRODUCTION, LOCATION, MONSTER_PART, MONSTER, ENVIRONMENT, RES, ITEM, RECEPT, NPC, ORDER, UPGRADE
}

enum NPCType {
	QUESTER, TRADER, BUYER
}

enum OwnerType {
	PLAYER, ENEMY, NEUTRAL
}

enum MonsterPartType {
	BODY, HEAD, L_ARM, R_ARM, L_LEG, R_LEG
}

enum EntityGrade {
	T1, T2, T3
}

enum GeneType {
	TOXIC, FLYING, SPECTER
}

enum ProductionType {
	PART_CREATOR, RES_CREATOR, MONSTER_CREATOR, MONSTER_MERGER, PART_MIXER, PART_MERGER
}

enum LocationType {
	GRAVEYARD, FARM, 
}

enum PercType {
	NONE, DIGGER, FIGHTER
}

enum MonsterFamily {
	UNDEAD, ANIMAL, HUMAN
}

enum MonsterBase {
	SKELETON, ZOMBIE, 
	COCK, 
}

enum UpgradeType {
	SPEED, RARE_DROP
}

var card_header_size : float = 22

var default_z_index : int = 5

var parts_size : int = 6

var monster_love_size : int = 2

var parts_merger_count: int = 5

## Максимальный грейд здесь означает индекс массива EntityGrade. 
## Прямо сейчас у нас только 2 грейда, т.е. значения 0 и 1. 
## Временно уменьшил здесь максимальный грейд
var max_grade: int = 1

# ЦЕНЫ
@export var order_reroll_cost : int = 0  # Заказы меняем бесплатно
@export var shop_reroll_cost : int = 5   # Товары за деньги

var npc_positions : Array[float] = [-500, -200]

var chances_dict : Dictionary[EntityGrade, float] = {
	EntityGrade.T1 : 0.1,	# значение 0.1 лишнее или используется хз где. Оставь
	EntityGrade.T2 : 0.2,	# 20% шанс на Т2
	EntityGrade.T3 : 1
}



# Все возможные товары в магазине (Лопаты, рецепты, локации и т.д.)
#@export var all_shop_items : Array[CardRes] = []

# Словарь координат: Семейство -> Точки крепления на ТЕЛЕ
const BASE_JOINTS = {
	MonsterBase.ZOMBIE: {
		MonsterPartType.HEAD:  Vector2(3.0,		-49.0),
		MonsterPartType.L_ARM: Vector2(-7.0,	-41.0),
		MonsterPartType.R_ARM: Vector2(12.0,	-41.0),
		MonsterPartType.L_LEG: Vector2(-7.0,	-9.0),
		MonsterPartType.R_LEG: Vector2(6.0,		-9.0)
	},
	MonsterBase.SKELETON: {
		MonsterPartType.HEAD:  Vector2(5.0,		-49.0),
		MonsterPartType.L_ARM: Vector2(-7.0,	-41.0),
		MonsterPartType.R_ARM: Vector2(12.0,	-41.0),
		MonsterPartType.L_LEG: Vector2(-7.0,	-14.0),
		MonsterPartType.R_LEG: Vector2(6.0,		-15.0)
	},
	# Добавляем сюда новые виды по мере их отрисовки
	# можно не добавлять апгрейднутых существ, если их размеры тела одинаковы
	
	#MonsterRace.SKELETON: {
		#MonsterPartType.HEAD:  Vector2(,	),
		#MonsterPartType.L_ARM: Vector2(,	),
		#MonsterPartType.R_ARM: Vector2(,	),
		#MonsterPartType.L_LEG: Vector2(,	),
		#MonsterPartType.R_LEG: Vector2(,	)
	#},
	
}
# Функция, чтобы получать данные - вектора смещения для частей тел из их расы (тела):
func get_joint_pos(base: MonsterBase, type: MonsterPartType) -> Vector2:
	if BASE_JOINTS.has(base) and BASE_JOINTS[base].has(type):
		return BASE_JOINTS[base][type]
	return Vector2.ZERO
