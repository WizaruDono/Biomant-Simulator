class_name Card
extends Area2D

signal initialized

@export var intersected_card : Card

@export var card_state : DataManager.CardState: set = _on_state_set
@export var prev_state : DataManager.CardState
@export var stack: Stack

@export var is_dragging : bool

@export var card_type : DataManager.CardType
@export var card_grade : DataManager.EntityGrade
@export var card_cost : int
@export var card_texture : Texture2D
@export var card_owner_type : DataManager.OwnerType
@export var stylebox_tooltip : StyleBoxFlat
@export var font_tooltip : Font

@export var parts : Array[CardActorPart]
@export var production_card: CardProduction
@export var location_card : CardLocation
@export var order_card : CardOrder
@export var is_can_product : bool
@export var is_can_digg : bool
@export var is_can_get_reward : bool

@onready var collision_card: CollisionShape2D = %collision_card
@onready var anim_card: AnimationPlayer = %anim_card
@onready var activate_timer: Timer = %activate_timer
@onready var rect_main_img: TextureRect = %rect_main_img
@onready var label_header: Label = %label_header
@onready var panel_back: PanelContainer = %panel_back
@onready var card_container: Node2D = %CardContainer
@onready var activation_progress: ProgressBar = %activation_progress

var intersected_card_areas: Array[Card]
var is_stack: bool = false: set = _on_is_stack_set
var main_card: Card

var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	card_state = DataManager.CardState.ON_FIELD
	# Вызываем один раз после полной инициализации узла
	call_deferred("set_collision_size")
	
	initialized.connect(_on_initialized)
	panel_back.resized.connect(set_collision_size)

func _on_initialized() -> void:
	set_collision_size()

func set_collision_size() -> void:
	if collision_card.shape == null or panel_back.size == Vector2.ZERO: return
	if collision_card.shape.size == panel_back.size: return
	
	collision_card.shape.size = panel_back.size
	collision_card.position = panel_back.size / 2

func _process(_delta: float) -> void:
	if not activate_timer.is_stopped() and not activate_timer.paused:
		update_progress_bar(activate_timer.wait_time - activate_timer.time_left)
		if not activation_progress.visible:
			activation_progress.show()
	else:
		if activation_progress.visible:
			activation_progress.hide()
	
	queue_redraw()

func setup_tooltip():
	# 🛡️ ЗАЩИТА: Если ресурс не назначен в инспекторе, мы просто выходим!
		if stylebox_tooltip == null:
			print("Предупреждение: для карты ", name, " не задан stylebox_tooltip!")
			return
			
		var new_theme = Theme.new()
		var sb = stylebox_tooltip.duplicate()
		sb.set_content_margin_all(8)
		new_theme.set_stylebox('panel', 'TooltipPanel', sb)
		new_theme.set_font('font', 'TooltipLabel', font_tooltip)
		new_theme.set_font_size('font_size', 'TooltipLabel', 12)
		new_theme.set_color('font_color', 'TooltipLabel', Color(0.125, 0.18, 0.216, 1.0))
		#var stylebox = new_theme.get_theme_stylebox('normal')
		panel_back.theme = new_theme

func _on_state_set(value: DataManager.CardState) -> void:
	if value == card_state: return
	var old_state = card_state
	card_state = value
	_exit_state(old_state)
	_enter_state()

func _enter_state() -> void:
	match card_state:
		DataManager.CardState.APPEARS:
			anim_card.play("appears")
		
		DataManager.CardState.ON_FIELD:
			collision_card.disabled = false
			z_index = 0
			if GameManager.dragged_card == self:
				GameManager.dragged_card = null
		
		DataManager.CardState.DRAGGED:
			intersected_card_areas.clear()
			collision_card.disabled = true
			collision_card.disabled = false
			z_index = 1000
			GameManager.dragged_card = self
		
		DataManager.CardState.HOVER_STACK:
			z_index = 1000
		
		DataManager.CardState.ENTER_STACK:
			if intersected_card:
				intersected_card.add_card_to_stack(self)
		
		DataManager.CardState.IN_STACK, \
		DataManager.CardState.EXIT_STACK, \
		DataManager.CardState.DESTROYED:
			pass

	print("%s %s" % [DataManager.CardState.keys()[card_state], name])

func _exit_state(old_state: DataManager.CardState) -> void:
	match old_state:
		DataManager.CardState.IN_STACK:
			if get_parent() != GameManager.level:
				call_deferred("reparent_to_level")
		DataManager.CardState.DRAGGED:
			if GameManager.dragged_card == self:
				GameManager.dragged_card = null
			
			if intersected_card:
				card_state = DataManager.CardState.ENTER_STACK
			
			# Очищаем пересечения
			intersected_card_areas.clear()
			intersected_card = null
		
		_ : pass

	print("Выход из состояния: %s %s" % [DataManager.CardState.keys()[old_state], name])

