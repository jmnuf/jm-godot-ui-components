tool
extends Label

var _bg_stylebox := StyleBoxFlat.new()


func _init() -> void:
	add_stylebox_override("normal", _bg_stylebox)
	var x_margin = 2
	var y_margin = 1
	
	_bg_stylebox.expand_margin_right = x_margin
	_bg_stylebox.expand_margin_left = x_margin
	
	_bg_stylebox.expand_margin_bottom = y_margin
	_bg_stylebox.expand_margin_top = y_margin
	
	if not is_connected("resized", self, "update"):
		connect("resized", self, "update")


func _ready() -> void:
	call_deferred("update")


func update() -> void:
	var radius = min(rect_size.x, rect_size.y) / 4
	_bg_stylebox.set_corner_radius_all(radius)
	
	.update()


func set_pill_bg_color(color:Color) -> void:
	_bg_stylebox.bg_color = color


func set_pill_border_color(color:Color) -> void:
	_bg_stylebox.border_color = color


func set_pill_border_width(width:int) -> void:
	_bg_stylebox.set_border_width_all(width)


func _set(property: String, value) -> bool:
	match property:
		"pill_bg_color":
			set_pill_bg_color(value)
		
		"pill_border_color":
			set_pill_border_color(value)
		
		"pill_border_width":
			set_pill_border_width(value)
	return false


func _get(property: String):
	match property:
		"pill_bg_color":
			return _bg_stylebox.bg_color
		
		"pill_border_color":
			return _bg_stylebox.border_color
		
		"pill_border_width":
			return _bg_stylebox.get_border_width_min()
		
		"custom_styles/normal":
			return _bg_stylebox
		
		_:
			return null


func _get_property_list() -> Array:
	var props := []
	
	props.append({
		"name": "PillLabel",
		"usage": PROPERTY_USAGE_CATEGORY,
		"type": TYPE_NIL,
	})
	
	props.append({
		"name": "pill",
		"usage": PROPERTY_USAGE_GROUP,
		"type": TYPE_NIL,
		"hint_string": "pill_"
	})
	props.append({
		"name": "pill_bg_color",
		"type": TYPE_COLOR,
	})
	props.append({
		"name": "pill_border_color",
		"type": TYPE_COLOR
	})
	props.append({
		"name": "pill_border_width",
		"type": TYPE_INT
	})
	
	return props
