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
	MonsterManager.create_grandpa()			# рожаем деда
	LocationManager.create_graveyard()		# закапываем кладбища
	NpcManager.create_trader()				# зазываем торговца
	OrderManager.rate = 0					# копим возмущённых заказчиков
	
	# Для отладки:
	#MonsterManager.create_grandpa()
	#ProductionManager.create_stapler()		# Сшиватель
	#ProductionManager.create_motel()		# Любовное Гнёздышко
	#ProductionManager.create_changeshop()	# Обменник
	
	# Кнопкка ReRoll - можно удалить
	#var btn_scene = preload("res://scenes/reroll_button.tscn")
	#var btn = btn_scene.instantiate()
	#add_child(btn)
	#btn.global_position = Vector2(500, 100) # Позиция рядом с заказами
