extends Resource
class_name Item

@export var name: String
@export var texture: Texture2D
@export_multiline var description: String
@export_range(1,9999) var stack_limit: int
@export_range(0,99999) var max_durability: int
var durability: int
