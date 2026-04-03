extends Node

var location_scene : PackedScene = load("res://scenes/card_location.tscn")
var monster_scene : PackedScene = load("res://scenes/card_actor_monster.tscn")
var part_scene : PackedScene = load("res://scenes/card_actor_part.tscn")
var order_scene : PackedScene = load("res://scenes/card_order.tscn")
var upgrade_scene : PackedScene = load("res://scenes/card_upgrade.tscn")

func create_entity_scene(res : CardRes):
	var instance: Node
	match res.card_type:
		DataManager.CardType.LOCATION:
			instance = location_scene.instantiate()
			instance.location_res = res
		DataManager.CardType.MONSTER:
			instance = monster_scene.instantiate()
			instance.monster_res = res
		DataManager.CardType.MONSTER_PART:
			instance = part_scene.instantiate()
			instance.part_res = res
		DataManager.CardType.ORDER:
			instance = order_scene.instantiate()
			instance.order_res = res
		DataManager.CardType.UPGRADE: 
			instance = upgrade_scene.instantiate()
			instance.upgrade_res = res
	return instance
