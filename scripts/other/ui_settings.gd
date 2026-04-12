extends TextureButton

@export var hover_scale: Vector2 = Vector2(1.15, 1.15)
var default_scale: Vector2

func _ready() -> void:
	default_scale = scale
	# Чтобы кнопка работала во время паузы
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	pressed.connect(_on_settings_pressed)
	mouse_entered.connect(func(): _animate(hover_scale))
	mouse_exited.connect(func(): _animate(default_scale))

func _on_settings_pressed() -> void:
	if GameManager.options_UI and GameManager.options_UI.is_opened:
		GameManager.hide_options()
	else:
		GameManager.show_options()

func _animate(target: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", target, 0.15).set_trans(Tween.TRANS_QUAD)
