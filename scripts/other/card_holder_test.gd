#class_name CardHolderTest
#extends Area2D
#
#@export var intersected_card : CardHolderTest
#
#@export var card_state : DataManager.CardState: set = _on_state_set
#@export var prev_state : DataManager.CardState
#
#@export var is_dragging : bool
#@export var prev_z_index : int
#
#@export var card_type : DataManager.CardType
#@export var card_grade : DataManager.EntityGrade
#@export var card_cost : int
#@export var card_texture : Texture2D
#@export var card_owner_type : DataManager.OwnerType
#@export var stylebox_tooltip : StyleBoxFlat
#@export var font_tooltip : Font
#
#@onready var collision_card: CollisionShape2D = %collision_card
#@onready var anim_card: AnimationPlayer = %anim_card
#@onready var activate_timer: Timer = %activate_timer
#@onready var rect_main_img: TextureRect = %rect_main_img
#@onready var label_header: Label = %label_header
#@onready var panel_back: PanelContainer = %panel_back
#@onready var card_container: Node2D = %CardContainer
#
#var drag_offset: Vector2 = Vector2.ZERO
#
#func _ready() -> void:
	#card_state = DataManager.CardState.APPEARS
#
#func setup_tooltip():
	## 🛡️ ЗАЩИТА: Если ресурс не назначен в инспекторе, мы просто выходим!
		#if stylebox_tooltip == null:
			#print("Предупреждение: для карты ", name, " не задан stylebox_tooltip!")
			#return
			#
		#var new_theme = Theme.new()
		#var sb = stylebox_tooltip.duplicate()
		#sb.set_content_margin_all(8)
		#new_theme.set_stylebox('panel', 'TooltipPanel', sb)
		#new_theme.set_font('font', 'TooltipLabel', font_tooltip)
		#new_theme.set_font_size('font_size', 'TooltipLabel', 12)
		#new_theme.set_color('font_color', 'TooltipLabel', Color(0.125, 0.18, 0.216, 1.0))
		##var stylebox = new_theme.get_theme_stylebox('normal')
		#panel_back.theme = new_theme
#
#func _on_state_set(value: DataManager.CardState) -> void:
	#prev_state = card_state
	#card_state = value
#
#func _enter_state() -> void:
	#match card_state:
		#DataManager.CardState.APPEARS:
			#anim_card.play('appears')
		#
		#DataManager.CardState.ON_FIELD:
			#pass
		#
		#DataManager.CardState.DRAGGED:
			#if get_parent() != GameManager.level:
				#call_deferred("reparent_to_level")
			#
			#drag_offset = get_global_mouse_position() - global_position
			#
			#z_index = 10
		#
		#DataManager.CardState.HOVER_STACK:
			#pass
		#
		#DataManager.CardState.ENTER_STACK:
			#if intersected_card:
				#intersected_card.add_card_to_stack(self)
		#
		#DataManager.CardState.IN_STACK:
			#pass
		#
		#DataManager.CardState.EXIT_STACK:
			#pass
		#
		#DataManager.CardState.DESTROYED:
			#pass
		#
	#print(DataManager.CardState.keys()[card_state] + ' ' + self.name)
#
#func reparent_to_level() -> void:
	#var _level: Level = GameManager.level
	#reparent(_level)
#
#func add_card_to_stack(card: CardHolderTest) -> void:
	#card.reparent(self)
	#card.position = Vector2.ZERO
	#card.position.y += label_header.size.y
#
#func _physics_process(delta: float) -> void:
	#if is_dragging:
		#global_position = get_global_mouse_position() + drag_offset