func _draw() -> void:
	var font = preload("uid://co45erws16hd7")
	draw_string(font, Vector2.ZERO, str(is_stack), HORIZONTAL_ALIGNMENT_CENTER)

func reparent_to_level() -> void:
	var _level: Level = GameManager.level
	var old_parrent_card: Card = get_parent().get_parent()
	main_card = null
	reparent(_level)
	await get_tree().process_frame
	old_parrent_card._check_is_stack()
	if old_parrent_card.main_card:
		old_parrent_card.main_card.perform_is_stack_action()

func add_card_to_stack(card: Card) -> void:
	if card == null or card == self:
		print("Отмена стака: ", card.name, " и ", name, " не валидная карта")
		return
	
	# Защита от циклической зависимости (карта не может стать родителем своего родителя/потомка)
	if card.is_ancestor_of(self) or self.is_ancestor_of(card):
		print("Отмена стака: ", card.name, " и ", name, " уже в одной иерархии")
		return
		
	if not card_container.get_children().is_empty():
		print("Отмена стака: ", card.name, " и ", name, " в контейнере уже есть карта")
		return
	
	card.reparent(card_container)
	card.position = Vector2(0, label_header.size.y)
	card.card_state = DataManager.CardState.IN_STACK
	card._check_is_stack()
	
	await get_tree().process_frame
	
	if main_card:
		card.main_card = main_card
		main_card.perform_is_stack_action()
	else:
		card.main_card = self
	
	card.z_index = card.get_index()
	is_stack = true

func _check_is_stack() -> void:
	is_stack = !card_container.get_children().is_empty()

func _on_is_stack_set(value: bool) -> void:
	is_stack = value
	perform_is_stack_action()

func perform_is_stack_action() -> void:
	pass

func _physics_process(delta: float) -> void:
	if card_state == DataManager.CardState.DRAGGED:
		global_position = get_global_mouse_position() + drag_offset

func _input(event: InputEvent) -> void:
	if event.is_action_released("left_mouse"):
		if card_state == DataManager.CardState.DRAGGED:
			if GameManager.dragged_card != self:
				return
			
			GameManager.dragged_card = null
			
			print(self.name + ' dropped')
			GameManager.is_captured = false
				
			# Отпускаем объект
			card_state = DataManager.CardState.ON_FIELD
	
	elif event.is_action_pressed("left_mouse"):
		if card_owner_type != DataManager.OwnerType.PLAYER:
			return
	
		if GameManager.is_captured:
			return
		
		if GameManager.hovered_card != self or GameManager.dragged_card:
			return
		
	# === ЗАПРЕТ НА ПЕРЕТАСКИВАНИЕ ДЛЯ КАРТ ЗАКАЗОВ ===
		if card_type == DataManager.CardType.ORDER:
			return # раскомментируй две строки если хочешь активировать запрет
	# ==========================
		
		# Начинаем перетаскивание и запоминаем смещение мыши относительно центра
		GameManager.is_captured = true
		card_state = DataManager.CardState.DRAGGED
		drag_offset = global_position - get_global_mouse_position()

func _on_panel_back_mouse_entered() -> void:
	GameManager.hovered_card = self
	GameManager.is_hovering_card = true
	var tween : Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale",  Vector2(1.05, 1.05), 0.1)

func _on_panel_back_mouse_exited() -> void:
	GameManager.hovered_card = null
	GameManager.is_hovering_card = false
	var tween : Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale",  Vector2(1, 1), 0.1)

func _on_area_entered(area: Area2D) -> void:
	if not area is Card: return
	if card_state != DataManager.CardState.DRAGGED: return
	
	# Защита от дубликатов и от карт внутри нашего же стака
	if card_container.get_children().has(area): return
	if intersected_card_areas.has(area): return
	
	intersected_card_areas.append(area)
	intersected_card = _find_best_target()

func _on_area_exited(area: Area2D) -> void:
	if not area is Card: return
	
	intersected_card_areas.erase(area)
	intersected_card = _find_best_target()

func _find_best_target() -> Card:
	if intersected_card_areas.size() == 1: return intersected_card_areas[0]
		
	var best_card: Card = null
	var min_dist: float = INF
		
	for card in intersected_card_areas:
		# Пропускаем карты, которые уже являются нашими предками или потомками
		if card.is_ancestor_of(self) or self.is_ancestor_of(card): continue
		
		#Пропускаем карты, которые уже собраны в стак (если не хотите стак в стак)
		if card.is_stack: continue
		
		var dist = global_position.distance_to(card.global_position)
		if dist < min_dist:
			min_dist = dist
			best_card = card
				
	return best_card

#region Parts

func check_order_consistency() -> bool:
	var submitted_card = card_container.get_child(0)
	var order : OrderRes = order_card.order_res 
	
