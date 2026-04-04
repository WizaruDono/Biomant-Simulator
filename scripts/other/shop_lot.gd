extends Area2D
class_name ShopLot

@export var lot : Card
@export var lot_cost : int
@export var lot_offset : float = 10
@onready var button_buy: Button = %button_buy

func initialize():
	await get_tree().process_frame
	lot_cost = lot.card_cost
	button_buy.text = str(lot_cost)
	global_position = lot.global_position - Vector2(0, lot_offset * 5)


func set_lot(new_lot : Card):
	lot = new_lot

func _on_button_buy_pressed() -> void:
	if PlayerManager.check_gold(lot_cost):
		SoundManager.play_asmr_sfx(SoundManager.SND_BUY, -8.0) # ЗВУК ПОКУПКИ (Слегка громкий, это же награда!)
		button_buy.disabled = true
		SignalManager.on_spend_gold.emit(lot_cost)
		

		
		# Проверяем, является ли это картой улучшения тип UPGRADE
		if lot is CardUpgrade:
			var up_res = lot.upgrade_res
			# Применяем эффект прямо из ресурса UpgradeRes
			PlayerManager.apply_upgrade(up_res.upgrade_type, up_res.upgrade_value)
			
			# Сигнализируем торговцу, что слот куплен (чтобы он автообновился, если надо)
			SignalManager.on_buy_lot.emit(lot)
			lot.queue_free()
		else:
			# Если это обычная карта (монстр, локация и т.д.)
			SignalManager.on_buy_lot.emit(lot)
			
		hide()
		get_tree().create_timer(0.1).timeout.connect(queue_free)
	else:
		# ДЕНЕГ НЕТ: Делаем кнопку красной на полсекунды
		var original_color = button_buy.modulate
		button_buy.modulate = Color(1, 0, 0)
		get_tree().create_timer(0.5).timeout.connect(func():
			if is_instance_valid(button_buy):
				button_buy.modulate = original_color
		)
