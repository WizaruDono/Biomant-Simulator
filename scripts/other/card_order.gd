extends Card
class_name CardOrder

@export var order_res : OrderRes
@export var order_name : String
@export var order_desc : String
@export var quest_part_conditions : Array[DataManager.MonsterPartType]
@export var quest_grade_conditions : DataManager.EntityGrade
@export var quest_family_conditions : Array[DataManager.MonsterFamily]
@export var order_type : DataManager.CardType
@export var reward_amount : int
@export var special_reward : CardRes


func initialize():
	await get_tree().process_frame
	card_type = order_res.card_type
	card_texture = order_res.card_texture
	card_grade = order_res.card_grade
	card_cost = order_res.card_cost
	order_name = order_res.card_name
	order_desc = order_res.card_desc
	card_owner_type = order_res.card_owner_type
	quest_part_conditions = order_res.quest_part_conditions
	quest_grade_conditions = order_res.quest_grade_conditions
	quest_family_conditions = order_res.quest_family_conditions
	order_type = order_res.order_type
	reward_amount = order_res.reward_amount
	special_reward = order_res.special_reward
	panel_back.tooltip_text = order_desc
	setup_tooltip()
	
	label_header.text = order_name
	rect_main_img.texture = card_texture


func start_rewarding():
	create_rewards()


func create_rewards():
	if special_reward:
		var special_reward_scene : PackedScene = EntityManager.create_entity_scene(special_reward)
		var reward : Card = special_reward_scene.instantiate()
		GameManager.level.add_child(reward)
		reward.initialize()
		var pos : Vector2 = global_position + Vector2(randi_range(80, 100), randi_range(80, 100)) if randf() < 0.5 else global_position + Vector2(randi_range(-80, -100), randi_range(-80, -100))
		reward.global_position += pos
	PlayerManager.add_gold(reward_amount)
	stack.remove_card(self)
	
	#OrderManager.on_order_completed(self)	# ВЫЗЫВАЕМ МЕНЕДЖЕР
	queue_free()
