extends Area2D
class_name Card

@export var stack_scene : PackedScene
@export var is_dragging : bool
@export var stack : Stack
@export var intersected_card : Card
@export var is_in_stack : bool
@export var card_state : DataManager.CardState
@export var prev_state : DataManager.CardState
@export var offset : Vector2 = Vector2.ZERO
@export var prev_z_index : int
@export var card_type : DataManager.CardType
@export var card_grade : DataManager.EntityGrade
@export var card_cost : int
@export var card_texture : Texture2D
@export var card_owner_type : DataManager.OwnerType
@export var stylebox_tooltip : StyleBoxFlat
@export var font_tooltip : Font
@export var intersected_areas : Array[Card]

@onready var collision_card: CollisionShape2D = %collision_card
@onready var anim_card: AnimationPlayer = %anim_card
@onready var activate_timer: Timer = %activate_timer
@onready var rect_main_img: TextureRect = %rect_main_img
@onready var label_header: Label = %label_header
@onready var panel_back: PanelContainer = %panel_back


func _ready() -> void:
	change_state(DataManager.CardState.APPEARS)


func setup_tooltip():
	# 🛡️ ЗАЩИТА: Если ресурс не назначен в инспекторе, мы просто выходим!
		if stylebox_tooltip == null:
			print("Предупреждение: для карты ", name, " не задан stylebox_tooltip!")
			return
			
		var new_theme = Theme.new()
		var sb = stylebox_tooltip.duplicate()
		sb.set_content_margin_all(10)
		new_theme.set_stylebox('panel', 'TooltipPanel', sb)
		new_theme.set_font('font', 'TooltipLabel', font_tooltip)
		new_theme.set_font_size('font_size', 'TooltipLabel', 8)
		new_theme.set_color('font_color', 'TooltipLabel', Color8(52, 28, 39, 255))
		#var stylebox = new_theme.get_theme_stylebox('normal')
		panel_back.theme = new_theme

func change_state(new_state : DataManager.CardState):
	prev_state = card_state
	card_state = new_state
	match card_state:
		DataManager.CardState.APPEARS:
			anim_card.play('appears')
		DataManager.CardState.ON_FIELD:
			change_collision_to_stacked_state()
			input_pickable = true
		DataManager.CardState.DRAGGED:
			if prev_state == DataManager.CardState.IN_STACK and not (stack and stack.is_dragging):
				if stack and is_instance_valid(stack):
					stack.remove_card(self)
					#stack.calculate()
					is_in_stack = false
			change_collision_to_dragged_state()
			z_index = 100
		DataManager.CardState.HOVER_STACK:
			pass
		DataManager.CardState.ENTER_STACK:
			if prev_state == DataManager.CardState.HOVER_STACK:
				intersected_card = get_closest_card(intersected_areas)
				stack = intersected_card.stack
			change_collision_to_stacked_state()
			enter_to_stack()
		DataManager.CardState.IN_STACK:
			is_in_stack = true
			change_collision_to_invisible_state()
			stack.calculate()
		DataManager.CardState.EXIT_STACK:
			pass
		DataManager.CardState.DESTROYED:
			pass
	print(DataManager.CardState.keys()[card_state] + ' ' + self.name)


func get_closest_card(cards : Array[Card]):
	if cards.size() == 0:
		return null
	if cards.size() == 1:
		return cards[0]
	cards.sort_custom(func(a: Card, b: Card): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	return cards[0]


func drop_card():
	if card_state == DataManager.CardState.HOVER_STACK:
		change_state(DataManager.CardState.ENTER_STACK)
	else:
		change_state(DataManager.CardState.ON_FIELD)
		z_index = DataManager.default_z_index


func _on_area_entered(area: Area2D) -> void:
	# здесь добавить чек на стак, если будут баги
	if card_state != DataManager.CardState.HOVER_STACK and card_state != DataManager.CardState.DRAGGED:
		return
	var card : Card = area
	if card.card_owner_type != DataManager.OwnerType.PLAYER:
		return
	if not intersected_areas.has(card):
		intersected_areas.append(card)
	change_state(DataManager.CardState.HOVER_STACK)
	#if not stack:
		#stack = card.stack


func _on_area_exited(area: Area2D) -> void:
	if card_state == DataManager.CardState.ENTER_STACK:
		return
	var card : Card = area
	if intersected_areas.has(card):
		intersected_areas.erase(card)
	# здесь ошибка
	if not is_in_stack:
		stack = null
	if intersected_areas.size() == 0:
		change_state(DataManager.CardState.DRAGGED)


func make_card_stacked():
	is_in_stack = true
	change_collision_to_stacked_state()


func make_card_unstacked():
	is_in_stack = false
	change_collision_to_dragged_state()


func change_collision_to_stacked_state():
	# кто проверяет?
	set_collision_layer_value(2, true)
	set_collision_mask_value(2, false)


func change_collision_to_dragged_state():
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, true)


