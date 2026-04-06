extends Node

@export var location_scene : PackedScene = preload("res://scenes/card_location.tscn")
@export var graveyard_res : LocationRes = preload("res://resources/locations/location_graveyard.tres")
@export var all_res : LocationRes = preload("res://resources/locations/all_parts.tres")



func create_random_location():
	pass


func create_location_by_type_and_grade(_location_type : DataManager.LocationType, _location_grade : DataManager.EntityGrade):
	pass


func create_graveyard():
	var graveyard : CardLocation = location_scene.instantiate()
	graveyard.location_res = graveyard_res
	GameManager.level.player_locations.add_child(graveyard)
	graveyard.initialize()
	graveyard.global_position = Vector2(600, 600)	# зафиксировал позицию для гайда
	#graveyard.global_position = Vector2(600 + randi_range(-150, 150), 600 + randi_range(-150, 150))
