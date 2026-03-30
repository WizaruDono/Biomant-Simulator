extends CardActor

class_name CardActorPart


@export var part_res : PartRes
@export var part_perc : DataManager.PercType
@export var part_type : DataManager.MonsterPartType
@export var part_family : DataManager.MonsterFamily


func initialize():
	await get_tree().process_frame
	card_type = part_res.card_type
	card_texture = part_res.card_texture
	card_grade = part_res.card_grade
	card_cost = part_res.card_cost
	actor_name = part_res.card_name
	actor_desc = part_res.card_desc
	actor_health = part_res.actor_health
	actor_damage = part_res.actor_damage
	card_texture = part_res.card_texture
	part_perc = part_res.part_perc
	part_type = part_res.part_type
	part_family = part_res.part_family
	panel_back.tooltip_text = actor_desc
	setup_tooltip()
	
	label_header.text = actor_name
	var atlas : AtlasTexture = AtlasTexture.new()
	atlas.atlas = card_texture
	atlas.region = Rect2(0, 0, 128, 128)
	rect_main_img.texture = atlas
	label_damage.text = str(actor_damage)
	label_health.text = str(actor_health)
