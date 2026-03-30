extends Node

var location_scene : PackedScene = load("res://scenes/card_location.tscn")
var monster_scene : PackedScene = load("res://scenes/card_actor_monster.tscn")
var part_scene : PackedScene = load("res://scenes/card_actor_part.tscn")
var order_scene : PackedScene = load("res://scenes/card_order.tscn")
var upgrade_scene : PackedScene = load("res://scenes/card_upgrade.tscn")

func create_entity_scene(res : CardRes):
	match res.card_type:
		DataManager.CardType.LOCATION:
			var location : CardLocation = location_scene.instantiate()
			location.location_res = res
			var scene : PackedScene = PackedScene.new()
			scene.pack(location)
			return scene
		DataManager.CardType.MONSTER:
			var monster : CardActorMonster = monster_scene.instantiate()
			monster.monster_res = res
			var scene : PackedScene = PackedScene.new()
			scene.pack(monster)
			return scene
		DataManager.CardType.MONSTER_PART:
			var part : CardActorPart = part_scene.instantiate()
			part.part_res = res
			var scene : PackedScene = PackedScene.new()
			scene.pack(part)
			return scene
		DataManager.CardType.ORDER:
			var order : CardOrder = order_scene.instantiate()
			order.order_res = res
			var scene : PackedScene = PackedScene.new()
			scene.pack(order)
			return scene
		DataManager.CardType.UPGRADE: 
			var upgrade : CardUpgrade = upgrade_scene.instantiate()
			upgrade.upgrade_res = res
			var scene : PackedScene = PackedScene.new()
			scene.pack(upgrade)
			return scene
