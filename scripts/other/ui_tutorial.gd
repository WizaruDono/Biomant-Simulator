extends Control

# Находим кнопку и текст внутри неё
@onready var toggle_button: Button = $ToggleButton 
@onready var text_button: Label = $ToggleButton/ArrowLabel

var is_open: bool = false
# Узнаем ширину панели из настроек, которые ты выставил в редакторе
@onready var panel_width: float = size.x +20

func _ready():
	# Состояние при старте: панель спрятана за левый край.
	# position.x = -350 (условно), значит её не видно.
	position.x = -panel_width
	
	# Подключаем сигнал нажатия программно, если не сделали это в эдиторе
	toggle_button.pressed.connect(_on_toggle_button_pressed)

func _on_toggle_button_pressed() -> void:
	is_open = !is_open
	print("OPEN 1:", is_open)
	
	# Создаем Твин для плавной анимации
	var tween = create_tween()
	print("OPEN 2:", is_open)
	# Куда едем? Если открываемся — в 0. Если закрываемся — обратно в минус.
	var target_x = -10 if is_open else -panel_width
	
	# Анимируем позицию. 
	# 0.3 секунды — оптимально. TRANS_BACK даст небольшой "отскок" как в мобилках.
	tween.tween_property(self, "position:x", target_x, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Поворачиваем стрелку (можно просто менять текст)
	if is_open:
		text_button.text = "<"
	else:
		text_button.text = ">"


"""
для текста правил:

[color=#FDFD96]Пастельный желтый: [/color]

[color=#B2E2F2]Мятный (для Фермы): [/color]

[color=#FFD1DC]Приглушенный розовый: [/color]

[color=#D3D3D3]Светло-серый (для костей): [/color]

"""
