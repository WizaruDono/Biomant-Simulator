extends CardActor

class_name CardActorMonster


@export var monster_res : MonsterRes
@export var monster_perc : DataManager.PercType
@export var monster_parts : Array[PartRes]
@export var is_can_love : bool = true

@onready var sprite_container: Node2D = %sprite_container
@onready var sprite_rig: Node2D = %sprite_rig
@onready var sprite_head: Sprite2D = %sprite_head
@onready var sprite_body: Sprite2D = %sprite_body
@onready var sprite_l_arm: Sprite2D = %sprite_l_arm
@onready var sprite_r_arm: Sprite2D = %sprite_r_arm
@onready var sprite_l_leg: Sprite2D = %sprite_l_leg
@onready var sprite_r_leg: Sprite2D = %sprite_r_leg

# === НОВОЕ: Вспомогательная функция для поиска нужной части ===
func get_part_res(type: DataManager.MonsterPartType) -> PartRes:
	for part in monster_parts:
		if part != null and part.part_type == type:
			return part
	return null



func initialize():
	await get_tree().process_frame
	card_type = monster_res.card_type
	card_owner_type = monster_res.card_owner_type
	card_texture = monster_res.card_texture
	card_grade = monster_res.card_grade
	card_cost = monster_res.card_cost
	actor_name = monster_res.card_name
	actor_desc = monster_res.card_desc
	actor_health = monster_res.actor_health
	actor_damage = monster_res.actor_damage
	card_texture = monster_res.card_texture
	monster_parts = monster_res.monster_parts
	monster_perc = monster_res.monster_perc
	#panel_back.tooltip_text = actor_desc
	setup_tooltip()
	set_tooltip_text(actor_desc)
	
	label_header.text = actor_name
	rect_main_img.texture = card_texture
	label_damage.text = str(actor_damage)
	label_health.text = str(actor_health)
	# собираем монстра
	'''
	sprite_body.texture = monster_res.monster_body_texture
	sprite_head.texture = monster_res.monster_head_texture
	sprite_l_arm.texture = monster_res.monster_L_arm_texture
	sprite_r_arm.texture = monster_res.monster_R_arm_texture
	sprite_l_leg.texture = monster_res.monster_L_leg_texture
	sprite_r_leg.texture = monster_res.monster_R_leg_texture

# === НОВОЕ: Логика сборки по маркерам ===
	# 1. Получаем ресурс тела, чтобы узнать его базу (например, ZOMBIE)
	var body_part = get_part_res(DataManager.MonsterPartType.BODY)
	
	if body_part:
		# переменная в part_res.gd - part_base 
		var body_base = body_part.part_base 

		# 2. Создаем список: [Тип, Имя маркера в дереве, Сам спрайт]
		var joints_setup = [
			[DataManager.MonsterPartType.HEAD, "Join_Head", sprite_head],
			[DataManager.MonsterPartType.L_ARM, "Join_L_Arm", sprite_l_arm],
			[DataManager.MonsterPartType.R_ARM, "Join_R_Arm", sprite_r_arm],
			[DataManager.MonsterPartType.L_LEG, "Join_L_Leg", sprite_l_leg],
			[DataManager.MonsterPartType.R_LEG, "Join_R_Leg", sprite_r_leg]
		]
#
		# 3. Расставляем конечности
		for setup in joints_setup:
			var p_type = setup[0]
			var marker_node_name = setup[1]
			var sprite = setup[2]
			
			# Находим маркер внутри тела (так как у маркеров нет %, но это можно "исправить")
			var marker = sprite_body.get_node_or_null(marker_node_name)
			var limb_part = get_part_res(p_type)
			
			if limb_part and marker and sprite:
				# Двигаем МАРКЕР на точку крепления текущего ТЕЛА
				marker.position = DataManager.get_joint_pos(body_base, p_type)
				
				# Сдвигаем СПРАЙТ конечности на её родной оффсет
				var limb_base = limb_part.part_base
				sprite.offset = -DataManager.get_joint_pos(limb_base, p_type)
	# ==============================================================
	
	initialized.emit()
	
			if limb_part and marker and sprite:
			# Ставим маркер в нужную точку на теле
			marker.position = DataManager.get_joint_pos(body_base, p_type)
			
			# ТАК КАК спрайт теперь не ребенок маркера, а сосед тела:
			# Его позиция = позиция тела + позиция маркера
			sprite.position = sprite_body.position + marker.position
			
			# Сдвигаем спрайт на его родной оффсет
			var limb_base = limb_part.part_base
			sprite.offset = -DataManager.get_joint_pos(limb_base, p_type)
	'''


	# 1. Назначаем текстуры всем (и телу тоже)
	sprite_body.texture = monster_res.monster_body_texture
	sprite_head.texture = monster_res.monster_head_texture
	sprite_l_arm.texture = monster_res.monster_L_arm_texture
	sprite_r_arm.texture = monster_res.monster_R_arm_texture
	sprite_l_leg.texture = monster_res.monster_L_leg_texture
	sprite_r_leg.texture = monster_res.monster_R_leg_texture

	var body_part = get_part_res(DataManager.MonsterPartType.BODY)
	if not body_part: return
	var body_base = body_part.part_base 

	# 2. Список для расстановки. ТЕЛО тут не нужно двигать через цикл, 
	# оно — наша точка отсчета.
	var joints_setup = [
		[DataManager.MonsterPartType.HEAD, "Join_Head", sprite_head],
		[DataManager.MonsterPartType.L_ARM, "Join_L_Arm", sprite_l_arm],
		[DataManager.MonsterPartType.R_ARM, "Join_R_Arm", sprite_r_arm],
		[DataManager.MonsterPartType.L_LEG, "Join_L_Leg", sprite_l_leg],
		[DataManager.MonsterPartType.R_LEG, "Join_R_Leg", sprite_r_leg]
	]

	# Центрируем скелет и само тело в контейнере (обычно это центр карты)
	# Если sprite_conteiner в центре, то ставим в 0,0
	sprite_rig.position = Vector2.ZERO 
	sprite_body.position = Vector2.ZERO 

	for setup in joints_setup:
		var p_type = setup[0]
		var marker_name = setup[1]
		var limb_sprite = setup[2]
		
		var marker = sprite_rig.get_node_or_null(marker_name)
		var limb_part = get_part_res(p_type)
		
		if limb_part and marker and limb_sprite:
			# Двигаем маркер (невидимую точку)
			marker.position = DataManager.get_joint_pos(body_base, p_type)
			
			# Приравниваем позицию спрайта к позиции маркера
			# Теперь рука будет находиться ровно там, где маркер
			limb_sprite.position = marker.position
			
			# Применяем оффсет самой конечности
			var limb_base = limb_part.part_base
			limb_sprite.offset = -DataManager.get_joint_pos(limb_base, p_type)

	# 3. УПРАВЛЯЕМ СЛОЯМИ (Tree Order)
	# Кто ниже в списке — тот рисуется ПОВЕРХ остальных.
	var container = sprite_body.get_parent()
	container.move_child(sprite_l_arm, 0)  # Самый задний
	container.move_child(sprite_l_leg, 1)
	container.move_child(sprite_r_leg, 2)
	container.move_child(sprite_body, 3)   # Тело посередине
	container.move_child(sprite_head, 4)
	container.move_child(sprite_r_arm, 5)  # Самый передний

	# 4. ОБНУЛЯЕМ Z-INDEX (Критически важно!)
	# Теперь всё на одном слое карты, и они не будут протыкать соседние карты.
	for s in [sprite_body, sprite_head, sprite_l_arm, sprite_r_arm, sprite_l_leg, sprite_r_leg]:
		s.z_index = 0
		s.z_as_relative = true

	initialized.emit()
