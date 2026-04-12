extends Node

@warning_ignore("unused_signal")
signal on_buy_lot(card : Card)
@warning_ignore("unused_signal")
signal on_spend_gold(gold_amount : int)

signal card_focused(target_position: Vector2)

# === СИГНАЛЫ ДЛЯ КВЕСТОВ (для заданий) ===
# 1 глава
signal monster_started_digging()	# монстр начал добычу
signal part_mined()			# для задания: выбить N конечностей

# 2 глава
signal stapler_started()	# гайд - начали сшивать монстра
signal order_finished(order_type: DataManager.CardType, grade: int) # передаем уровень и тип выполненого заказа (монстр / конечность)

# 3 глава
signal part_merger_finished() # Обменник сработал
