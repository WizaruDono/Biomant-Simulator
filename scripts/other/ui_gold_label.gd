extends Label

func _ready():
	# Обновляем текст каждый кадр (для джема сойдет, чтобы не настраивать сигналы)
	set_process(true)

func _process(_delta):
	text = str(PlayerManager.current_gold) + "$"	# "Золото: " + 
