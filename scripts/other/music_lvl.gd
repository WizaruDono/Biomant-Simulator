extends AudioStreamPlayer

@export var playlist : Array[AudioStream] = [
	preload("res://sounds/music/Kevin MacLeod - Cool Vibes.mp3"),
	preload("res://sounds/music/Kevin MacLeod - Scheming Weasel slower.mp3"),	# популярная, топово вписывается
	preload("res://sounds/music/Kevin MacLeod - Kool Kats.mp3"),			# больше как музыка в лифте, но затягивает
	preload("res://sounds/music/Kevin MacLeod - Investigations.mp3"),		# достаточно весёлая (известная)
	preload("res://sounds/music/Kevin MacLeod - Ghost Processional.mp3"),	# немного мрачная
]

# Словарь для тонкой настройки громкости (в децибелах)
# Если трек слишком тихий, пишем 5.0, если громкий -5.0
var volume_offsets = {
	"Kevin MacLeod - Cool Vibes": -2.0,
	"Kevin MacLeod - Kool Kats": -7.0,
	"Kevin MacLeod - Investigations": -10.0,			# рил громкая
	"Kevin MacLeod - Scheming Weasel slower": 0.0,
	"Kevin MacLeod - Ghost Processional": -4.0 # Сделаем чуть тише, он мрачноват
}

var current_track_index = 0
var base_volume = 0.0 # Базовая громкость плеера (0 дБ)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Не останавливать в паузе
	bus = "Music" # Убедись, что шина создана в Audio Layout
	finished.connect(_on_track_finished)
	play_current_track()

func play_current_track():
	var track = playlist[current_track_index]
	stream = track
	
	# Ищем название трека в словаре, чтобы применить офсет
	var track_name = track.resource_path.get_file().get_basename()
	var offset = volume_offsets.get(track_name, 0.0)
	
	# Плавное появление (Fade In)
	volume_db = -40 # Начинаем с тишины
	play()
	
	var tween = create_tween()
	tween.tween_property(self, "volume_db", base_volume + offset, 2.0).set_trans(Tween.TRANS_SINE)
	print("Играет трек: ", track_name)

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
