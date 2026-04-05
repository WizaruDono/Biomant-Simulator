extends CardRes
class_name OrderRes

@export var is_check_part_side: bool = true
@export var quest_part_conditions : Array[DataManager.MonsterPartType]

@export var is_check_family_conditions: bool = true
@export var quest_family_conditions : Array[DataManager.MonsterFamily]

@export var is_check_base_conditions: bool = true
@export var quest_base_conditions : Array[DataManager.MonsterBase]

@export var is_check_perc_conditions: bool = true
@export var quest_perc_conditions: DataManager.PercType
# ==========================

@export var order_type : DataManager.CardType		# PRODUCTION, LOCATION, MONSTER_PART, MONSTER, ENVIRONMENT, RES, ITEM, RECEPT, NPC, ORDER
@export var reward_amount : int
@export var special_reward : CardRes
