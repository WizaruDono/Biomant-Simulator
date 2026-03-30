extends Node

@export var gold : int = 150
@export var current_gold : int

# === НОВОЕ: Глобальные модификаторы ===
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

# === Функция применения апгрейдов ===
func apply_upgrade(upgrade_type: DataManager.UpgradeType, value: float):
	match upgrade_type:
		DataManager.UpgradeType.SPEED:
			# Умножаем время (уменьшаем его). 
			# Если передали 0.8, то время копания уменьшится на 20%
			dig_speed_multiplier *= value 
			print("Скорость раскопок увеличена! Текущий множитель времени: ", dig_speed_multiplier)
		DataManager.UpgradeType.RARE_DROP:
			# Тут прибавляем шанс. Если передали 0.15, шанс вырастет на 15%
			rare_drop_bonus += value
			print("Шанс редкого дропа увеличен! Бонус: ", rare_drop_bonus)
