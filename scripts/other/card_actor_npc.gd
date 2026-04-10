extends CardActor

class_name CardActorNPC


@export var card_upgrade_scene: PackedScene = preload("uid://caoqrrojhtbwk")
@export var lot_scene : PackedScene = preload("res://scenes/shop_lot.tscn")
@export var npc_res : NPCRes
@export var npc_type : DataManager.NPCType
@export var npc_quest_name : String
@export var npc_quest_desc : String
@export var replics : Array[String]
@export var quest_part_conditions : Array[DataManager.MonsterPartType]
@export var quest_grade_conditions : DataManager.EntityGrade
@export var quest_family_conditions : Array[DataManager.MonsterFamily]
@export var npc_shop_content : Array[CardRes]
@export var ncp_shop_lots_count : int
@export var npc_mood : DataManager.OwnerType
@export var npc_wait_timer : float
@export var lots : Array[Card]
@export var lots_offset : float = 20
var active_buttons : Array[ShopLot] = []	# для удаления кнопок использованных
# Для спавна кнопки рерола:
var reroll_btn_scene = preload("res://scenes/reroll_button.tscn")
var current_reroll_btn : Node2D = null



func initialize():
	await get_tree().process_frame
	SignalManager.on_buy_lot.connect(buy_lot)
	card_owner_type = npc_res.card_owner_type
	card_cost = npc_res.card_cost
	npc_type = npc_res.npc_type
	actor_name = npc_res.card_name
	actor_desc = npc_res.card_desc
	actor_damage = npc_res.actor_damage
	actor_health = npc_res.actor_health
	card_texture = npc_res.card_texture
	npc_quest_name = npc_res.npc_quest_name 
	npc_quest_desc = npc_res.npc_quest_desc 
	replics = npc_res.replics 
	quest_part_conditions = npc_res.quest_part_conditions 
	quest_grade_conditions = npc_res.quest_grade_conditions 
	quest_family_conditions = npc_res.quest_family_conditions 
	npc_shop_content = npc_res.npc_shop_content 
	ncp_shop_lots_count = npc_res.ncp_shop_lots_count 
	npc_mood = npc_res.npc_mood 
	npc_wait_timer = npc_res.npc_wait_timer 
	
	label_header.text = actor_name
	rect_main_img.texture = card_texture
	#panel_back.tooltip_text = actor_desc
	label_damage.text = str(actor_damage)
	label_health.text = str(actor_health)
	setup_tooltip()
	set_tooltip_text(actor_desc)
	activate()


func activate():
	match npc_type:
		DataManager.NPCType.TRADER:
			create_shop()


func create_shop():
	# Очищаем старые лоты (карты)
	for lot in lots:
		if is_instance_valid(lot): lot.queue_free()
	lots.clear()
	
	# Очищаем старые кнопки ценников
	for btn in active_buttons:
		if is_instance_valid(btn): btn.queue_free()
	active_buttons.clear()
	
	if not npc_res or npc_res.npc_shop_content.is_empty():
		return
		
	# Берем копию товаров из ресурса
	var pool = npc_res.npc_shop_content.duplicate()
	pool = pool.filter(func(res): return res != null)
	
	if pool.is_empty():
		print("Ошибка: У торговца нет доступных товаров!")
		return
	
	# Спавним ровно 3 товара
	for i in range(3):
		var selected_res : CardRes
		var roll = randf()
		
		var chance_1: float = DataManager.chance_production_from_trader
		var chance_2: float = DataManager.chance_location_from_trader
		# 1. Шанс 10% на продукцию (Обменники)
		if roll <= chance_1:
			var productions = pool.filter(func(res): return res.card_type == DataManager.CardType.PRODUCTION)
			if not productions.is_empty():
				selected_res = productions.pick_random()
				
		# 2. Шанс 25% на локацию (если продукция не выпала)
		if selected_res == null and roll <= (chance_1 + chance_2): # 0.10 + 0.25 = 0.35
			var locations = pool.filter(func(res): return res.card_type == DataManager.CardType.LOCATION)
			if not locations.is_empty():
				selected_res = locations.pick_random()
				
		# 3. Если ничего по шансам не выпало — берем абсолютно рандомный товар
		if selected_res == null:
			selected_res = pool.pick_random()
			
		if selected_res == null: 
			continue
			
		var copy_res : CardRes = selected_res.duplicate(true)
		copy_res.card_owner_type = DataManager.OwnerType.NEUTRAL
		
		var lot: Card = EntityManager.create_entity_scene(copy_res)
		
		if lot == null:
			lot = card_upgrade_scene.instantiate()
			#lot.upgrade_res = copy_res 	# ЭТА СТРОЧКА ИСПРАВЛЯЕТ БАГ: если добавлена на продажу карта нового типа игра не должна крашится
		
		GameManager.level.add_child(lot)
		lot.possibility_stack = false
		
		lot.initialize()
		
		lots.append(lot)
		
	align_lots()

func align_lots():
	if lots.is_empty(): return
	
	var lot: Card = lots[0]
	var card_width = lot.panel_back.size.x
	var start_x = global_position.x - ((lots.size() - 1) * (card_width + lots_offset)) / 2
	var start_y = global_position.y + 270 
	
	for i in range(lots.size()):
		# код позиционирования товаров
		lot = lots[i]
		# Фиксированная позиция для каждого товара в ряд
		lot.global_position = Vector2(start_x + i * (card_width + lots_offset), start_y)
		
		# Создаем ценник
		var shop_lot : ShopLot = lot_scene.instantiate()
		GameManager.level.add_child(shop_lot)
		shop_lot.set_lot(lot)
		shop_lot.initialize()
		
		# Заносим кнопки в массив для дальнейшего удаления
		active_buttons.append(shop_lot)
		
	# Кнопка обновления товаров
	if current_reroll_btn == null or not is_instance_valid(current_reroll_btn):
		current_reroll_btn = reroll_btn_scene.instantiate()
		GameManager.level.add_child(current_reroll_btn)
		current_reroll_btn.setup(DataManager.shop_reroll_cost, Callable(self, "create_shop"))
		
	# Ставим кнопку чуть правее последнего товара
	current_reroll_btn.global_position = Vector2(start_x + lots.size() * (card_width + lots_offset), start_y)


func buy_lot(lot : Card):
	if npc_type != DataManager.NPCType.TRADER: return
	if not lots.has(lot): return
	
	lot._move_card_away_down(lot)
	lot.card_owner_type = DataManager.OwnerType.PLAYER
	lot.possibility_stack = true
	lots.erase(lot)
	
	# Если товары кончились:
	if lots.size() == 0:
		if replics.size() > 0:
			var random_replic = replics[randi() % replics.size()]
			print(actor_name + ": " + random_replic) # Вывод реплики в консоль
		else:
			print(actor_name + ": Спасибо за покупки!")
		
		create_shop()	# === АВТООБНОВЛЕНИЕ ТОВАРОВ ===
		# queue_free() УДАЛЕН. Торговец остается стоять на месте.
