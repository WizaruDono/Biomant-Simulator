class_name OrderManager
extends Node

@export var main_possible_orders_by_rate: PossibleOrdersByRate
@export var base_number_of_orders: int = 3

var active_orders : Array[Card] = []
var start_position = Vector2(640, 32) 
var offset_y = 192 # ВЗЯТЬ ПОТОМ ПРОГРАММНО высоту карты 
var offset_x = 192 # ВЗЯТЬ ПОТОМ ПРОГРАММНО высоту карты 

var reroll_btn_scene = preload("res://scenes/reroll_button.tscn")
var current_reroll_btn : Node2D = null

var rate: int: set = _on_rate_set

var number_of_orders: int

var deck: Array[OrderRes]: set = _on_deck_set
var draw_pile: Array[OrderRes]: set = _on_draw_pile_set
var discard_pile: Array[OrderRes]

func _on_rate_set(value: int) -> void:
	rate = value
	
	base_number_of_orders = roundi(StatCalculator.get_soft_squared_value(base_number_of_orders, value, 0.5))
	
	create_deck()

func _on_deck_set(value: Array[OrderRes]) -> void:
	deck = value.duplicate()
	deck.shuffle()
	draw_pile = deck

func _on_draw_pile_set(value: Array[OrderRes]) -> void:
	draw_pile = value.duplicate()
	
	create_order()

func create_deck() -> void:
	if not deck.is_empty(): deck.clear()
	if not draw_pile.is_empty(): draw_pile.clear()
	if not discard_pile.is_empty(): discard_pile.clear()
	
	var _possible_orders: PossibleOrders = _get_possible_orders_to_rate(rate, main_possible_orders_by_rate)
	deck = _possible_orders.orders
	print(deck)

func _get_possible_orders_to_rate(_rate: int, _possible_orders_by_rate: PossibleOrdersByRate) -> PossibleOrders:
	var target_rate: int = clampi(_rate, 0, _possible_orders_by_rate.orders_by_rate.size())
	var result: PossibleOrders = _possible_orders_by_rate.orders_by_rate.duplicate()[target_rate]
	return result

func create_order() -> void:
	var order_res = draw_pile.pop_front().duplicate(true)
	order_res.card_owner_type = DataManager.OwnerType.PLAYER
	
	var order_node: Card = EntityManager.create_entity_scene(order_res)
	GameManager.level.player_loot.add_child(order_node)
	order_node.initialize()
	
	# Ставим заказ на позицию в коллоде
	set_order_pos(order_node)
	
	active_orders.append(order_node)
	
	%order_spawn_timer.start(2.0)

func _on_order_spawn_timer_timeout() -> void:
	if draw_pile.is_empty(): return
	create_order()

func set_orders_pos() -> void:
	var pos: Vector2 = start_position
	for loot in GameManager.level.player_loot.get_children():
		if loot is CardOrder:
			if loot.position != Vector2.ZERO: continue
			loot.global_position = start_position
			var tween: Tween = create_tween()
			tween.tween_property(loot, "global_position", pos, 0.2)
			pos.y += loot.panel_back.size.y / 1.5

func set_order_pos(order: CardOrder) -> void:
	# Собираем все карты заказов в контейнере
	var orders: Array[CardOrder] = []
	for child in GameManager.level.player_loot.get_children():
		if child is CardOrder:
			orders.append(child as CardOrder)
			
	if orders.is_empty(): return
	
	var spacing = 8.0
	var total_width = 0.0
	for card in orders:
		total_width += card.panel_back.size.x
	total_width += spacing * max(0, orders.size() - 1)
	
	# Находим стартовую X, чтобы вся группа была строго по центру
	var center_x = 1920.0 / 2.0
	var current_x = center_x - total_width / 2.0
	var base_y = orders[0].position.y # Сохраняем общую Y-координату
	
	# Анимируем ВСЕ карты одновременно
	var tween = create_tween().set_parallel()
	for card in orders:
		var target_pos = Vector2(current_x, base_y)
		tween.tween_property(card, "position", target_pos, 0.2)
		current_x += card.panel_back.size.x + spacing

# Спавнит 3 случайных заказа из пула
func spawn_3_random_orders():
	# Очищаем старые, если они были
	clear_current_orders()
	var pool = DataManager.all_possible_orders.duplicate()
	if pool.is_empty(): return
	pool.shuffle() # Перемешиваем
	# Берем максимум 3 штуки
	var count = min(3, pool.size())
	for i in range(count):
		var order_res = pool[i].duplicate(true)
		order_res.card_owner_type = DataManager.OwnerType.PLAYER
		
		var order_node: Card = EntityManager.create_entity_scene(order_res)
		GameManager.level.player_loot.add_child(order_node)
		order_node.initialize()
		
		# Фиксированная позиция слева
		order_node.global_position = start_position + Vector2(0, i * (offset_y+15))
		
		active_orders.append(order_node)
		
	# === СПАВНИМ КНОПКУ ПОД ЗАКАЗАМИ ===
	if current_reroll_btn == null or not is_instance_valid(current_reroll_btn):
		current_reroll_btn = reroll_btn_scene.instantiate()
		GameManager.level.player_loot.add_child(current_reroll_btn)
		# Передаем цену и команду "вызови spawn_3_random_orders снова"
		current_reroll_btn.setup(DataManager.order_reroll_cost, Callable(self, "spawn_3_random_orders"))
	# Сдвигаем кнопку под последнюю карту
	current_reroll_btn.global_position = start_position + Vector2(0, count * (offset_y + 15))

# Функция для кнопки реролла или автообновления
func clear_current_orders():
	for order in active_orders:
		if is_instance_valid(order):
			order.queue_free()
	active_orders.clear()

# Эту функцию надо вызывать, когда игрок успешно сдает заказ (в card_order.gd)
func on_order_completed(completed_order: Card):
	if active_orders.has(completed_order):
		active_orders.erase(completed_order)
		
	# Если на столе не осталось заказов — обновляем бесплатно!
	if active_orders.is_empty():
		spawn_3_random_orders()
