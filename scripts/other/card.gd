class_name Card
extends Area2D

signal initialized

@export var intersected_card : Card

@export var card_state : DataManager.CardState: set = _on_state_set
@export var prev_state : DataManager.CardState
@export var stack: Stack

@export var is_dragging : bool

@export var card_type : DataManager.CardType
@export var card_grade : DataManager.EntityGrade: set = _on_card_grade_set
@export var card_cost : int
@export var card_texture : Texture2D
@export var card_owner_type : DataManager.OwnerType
@export var stylebox_tooltip : StyleBoxFlat
@export var font_tooltip : Font

@export var parts : Array[CardActorPart]
@export var production_card: CardProduction
@export var location_card : CardLocation
@export var is_can_product : bool
@export var is_can_digg : bool
@export var is_can_get_reward : bool

@onready var collision_card: CollisionShape2D = %collision_card
@onready var anim_card: AnimationPlayer = %anim_card
@onready var activate_timer: Timer = %activate_timer
@onready var rect_main_img: TextureRect = %rect_main_img
@onready var label_header: Label = %label_header
@onready var panel_back: Button = %panel_back
@onready var card_container: Node2D = %CardContainer
@onready var activation_progress: ProgressBar = %activation_progress
@onready var container_content: VBoxContainer = %container_content

var intersected_card_areas: Array[Card]
var is_stack: bool = false: set = _on_is_stack_set
var main_card: Card

var possibility_stack: bool = true

var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	card_state = DataManager.CardState.ON_FIELD
	# Вызываем один раз после полной инициализации узла
	call_deferred("set_collision_size")
	
	initialized.connect(_on_initialized)
	panel_back.resized.connect(set_collision_size)

func _on_initialized() -> void:
	set_collision_size()

func _on_card_grade_set(value: DataManager.EntityGrade) -> void:
	if not is_node_ready():
		await ready
	
	card_grade = value
	
	match value:
		DataManager.EntityGrade.T1:
			set_color_border( Color(0.125, 0.18, 0.216, 1.0), 2)
		DataManager.EntityGrade.T2:
			set_color_border( Color(0.16, 0.277, 0.8, 1.0), 2)
		DataManager.EntityGrade.T3:
			set_color_border(Color(0.48, 0.0, 0.8, 1.0), 2)
		_:
			set_color_border( Color(0.125, 0.18, 0.216, 1.0), 2)

func set_color_border(_color: Color, width: int = 2):
	# Normal
	var normal_sb = StyleBoxFlat.new()
	normal_sb.border_color = _color
	normal_sb.set_border_width_all(width)
	normal_sb.corner_radius_bottom_left = 8
	normal_sb.corner_radius_bottom_right = 8
	normal_sb.bg_color = Color(0.843, 0.71, 0.58, 1.0)
	normal_sb.shadow_color = Color(0.129, 0.184, 0.22, 0.588)
	normal_sb.shadow_size = 4
	panel_back.add_theme_stylebox_override("normal", normal_sb)

	# Hover
	var hover_sb = StyleBoxFlat.new()
	hover_sb.border_color = _color
	hover_sb.set_border_width_all(width)
	hover_sb.corner_radius_bottom_left = 8
	hover_sb.corner_radius_bottom_right = 8
	hover_sb.bg_color = Color(0.843, 0.71, 0.58, 1.0)
	hover_sb.shadow_color = Color(0.129, 0.184, 0.22, 0.588)
	hover_sb.shadow_size = 8
	panel_back.add_theme_stylebox_override("hover", hover_sb)
	
	# Pressed
	panel_back.add_theme_stylebox_override("pressed", hover_sb)

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
			
			SoundManager.play_asmr_sfx(SoundManager.FLESH_POP, -20.0)
		
		DataManager.CardState.HOVER_STACK:
			z_index = 1000
		
		DataManager.CardState.ENTER_STACK:
			if intersected_card:
				if intersected_card.possibility_stack and intersected_card.card_owner_type == DataManager.OwnerType.PLAYER:
					intersected_card.add_card_to_stack(self)
				else:
					card_state = DataManager.CardState.ON_FIELD
					_move_card_away(self)
		
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
				if intersected_card.possibility_stack and intersected_card.card_owner_type == DataManager.OwnerType.PLAYER:
					card_state = DataManager.CardState.ENTER_STACK
				else:
					_move_card_away(intersected_card)
			else:
				SoundManager.play_asmr_sfx(SoundManager.FLESH_POP, -20.0)
				
			
			# Очищаем пересечения
			intersected_card_areas.clear()
			intersected_card = null
			
		_ : pass

	print("Выход из состояния: %s %s" % [DataManager.CardState.keys()[old_state], name])

