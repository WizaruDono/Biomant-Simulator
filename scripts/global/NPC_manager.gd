extends Node

@export var npc_scene : PackedScene = preload("res://scenes/card_actor_npc.tscn")
@export var npc_trader_location_res : NPCRes = preload("res://resources/NPC_trader.tres")
@export var npc_trader_order_res : NPCRes = preload("res://resources/NPC_order_trader.tres")


func create_random_trader():
	pass


func create_trader_by_type(trader_type : DataManager.CardType):
	pass

# ТОРГОВЕЦ
func create_trader():
	var npc : CardActorNPC = npc_scene.instantiate()
	npc.npc_res = npc_trader_location_res
	GameManager.level.player_actors.add_child(npc)
	npc.initialize()
	# Конкретные координаты (X, Y)
	npc.global_position = Vector2(1400, -150) # чем меньше Y - тем выше
	# Рандомная позиция
	#npc.global_position = Vector2(600 + randi_range(-150, 150), randf_range(DataManager.npc_positions[0], DataManager.npc_positions[1]))
	
# Торговец с заданиями, можно удалить
func create_order_trader():
	var npc : CardActorNPC = npc_scene.instantiate()
	npc.npc_res = npc_trader_order_res
	GameManager.level.player_actors.add_child(npc)
	npc.initialize()
	npc.global_position = Vector2(600 + randi_range(-150, 150), randf_range(DataManager.npc_positions[0], DataManager.npc_positions[1]))
