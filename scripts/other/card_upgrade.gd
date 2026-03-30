extends Card
class_name CardUpgrade

@export var upgrade_res : CardRes

func initialize():
	await get_tree().process_frame
	card_type = upgrade_res.card_type
	card_texture = upgrade_res.card_texture
	card_cost = upgrade_res.card_cost
	card_owner_type = upgrade_res.card_owner_type
	
	label_header.text = upgrade_res.card_name
	rect_main_img.texture = card_texture
	panel_back.tooltip_text = upgrade_res.card_desc
	setup_tooltip()
