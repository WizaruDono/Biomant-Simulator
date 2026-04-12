extends ActorRes

class_name NPCRes

@export var npc_type : DataManager.NPCType
@export var npc_quest_name : String
@export var npc_quest_desc : String
@export var replics : Array[String]
# косяк с присваиванием массивов при создании NPC
@export var quest_part_conditions : Array[DataManager.MonsterPartType]	# условия выполнения (части) задания	Части монсров
@export var quest_grade_conditions : DataManager.EntityGrade			# условия оценки квеста 				Улучшения (грейды)
@export var quest_family_conditions : Array[DataManager.MonsterFamily]	# 										Вид монстра
# Убираем старый единый список:
# @export var npc_shop_content : Array[CardRes]
# И добавляем список пулов по главам:
@export var shop_pools_by_chapter : Array[ShopPool]

@export var ncp_shop_lots_count : int			# количество лотов в магазине
@export var npc_mood : DataManager.OwnerType	# PLAYER, ENEMY, NEUTRAL
@export var npc_wait_timer : float
