extends Node

@export var gold : int = 250
@export var current_gold : int

# === Глобальные модификаторы ===
@export var dig_speed_multiplier : float = 1.0  # Чем меньше, тем быстрее (напр. 0.8 = на 20% быстрее)
@export var rare_drop_bonus : float = 0.05       # Прибавка к шансу (напр. 0.1 = +10% шанс Т2)

func initialize():
	SignalManager.on_spend_gold.connect(spend_gold)
	current_gold = gold

func check_gold(gold_amount : int) -> bool:
	if current_gold - gold_amount < 0:
		return false
	return true

func spend_gold(gold_amount : int):
	current_gold -= gold_amount
	# Опционально: добавить сигнал SignalManager.on_gold_changed.emit(current_gold) для UI

func add_gold(gold_amount : int):
	current_gold += gold_amount
	# Опционально: добавить сигнал SignalManager.on_gold_changed.emit(current_gold) для UI

# === ПРИМЕНЕНИЕ АПГРЕЙДА (повышает уровень в DataManager) ===
func apply_upgrade(up_res: UpgradeRes):
	var u_type = up_res.upgrade_type
	var new_level = int(up_res.card_grade) + 1	# T1(0) -> 1, T2(1) -> 2, T3(2) -> 3
	# 1. Если грейдим ЛОКАЦИЮ
	if up_res.target_card_type == DataManager.CardType.LOCATION:
		var loc = up_res.target_location
		# Проверяем существование ключей перед доступом
		if DataManager.current_location_upgrades.has(loc) and DataManager.current_location_upgrades[loc].has(u_type):
			if new_level > DataManager.current_location_upgrades[loc][u_type]:
				DataManager.current_location_upgrades[loc][u_type] = new_level
				print("Локация ", loc, " уровень: ", new_level)
	# 2. Если грейдим ПРОИЗВОДСТВО
	elif up_res.target_card_type == DataManager.CardType.PRODUCTION:
		var prod = up_res.target_production
		if DataManager.current_production_upgrades.has(prod) and DataManager.current_production_upgrades[prod].has(u_type):
			if new_level > DataManager.current_production_upgrades[prod][u_type]:
				DataManager.current_production_upgrades[prod][u_type] = new_level
				print("Производство ", prod, " уровень: ", new_level)
