extends Node


@export var production_scene : PackedScene = preload("res://scenes/card_production.tscn")
@export var stapler_res : ProductionRes = preload("res://resources/production/production_stapler.tres")
@export var motel_res : ProductionRes = preload("res://resources/production/production_motel.tres")
@export var changeshop_res : ProductionRes = preload("res://resources/production/production_changeshop.tres")



func create_random_production():
	pass


func create_location_by_type_and_grade(_production : DataManager.ProductionType, _production_grade : DataManager.EntityGrade):
	pass


func create_stapler():
	var stapler : CardProduction = production_scene.instantiate()
	stapler.production_res = stapler_res
	GameManager.level.player_productions.add_child(stapler)
	stapler.initialize()
	stapler.global_position = Vector2(600 + randi_range(-150, 150), 600 + randi_range(-150, 150))


func create_motel():
	var motel : CardProduction = production_scene.instantiate()
	motel.production_res = motel_res
	GameManager.level.player_productions.add_child(motel)
	motel.initialize()
	motel.global_position = Vector2(600 + randi_range(-150, 150), 600 + randi_range(-150, 150))


func create_changeshop():
	var changeshop : CardProduction = production_scene.instantiate()
	changeshop.production_res = changeshop_res
	GameManager.level.player_productions.add_child(changeshop)
	changeshop.initialize()
	changeshop.global_position = Vector2(600 + randi_range(-150, 150), 600 + randi_range(-150, 150))