func change_collision_to_invisible_state():
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)
	
	
func enter_to_stack():
	if not stack or not is_instance_valid(stack):
		create_stack()
	else:
		stack.add_card(self)


func _on_anim_card_animation_finished(anim_name: StringName) -> void:
	pass
	#match anim_name:
		#'appears':
			#change_state(DataManager.CardState.ON_FIELD)


#func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	#if card_state == DataManager.CardState.APPEARS or card_state == DataManager.CardState.ENTER_STACK:
		#return
	## Проверяем, нажата ли левая кнопка мыши
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#print('dragged')
			#is_dragging = event.pressed
			#if not is_dragging:
				#check_drop()
			#else:
				#change_state(DataManager.CardState.DRAGGED)
	#
	## Если мышь движется и мы "тащим" карту
	#elif event is InputEventMouseMotion and is_dragging:
		## Перемещаем карту на величину движения мыши
		#position += event.relative

func _on_input_event(_viewport, event, _shape_idx):
	if card_owner_type != DataManager.OwnerType.PLAYER:
		return
	if GameManager.is_captured:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
		# === ЗАПРЕТ НА ПЕРЕТАСКИВАНИЕ ДЛЯ КАРТ ЗАКАЗОВ ===
			if card_type == DataManager.CardType.ORDER:
				return # раскомментируй две строки если хочешь активировать запрет
		# ==========================
			# Начинаем перетаскивание и запоминаем смещение мыши относительно центра
			GameManager.is_captured = true
			change_state(DataManager.CardState.DRAGGED)
			is_dragging = true
			offset = global_position - get_global_mouse_position()
		else:
			# Отпускаем объект
			if card_state == DataManager.CardState.DRAGGED or card_state == DataManager.CardState.HOVER_STACK:
				print(self.name + ' dropped')
				is_dragging = false
				GameManager.is_captured = false
				drop_card()


func _input(event):
	if is_dragging and event is InputEventMouseMotion:
		# Обновляем позицию объекта с учетом смещения
		global_position = get_global_mouse_position() + offset
	
	# Страховка: если кнопка мыши отпущена за пределами Area2D
	# здесь багованная история
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if card_state == DataManager.CardState.DRAGGED or card_state == DataManager.CardState.HOVER_STACK:
			is_dragging = false
			GameManager.is_captured = false
			#drop_card()


func create_stack():
	print('create stack working')
	stack = stack_scene.instantiate()
	GameManager.level.add_child(stack)
	stack.global_position = intersected_card.global_position
	intersected_card.input_pickable = false
	self.input_pickable = false
	intersected_card.stack = stack
	# здесь цимес
	intersected_card.change_state(DataManager.CardState.ENTER_STACK)
	stack.add_card(self)
	intersected_areas.clear()
	intersected_card = null


func merge_stacks():
	# значит у нас уже стек
	# если у карты пересечения есть стек
	var copy_stack : Stack = stack
	for card in stack.cards: 
		intersected_card.stack.add_card(card)
	copy_stack.queue_free()



func get_size():
	return collision_card.shape.size


func _on_mouse_entered() -> void:
	if card_state == DataManager.CardState.ON_FIELD:
		var tween : Tween = create_tween().set_parallel()
		tween.tween_property(self, "scale",  Vector2(1.05, 1.05), 0.1)
		#tween.tween_callback(_on_mouse_exited).set_delay(3)


func _on_mouse_exited() -> void:
	var tween : Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale",  Vector2(1, 1), 0.1)
