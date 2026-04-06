extends Card
class_name CardUpgrade

@export var upgrade_res : CardRes

var is_active: bool = false

func initialize():
	await get_tree().process_frame
	# Проверка: если ресурса нет, пишем ошибку и выходим из функции
	#if not upgrade_res:
		#print("🚨 КРИТИЧЕСКАЯ ОШИБКА: У карты ", name, " отсутствует upgrade_res!")
		#return
	card_type = upgrade_res.card_type
	card_texture = upgrade_res.card_texture
	card_cost = upgrade_res.card_cost
	card_owner_type = upgrade_res.card_owner_type
	
	label_header.text = upgrade_res.card_name
	rect_main_img.texture = card_texture
	panel_back.tooltip_text = upgrade_res.card_desc
	setup_tooltip()
