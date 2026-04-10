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

# Раса / Локация существ
enum MonsterFamily {
	UNDEAD, ANIMAL, HUMAN
}

# Существа
enum MonsterBase {
	SKELETON, ZOMBIE, 
	COCK, SHEEP,
	
	# Поставил в конец, чтобы настройки не сбились
	ANYONE,
}

enum UpgradeType {
	SPEED, RARE_DROP
}

var card_header_size : float = 22

var default_z_index : int = 0	# нигде не используется?

var parts_size : int = 6

var monster_love_size : int = 2

var parts_merger_count: int = 2

## Максимальный грейд для типа монстра
var MAX_GRADES = {
	MonsterBase.COCK: 3,
	MonsterBase.SKELETON: 3, 
	MonsterBase.ZOMBIE: 2, 
	MonsterBase.SHEEP: 2
}

# ЦЕНЫ
@export var order_reroll_cost : int = 0  # Заказы меняем бесплатно
@export var shop_reroll_cost : int = 5   # Товары за деньги

var npc_positions : Array[float] = [-500, -200]

var chances_dict : Dictionary[EntityGrade, float] = {
	EntityGrade.T1 : 0.1,	# значение 0.1 лишнее или используется хз где. Оставь
	EntityGrade.T2 : 0.2,	# 20% шанс на Т2
	EntityGrade.T3 : 1
}


# UPGRADE потенциальный

# Шансы на разный тип дропа у торгаша, в сумме по хорошему должно быть меньше 1.
var chance_location_from_trader		: float = 0.25	# 0.25 = 25%
var chance_production_from_trader	: float = 0.1

# Шанс на двойню и тройню. Работают независимо
var chacne_double_child : float = 0.25	# 0.25 = 25%
var chacne_triple_child : float = 0.05

# Шансы для обменника (PART_MERGER)
var chance_changeshop_to_grade_2 : float = 0.50 # 50% шанс апнуть с 1 на 2 уровень
var chance_changeshop_to_grade_3 : float = 0.30 # 30% шанс апнуть с 2 на 3 уровень

# Все возможные товары в магазине (Лопаты, рецепты, локации и т.д.)
#@export var all_shop_items : Array[CardRes] = []

# Словарь координат: Семейство -> Точки крепления на ТЕЛЕ
const BASE_JOINTS = {
		MonsterBase.ZOMBIE: {
		MonsterPartType.BODY:  Vector2(0.0,		0.0),
		MonsterPartType.HEAD:  Vector2(67.0,	47.0),
		MonsterPartType.L_ARM: Vector2(57.0,	56.0),
		MonsterPartType.R_ARM: Vector2(76.0,	56.0),
		MonsterPartType.L_LEG: Vector2(56.0,	87.0),
		MonsterPartType.R_LEG: Vector2(70.0,	87.0)
	},
	MonsterBase.SKELETON: {
		MonsterPartType.BODY:  Vector2(0.0,		0.0),
		MonsterPartType.HEAD:  Vector2(66.0,	47.0),
		MonsterPartType.L_ARM: Vector2(59.0,	55.0),
		MonsterPartType.R_ARM: Vector2(76.0,	55.0),
		MonsterPartType.L_LEG: Vector2(57.0,	83.0),
		MonsterPartType.R_LEG: Vector2(70.0,	83.0)
	},
	MonsterBase.COCK: {
		MonsterPartType.BODY:  Vector2(0.0,		0.0),
		MonsterPartType.HEAD:  Vector2(65.0,	50.0),
		MonsterPartType.L_ARM: Vector2(55.0,	59.0),
		MonsterPartType.R_ARM: Vector2(76.0,	59.0),
		MonsterPartType.L_LEG: Vector2(59.0,	84.0),
		MonsterPartType.R_LEG: Vector2(69.0,	83.0)
	},
	MonsterBase.SHEEP: {
		MonsterPartType.BODY:  Vector2(50.0,		50.0),
		MonsterPartType.HEAD:  Vector2(61.0,	47.0),
		MonsterPartType.L_ARM: Vector2(51.0,	65.0),
		MonsterPartType.R_ARM: Vector2(78.0,	65.0),
		MonsterPartType.L_LEG: Vector2(57.0,	85.0),
		MonsterPartType.R_LEG: Vector2(73.0,	85.0)
	},
	# Добавляем сюда новые виды по мере их отрисовки
	# можно не добавлять апгрейднутых существ, если их размеры тела одинаковы
	#MonsterBase.SKELETON: {
		#MonsterPartType.BODY:  Vector2(0.0,		0.0),
		#MonsterPartType.HEAD:  Vector2(,	),	# 1 вниз, 	1 вправо (от центра шеи)
		#MonsterPartType.L_ARM: Vector2(,	),	# 4 вниз, 	1 вправо
		#MonsterPartType.R_ARM: Vector2(,	),	# 4 вниз, 	2 влево
		#MonsterPartType.L_LEG: Vector2(,	),	# 1 вверх, 	2 вправо
		#MonsterPartType.R_LEG: Vector2(,	)	# 1 вверх, 	2 влево
	#},
	
}
# Функция, чтобы получать данные - вектора смещения для частей тел из их расы (тела):
func get_joint_pos(base: MonsterBase, type: MonsterPartType) -> Vector2:
	if BASE_JOINTS.has(base) and BASE_JOINTS[base].has(type):
		return BASE_JOINTS[base][type]
	return Vector2.ZERO
