extends Node2D

# References
@onready var texture = $texture
@onready var amount = $amount

# Info
var item: InventoryItem

func _ready() -> void:
	texture.texture = item.item.texture
	amount.text = str(item.amount)
	
