extends Node2D

# Exported Variabless
@export_group("Settings")
@export var item: Item

# Refereces
@onready var texture_node = $texture
@onready var item_area = $texture/item_area

# Information
var tween

# Processing
func _ready():
	texture_node.texture = item.texture
	if item != null:
		if item.max_durability > 1 and item.durability == 0:
			item.durability = item.max_durability
	start_floating_animation()

func start_floating_animation():
	# Create a new tween
	tween = create_tween()
	
	# Get the original position
	var start_position = texture_node.position
	var end_position = start_position + Vector2(0, -20)
	
	# Animate the object moving up and down
	tween.tween_property(texture_node, "position", end_position, 2).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(texture_node, "position", start_position, 2).set_trans(Tween.TRANS_CUBIC)
	
	# Callback to restart the animation
	tween.tween_callback(Callable(self, "start_floating_animation"))

func _on_item_area_area_entered(area):
	if area.name == "inventory_area_controller":
		if area.get_parent().get_node("inventory_manager").storage_manager.collect_item(item):
			queue_free()
