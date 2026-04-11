extends Node2D

var action_callable : Callable
var cost : int = 0
@onready var btn = $Button # Убедись, что путь до кнопки правильный

func setup(price: int, action: Callable):
	cost = price
	action_callable = action
	if cost > 0:
		btn.text = "Обновить (" + str(cost) + "$)"
	else:
		btn.text = "Обновить (Бесплатно)"

func _on_button_pressed():
	if PlayerManager.check_gold(cost):
		SoundManager.play_asmr_sfx(SoundManager.SND_REROLL, -8.0)	# ЗВУК ПЕРЕТАСОВКИ
		SignalManager.on_spend_gold.emit(cost)
		if action_callable.is_valid():
			action_callable.call()
	else:
		# ДЕНЕГ НЕТ: Делаем кнопку красной
		var original_color = btn.modulate
		btn.modulate = Color(1, 0, 0) # Чисто красный
		# Ждем полсекунды прямо здесь, без лишних функций
		await get_tree().create_timer(0.5).timeout
		# Возвращаем цвет обратно, если кнопка еще жива
		if is_instance_valid(btn):
			btn.modulate = original_color
