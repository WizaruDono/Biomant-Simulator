extends Node2D
class_name Level

@onready var player_actors: Node2D = %player_actors
#@onready var player_loot: Node2D = %player_loot
@onready var player_locations: Node2D = %player_locations
@onready var player_productions: Node2D = %player_productions
@onready var player_loot: Node2D = %player_loot

func _ready() -> void:
	GameManager.level = self
	PlayerManager.initialize()
	MonsterManager.create_grandpa()
	LocationManager.create_graveyard()
	ProductionManager.create_stapler()
	ProductionManager.create_motel()
	ProductionManager.create_changeshop()
	NpcManager.create_trader()		# торговец
	#NpcManager.create_order_trader()		# спавн торгаша заказов заменили на спавн самих заказов
	#OrderManager.spawn_3_random_orders()	# заказы
	
	# Кнопкка ReRoll - можно удалить
	#var btn_scene = preload("res://scenes/reroll_button.tscn")
	#var btn = btn_scene.instantiate()
	#add_child(btn)
	#btn.global_position = Vector2(500, 100) # Позиция рядом с заказами
