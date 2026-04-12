extends Node2D

var action_callable : Callable
var cost : int = 0
@onready var btn = $Button 

func setup(price: int, action: Callable):
	cost = price
	action_callable = action
	
	# Сделаем проверку безопасной
	if not is_node_ready(): await ready
	
	if cost > 0:
		btn.text = "Обновить (" + str(cost) + "$)"
	else:
		btn.text = "Обновить (Бесплатно)"

func _on_button_pressed():
	# Если бесплатно (cost=0) или у игрока хватает денег
	if cost == 0 or PlayerManager.check_gold(cost):
		SoundManager.play_asmr_sfx(SoundManager.SND_REROLL, -8.0)	# ЗВУК ПЕРЕТАСОВКИ
		
		if cost > 0:
			SignalManager.on_spend_gold.emit(cost)
			
		if action_callable.is_valid():
			action_callable.call()
	else:
		# Визуальный фидбек при нехватке денег
		var original_color = btn.modulate
		btn.modulate = Color(1, 0, 0) 
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(btn):
			btn.modulate = original_color