# ==========================================
	# ЛОГИКА 1: ЗАКАЗ НА КОНКРЕТНУЮ ЧАСТЬ ТЕЛА
	# ==========================================
	if order.order_type == DataManager.CardType.MONSTER_PART:
		# Если подсунули не часть тела — отказ
		if submitted_card.card_type != DataManager.CardType.MONSTER_PART:
			return false
			
		var part = submitted_card as CardActorPart
		
		# 1. Проверяем тип конечности (например, Голова)
		if order.quest_part_conditions.size() > 0:
			if part.part_type != order.quest_part_conditions[0]:
				return false
				
		# 2. Проверяем базу (например, Скелет)
		# Сначала ищем в массиве баз:
		if order.quest_base_conditions.size() > 0:
			if part.part_res.part_base != order.quest_base_conditions[0]:
				return false
		# Если массив пуст, проверяем одиночную переменную базы:
		elif order.check_base_condition != null:
			if part.part_res.part_base != order.check_base_condition:
				return false
				
		# 3. Проверяем уровень, только если галочка "строгий уровень" включена
		if order.check_entire_monster_grade:
			if part.card_grade != order.quest_grade_conditions:
				return false
				
		return true

# ==========================================
	# ЛОГИКА 2: ЗАКАЗ НА ЦЕЛОГО МОНСТРА (или Франкенштейна)
	# ==========================================
	elif order.order_type == DataManager.CardType.MONSTER:
		# Если подсунули не монстра — отказ
		if submitted_card.card_type != DataManager.CardType.MONSTER:
			return false
			
		var monster = submitted_card
		if monster.monster_parts.size() == 0:
			return false
			
		# 1. Проверка Уровня ВСЕГО монстра (если галочка включена)
		if order.check_entire_monster_grade:
			if monster.card_grade < order.quest_grade_conditions:
				return false
				
		# 2. Собираем особые требования по частям тела в словарь
		# Ключ: Тип конечности (HEAD, L_ARM), Значение: Требуемая база (SKELETON, ZOMBIE)
		var special_parts = {}
		for i in range(order.quest_part_conditions.size()):
			var req_part = order.quest_part_conditions[i]
			var req_base = order.quest_base_conditions[i] # Берем базу из нового массива
			special_parts[req_part] = req_base
			
		# 3. Список всех возможных слотов для проверки
		# Убедись, что тут перечислены все твои части тела из DataManager.MonsterPartType
		var all_part_types = [
			DataManager.MonsterPartType.HEAD,
			DataManager.MonsterPartType.BODY, 
			DataManager.MonsterPartType.L_ARM,
			DataManager.MonsterPartType.R_ARM,
			DataManager.MonsterPartType.L_LEG,
			DataManager.MonsterPartType.R_LEG
		]
		
		# 4. Жесткая проверка каждой конечности
		for part_type in all_part_types:
			var monster_part = monster.get_part_res(part_type)
			
			# Сценарий А: Заказчик выставил специфическое требование на эту часть
			if special_parts.has(part_type):
				if not monster_part:
					return false # Запрошенной части нет на теле
				
				if monster_part.part_base != special_parts[part_type]:
					return false # Пришита деталь не той базы (например, ждали руку зомби, а тут скелет)
					
			# Сценарий Б: Спец-требований нет, проверяем по основной базе монстра
# Сценарий Б: Спец-требований нет, проверяем по основной базе монстра
			else:
				# Если у заказа есть основная база (например, нужен Зомби)
				if order.check_base_condition != null: 
					if not monster_part:
						return false # Не хватает конечности, монстр собран не полностью
						
					if monster_part.part_base != order.check_base_condition:
						return false # Эта часть от другой базы, и спец-заказа на нее не было
						
		return true

	# === ДОБАВЬ ВОТ ЭТУ СТРОКУ ===
	# Срабатывает, если order_type вообще не опознан (страховка от багов)
	return false

#endregion

#region Продукция

# Получить все карты в стаке
func get_all_nested_cards_recursive() -> Array[Card]:
	var result: Array[Card] = []
	if card_container == null: return []
	
	for child in card_container.get_children():
		if child is Card:
			result.append(child)
			result.append_array(child.get_all_nested_cards_recursive())
	
	return result	

# Получить все карты в стаке, которые являются Частями Тела
func get_all_nested_cards_actor_part() -> Array[CardActorPart]:
	var cards: Array[Card] = get_all_nested_cards_recursive()
	var result: Array[CardActorPart] = []
	
	for card in cards:
		if card is CardActorPart:
			result.append(card)
	
	return result

#Получить все части тела
func get_all_nested_parts() -> Array[PartRes]:
	var cards: Array[Card] = get_all_nested_cards_recursive()
	var result: Array[PartRes] = []
	
	for card in cards:
		result.append(card.part_res)
	
	return result

func update_progress_bar(new_value : float):
	activation_progress.value = new_value

#endregion
