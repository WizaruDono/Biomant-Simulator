extends Node

@warning_ignore("unused_signal")
signal on_buy_lot(card : Card)
@warning_ignore("unused_signal")
signal on_spend_gold(gold_amount : int)

signal card_focused(target_position: Vector2)