# Для дебага
func _draw() -> void:
	return
	var font = preload("uid://co45erws16hd7")
	draw_string(font, Vector2.ZERO, str("state: ",card_state), HORIZONTAL_ALIGNMENT_CENTER)

func reparent_to_level() -> void:
	var _level: Level = GameManager.level
	var old_parrent_card: Card = get_parent().get_parent()
	main_card = null
	reparent(_level)
	await get_tree().process_frame
	old_parrent_card._check_is_stack()
	if old_parrent_card.main_card:
		old_parrent_card.main_card._check_is_stack()

func add_card_to_stack(card: Card) -> void:
	if not possibility_stack:
		return
	
	if not CardRuleManager.can_stack(self, card): 
		_move_card_away(card)
		return

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
	
	SoundManager.play_asmr_sfx(SoundManager.SND_STACK, -12.0)	# ЗВУК СТАКА
	
	await get_tree().process_frame
	
	card.position = Vector2(0, label_header.size.y)
	card.card_state = DataManager.CardState.IN_STACK
	
	if main_card:
		card.main_card = main_card
	else:
		card.main_card = self
	
	card.main_card._check_is_stack()
	
	if card.main_card != self:
		_check_is_stack()
	
	card.z_index = card.get_index()

func _check_is_stack() -> void:
	is_stack = !card_container.get_children().is_empty()

func _on_is_stack_set(value: bool) -> void:
	is_stack = value
	
	await get_tree().process_frame
	perform_is_stack_action()

# Виртуальный метод, выполняется, чтобы выполнить действия после склеивания / отклеивания карт
func perform_is_stack_action() -> void:
	pass

func _physics_process(delta: float) -> void:
	if card_state == DataManager.CardState.DRAGGED:
		global_position = get_global_mouse_position() + drag_offset

func _on_panel_back_button_down() -> void:
	pass # Replace with function body.

func _on_panel_back_button_up() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event.is_action_released("left_mouse"):
		_process_released_left_mouse()
	elif event.is_action_pressed("left_mouse"):
		_process_pressed_left_mouse()
	elif event.is_action_pressed("right_mouse"):
		_process_pressed_right_mouse()

func _process_released_left_mouse():
	if card_state == DataManager.CardState.DRAGGED:
		if GameManager.dragged_card != self:
			return
		
		GameManager.dragged_card = null
		
		print(self.name + ' dropped')
		GameManager.is_captured = false
			
		# Отпускаем объект
		card_state = DataManager.CardState.ON_FIELD
	pass

func _process_pressed_left_mouse():
	if card_owner_type != DataManager.OwnerType.PLAYER: return
	if GameManager.is_captured: return
	if GameManager.hovered_card != self or GameManager.dragged_card: return
	if CardRuleManager.forbidden_to_be_moved(self): return
	
	# Начинаем перетаскивание и запоминаем смещение мыши относительно центра
	GameManager.is_captured = true
	card_state = DataManager.CardState.DRAGGED
	drag_offset = global_position - get_global_mouse_position()
	pass

## Центрироваться на карте
func _process_pressed_right_mouse():
	if GameManager.hovered_card != self: return
	## Anchor на картах стоит в левом верхнем углу, поэтому вычисляем центр карты
	SignalManager.card_focused.emit(global_position + container_content.size / 2)
	pass

func _on_panel_back_mouse_entered() -> void:
	GameManager.hovered_card = self
	GameManager.is_hovering_card = true
	var tween : Tween = create_tween()
	tween.tween_property(self, "scale",  Vector2(1.05, 1.05), 0.1)

func _on_panel_back_mouse_exited() -> void:
	GameManager.hovered_card = null
	GameManager.is_hovering_card = false
	var tween : Tween = create_tween()
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

#region Заказы



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

func _on_container_content_resized() -> void:
	if not is_node_ready():
		await ready
	
	panel_back.size.y = container_content.size.y


func _move_card_away(moving_card: Card):
	var jump_distance: float = 164.0
	var random_direction = Vector2.from_angle(randf() * TAU)
	var target_pos: Vector2 = moving_card.global_position + (random_direction * jump_distance)

	# Было бы супер повернуть откидываемую карту вокруг своей оси, но пивот у неё в углу, 
	# и это выглядит ужасно. Поправить у меня не получилось.
	#var target_rotation = moving_card.rotation + TAU

	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(moving_card, "global_position", target_pos, 0.3).set_trans(Tween.TRANS_BACK)
	#tween.tween_property(moving_card, "rotation", target_rotation, 0.3).set_trans(Tween.TRANS_SINE)
	pass
