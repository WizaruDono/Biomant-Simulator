extends CardRes
class_name OrderRes

@export var quest_part_conditions : Array[DataManager.MonsterPartType]
@export var quest_grade_conditions : DataManager.EntityGrade
@export var quest_family_conditions : Array[DataManager.MonsterFamily]

# === НОВОЕ ДЛЯ ГИБКОСТИ ===
@export var quest_base_conditions : Array[DataManager.MonsterBase]
@export var check_base_condition : DataManager.MonsterBase # Нужен именно Зомби или Скелет, или ...
@export var check_entire_monster_grade : bool = false # Проверять тир ВСЕГО монстра, а не только частей
# ==========================

@export var order_type : DataManager.CardType		# PRODUCTION, LOCATION, MONSTER_PART, MONSTER, ENVIRONMENT, RES, ITEM, RECEPT, NPC, ORDER
@export var reward_amount : int
@export var special_reward : CardRes
