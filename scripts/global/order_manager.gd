extends Node

var active_orders : Array[Card] = []
var start_position = Vector2(20, 20) 
var offset_y = 192 # ВЗЯТЬ ПОТОМ ПРОГРАММНО высоту карты 

var reroll_btn_scene = preload("res://scenes/reroll_button.tscn")
var current_reroll_btn : Node2D = null

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
		
		var scene : PackedScene = EntityManager.create_entity_scene(order_res)
		var order_node : Card = scene.instantiate()
		
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
