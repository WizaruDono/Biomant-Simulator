extends HSlider

@export var audio_bus_name := "Master"
@export var default_volume_linear := 0.5 # 0.5 — это 50% громкости

@onready var _bus := AudioServer.get_bus_index(audio_bus_name)

func _ready() -> void:
	# 1. Сначала применяем громкость по умолчанию к шине
	# (Делаем это только один раз при старте или если хотим сбросить)
	var current_db = AudioServer.get_bus_volume_db(_bus)
	
	# Если в системе стоит 0 дБ (дефолт Godot), меняем на наш дефолт
	if current_db == 0: 
		AudioServer.set_bus_volume_db(_bus, linear_to_db(default_volume_linear))
	
	# 2. Теперь выставляем положение ползунка слайдера
	value = db_to_linear(AudioServer.get_bus_volume_db(_bus))


func _on_value_changed(val: float) -> void:
	# Убедись, что у HSlider в инспекторе: 
	# Min Value = 0, Max Value = 1, Step = 0.1 или 0.05
	AudioServer.set_bus_volume_db(_bus, linear_to_db(val))
	
	# Чтобы звук совсем выключался на нуле:
	AudioServer.set_bus_mute(_bus, val < 0.01)
