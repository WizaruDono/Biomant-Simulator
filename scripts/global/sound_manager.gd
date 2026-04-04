extends Node

var sound : AudioStreamPlayer
var music : AudioStreamPlayer
var main_theme1
var main_theme2
var menu_theme : Resource
var main_theme = [main_theme1, main_theme2]
var peaceful_music : Array[Resource]
var martial_music : Array[Resource]

var peaceful_music_index : int
var martial_music_index : int
var played_streams : Array[AudioStreamPlayer]
var is_martial_phase : bool
#const UI_HOVER : AudioStream = preload("res://sound/ui.wav")

# Подгружаем их сразу при запуске игры, чтобы не было микро-фризов при спавне
const SND_BUY = preload("res://sounds/sfx/normalized/flesh_pop_norm.wav")
const SND_REROLL = preload("res://sounds/sfx/normalized/buy_gold_1_norm.wav")	# "res://sounds/sfx/card_slide_3.wav"
const SND_STACK = preload("res://sounds/sfx/normalized/card_slide_1_norm.wav")	# "res://sounds/sfx/flesh_pop.wav"
const SND_SPAWN = preload("res://sounds/sfx/normalized/flesh_pop_norm.wav")
const FLESH_POP = preload("res://sounds/sfx/normalized/flesh_pop_norm.wav")
#"res://sounds/sfx/buy_gold_1.wav"
#"res://sounds/sfx/buy_gold_2.wav"
#"res://sounds/sfx/card_slide_1.wav"
#"res://sounds/sfx/card_slide_2.wav"
#"res://sounds/sfx/card_slide_3.wav"
#"res://sounds/sfx/flesh_pop.wav"
#"res://sounds/sfx/TIXO.wav"

## Пул плееров для переиспользования. Они созданы при загрузке игры и
## для проигрывания звука выбирается первый свободный. 
## В godot один плеер за раз может воспроизводить только один звук.
var pool_size: int = 8
var player_pool: Array[AudioStreamPlayer] = []

func _ready():
	# Initialize the pool once
	for i in pool_size:
		var sfx = AudioStreamPlayer.new()
		sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		sfx.bus = "SFX"
		add_child(sfx)
		player_pool.append(sfx)

func play_asmr_sfx(stream: AudioStream, vol_db: float = 0.0):
	if stream == null: return
	
	var sfx_player = _find_available_player()
	if sfx_player:
		sfx_player.stream = stream
		sfx_player.volume_db = vol_db
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_player.play()
	else:
		push_warning("Слишком много одновременных звуков, расширьте пул")
	pass

func play(_source: Node, stream: AudioStream):
	# Ощущение, что эта функция никому не нужно, но боюсь сломать, поэтому
	# печатаю в лог, что её позвали.
	print_rich("[color=red]DEBUG: play() was called by [/color]", _source)
	play_asmr_sfx(stream, -25)
	pass

func play_ui(_source : Node, stream : AudioStream):
	play_asmr_sfx(stream, -15)

func _find_available_player():
	for sfx in player_pool:
		if not sfx.playing: return sfx
	return null


func play_peaceful_music(_current_delay : int = 0):
	if music:
		music.stop()
		music.queue_free()
	music = AudioStreamPlayer.new()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.bus = "Music"
	if peaceful_music_index == peaceful_music.size():
		peaceful_music_index = 0
	music.stream = main_theme[peaceful_music_index]
	peaceful_music_index += 1
	music.play()

func play_martial_music(_current_delay : int = 0):
	if music:
		music.stop()
		music.queue_free()
	music = AudioStreamPlayer.new()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.bus = "Music"
	if martial_music_index == martial_music.size():
		martial_music_index = 0
	music.stream = main_theme[martial_music_index]
	martial_music_index += 1
	music.play()

func play_menu_music():
	if music:
		music.stop()
		music.queue_free()
	music = AudioStreamPlayer.new()
	music.stream = menu_theme
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.bus = "Music"
	music.play()
