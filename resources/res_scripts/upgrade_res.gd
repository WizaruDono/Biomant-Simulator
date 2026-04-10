extends CardRes
class_name UpgradeRes

@export var upgrade_type : DataManager.UpgradeType	 # "speed", "rare_drop"...
# Выбираем, ЧТО именно мы грейдим (Локацию или Производство)
@export var target_card_type : DataManager.CardType  		# PRODUCTION или LOCATION

# Выбираем КОНКРЕТНУЮ цель из готовых списков:
@export var target_location : DataManager.LocationType
@export var target_production : DataManager.ProductionType
