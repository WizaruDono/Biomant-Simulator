extends AudioStreamPlayer

@export var playlist : Array[AudioStream] = [
	preload("res://sounds/music/Kevin MacLeod - Cool Vibes.mp3"),
	preload("res://sounds/music/Kevin MacLeod - Scheming Weasel slower.mp3"),
	preload("res://sounds/music/Kevin MacLeod - Kool Kats.mp3"),
	preload("res://sounds/music/Kevin MacLeod - Investigations.mp3"),
	preload("res://sounds/music/Kevin MacLeod - Ghost Processional.mp3"),
]

var current_track_index = 0
var base_volume = 0.0 # Базовая громкость плеера (0 дБ)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Не останавливать в паузе
	bus = "Music" # Убедись, что шина создана в Audio Layout
	finished.connect(_on_track_finished)
	play_current_track()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("next_song"):
		current_track_index = wrapi(current_track_index + 1, 0, playlist.size())
		play_current_track()
	if Input.is_action_just_pressed("prev_song"):
		current_track_index = wrapi(current_track_index - 1, 0, playlist.size())
		play_current_track()
	pass

func play_current_track():
	var track = playlist[current_track_index]
	var track_name = track.resource_path.get_file().get_basename()
	print("Играет трек: ", track_name)
	
	stream = track # что играть
	volume_db = -40 # базовая громкость - тишина
	play()
	
	# Плавно увеличиваем громкость
	var tween = create_tween()
	tween.tween_property(self, "volume_db", base_volume, 2.0).set_trans(Tween.TRANS_SINE)
	pass

func _on_track_finished():
	# Плавное затухание (Fade Out) перед паузой уже не нужно (трек сам кончился),
	# так что просто ждем паузу.
	var wait_time = randf_range(5.0, 10.0)
	print("Пауза между треками: ", wait_time, " сек.")
	
	await get_tree().create_timer(wait_time).timeout
	
	current_track_index = (current_track_index + 1) % playlist.size()
	play_current_track()

# Если нужно переключить трек принудительно (например, кнопкой)
func skip_track():
	var tween = create_tween()
	# Плавное затухание за 1.5 сек
	tween.tween_property(self, "volume_db", -40, 1.5).set_trans(Tween.TRANS_SINE)
	await tween.finished
	stop()
	_on_track_finished()
