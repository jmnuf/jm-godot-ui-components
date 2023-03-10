extends LineEdit

signal suggestion_picked(suggestion)
signal calculated_suggestions()

export var select_on_suggesting:bool = true
export var _possible_suggestions := PoolStringArray()

var _used_suggestions := PoolStringArray()
var _suggestion_popup := PopupMenu.new()
var _suggest_from:String

func _init() -> void:
	if not is_connected("text_changed", self, "_on_SuggestiveLineEdit_text_changed"):
		connect("text_changed", self, "_on_SuggestiveLineEdit_text_changed")
	
	if not is_connected("text_entered", self, "_on_SuggestiveLineEdit_text_entered"):
		connect("text_entered", self, "_on_SuggestiveLineEdit_text_entered")
	
	
	_suggestion_popup.popup_exclusive = false
	
	if not _suggestion_popup.is_connected("focus_entered", self, "_on_SuggestionsPopup_focus_entered"):
		_suggestion_popup.connect("focus_entered", self, "_on_SuggestionsPopup_focus_entered")
	
	if not _suggestion_popup.is_connected("focus_exited", self, "_on_SuggestionsPopup_focus_exited"):
		_suggestion_popup.connect("focus_exited", self, "_on_SuggestionsPopup_focus_exited")
	
	if not _suggestion_popup.is_connected("index_pressed", self, "_on_SuggestionsPopup_idx_pressed"):
		_suggestion_popup.connect("index_pressed", self, "_on_SuggestionsPopup_idx_pressed")


func _ready() -> void:
	var root = get_tree().root
	if get_parent() == root:
		call_deferred("popup_suggestions")
	
	_suggestion_popup


func add_possible_suggestion(phrase:String) -> void:
	phrase = phrase.strip_edges()
	if _possible_suggestions.has(phrase):
		return
	
	_possible_suggestions.append(phrase)
	_calculate_suggestions()


func get_phrases() -> PoolStringArray:
	var phrases = text.split(",", false)
	
	for i in phrases.size():
		phrases[i] = phrases[i].strip_edges()
	
	return phrases


func set_suggestions_popup_parent(node:Node) -> void:
	if _suggestion_popup.get_parent():
		_suggestion_popup.get_parent()\
			.remove_child(_suggestion_popup)
	
	node.add_child(_suggestion_popup)


func popup_suggestions() -> void:
	var suggestions_parent = _suggestion_popup.get_parent()
	
	if not suggestions_parent:
		var tree = get_tree()
		if not tree: return
		else: tree.root.add_child(_suggestion_popup)
	
	var suggestions = _calculate_suggestions(true)
	
	if suggestions.empty():
		return
	
	call_deferred("_show_suggestion_popup_at_caret")


func _calculate_suggestions_popup_global_position() -> Vector2:
	var font = get("custom_fonts/font")
	if not font:
		font = get_font("font")
	if not font:
		push_error("Failed to get the font")
		return rect_global_position
	
	var extent := get_phrase_extent_near_caret()
	var text_behind_phrase = text.substr(0, extent[0])
	var string_size := Vector2(0, font.height)
	var padding:Vector2 = font.get_string_size(" ") / 2
	if not text_behind_phrase.empty():
		string_size = font.get_string_size(text_behind_phrase)
	
	var phrase_local_position := Vector2(string_size.x + padding.x, rect_size.y / 2 + string_size.y + padding.y / 2)
	
	prints("String size:", string_size)
	prints("Caret index:", caret_position)
	prints("Caret position:", phrase_local_position)
	
	var popup_position = rect_global_position + phrase_local_position
	
	return popup_position


func _calculate_suggestions(force_update_popup := false) -> PoolStringArray:
	var setup_popup = _suggestion_popup.visible
	var extent = get_phrase_extent_near_caret()
	_used_suggestions = (
		text.substr(0, extent[0]).strip_edges() \
		+ text.substr(extent[1]).strip_edges()
	).split(",", false)
	
	for i in range(_used_suggestions.size() -1, -1, -1):
		var phrase:String = _used_suggestions[i]
		phrase = phrase.strip_edges()
		if phrase.empty():
			_used_suggestions.remove(i)
			continue
		
		_used_suggestions[i] = phrase
	
	_suggest_from = text.substr(extent[0], extent[1])
	var suggestions := []
	for phrase in _possible_suggestions:
		if _used_suggestions.has(phrase):
			continue
		
		suggestions.append(phrase)
	
	emit_signal("calculated_suggestions")
	
	# If popup not visible no need to update it
	if not _suggestion_popup.visible and not force_update_popup:
		return PoolStringArray(suggestions)
	
	if not _suggest_from.strip_edges().empty():
		suggestions.sort_custom(self, "_compare_phrases_to_suggest")
	
	_suggestion_popup.clear()
	for phrase in suggestions:
		_suggestion_popup.add_item(phrase)
	
	_suggestion_popup.set_current_index(0)
	
	return PoolStringArray(suggestions)


func _compare_phrases_to_suggest(phrase_a:String, phrase_b:String) -> bool:
	var similarity_a = phrase_a.to_lower().similarity(_suggest_from.to_lower())
	var similarity_b = phrase_b.to_lower().similarity(_suggest_from.to_lower())
	
	if similarity_a == similarity_b:
		similarity_a = phrase_a.similarity(_suggest_from)
		similarity_b = phrase_b.similarity(_suggest_from)
	
	if similarity_a >= similarity_b:
		return true
	
	return false


func _show_suggestion_popup_at_caret() -> void:
	var font = get("custom_fonts/font")
	if not font:
		font = get_font("font")
	if not font:
		prints("Failed to get the font")
		return
	
	var position = _calculate_suggestions_popup_global_position()
	
	_suggestion_popup.popup(Rect2(
		position,
		Vector2(rect_size.x, 10)
	))
	_suggestion_popup.set_current_index(0)
	
	if not select_on_suggesting:
		return
	
	var extent := get_phrase_extent_near_caret()
	select(extent[0], extent[1])


func hide_suggestions() -> void:
	_suggestion_popup.hide()


func _unhandled_key_input(event: InputEventKey) -> void:
	if not event.control:
		return
	
	if event.scancode != KEY_SPACE:
		return
	
	if _possible_suggestions.empty():
		return
	
	popup_suggestions()


func get_phrase_extent_near_caret() -> PoolIntArray:
	var extent := PoolIntArray([0, 0])
	if caret_position == 0 and (text.empty() or text.begins_with(" ")):
		return extent
	
	var start_index:int = caret_position - 1
	while start_index >= 0:
		var section:String = text.substr(start_index, caret_position)
		if section.begins_with(","):
			if section.begins_with(", "):
				start_index += 2
			else:
				start_index += 1
			break
		
		start_index -= 1
	
	extent[0] = max(start_index, 0)
	
	var text_length = text.length()
	var end_index:int = caret_position + 1
	
	while end_index <= text_length:
		var character:String = text.substr(end_index - 1, 1)
		if character == ",":
			end_index -= 1
			break
		
		end_index += 1
	
	extent[1] = min(end_index, text_length)
	
	return extent


func _input(event: InputEvent) -> void:
	if not _suggestion_popup.visible:
		return
	
	if not (event is InputEventKey):
		return
	
	if get_focus_owner() != self:
		return
	
	var key = event.scancode
	var item_count = _suggestion_popup.get_item_count()
	
	match key:
		KEY_DOWN:
			var idx = _suggestion_popup.get_current_index()
			idx = (idx + 1) % item_count
			_suggestion_popup.set_current_index(idx)
		KEY_UP:
			var idx = _suggestion_popup.get_current_index()
			idx = idx - 1 if idx - 1 >= 0 else item_count - 1
			_suggestion_popup.set_current_index(idx)
		KEY_RIGHT:
			var idx = _suggestion_popup.get_current_index()
			var tag = _suggestion_popup.get_item_text(idx)
			var extent = get_phrase_extent_near_caret()
			var phrase = text.substr(extent[0], extent[1])
			if not tag.begins_with(phrase):
				return
			
			var next_char = tag.substr(phrase.length(), 1)
			var pos = caret_position + 1
			set_text("%s%s%s" % [
				text.substr(0, extent[0]),
				phrase + next_char,
				text.substr(extent[1])
			])
			caret_position = pos
		
		KEY_ESCAPE:
			_suggestion_popup.hide()
		
		KEY_TAB:
			var idx = _suggestion_popup.get_current_index()
			_suggestion_popup.emit_signal("index_pressed", idx)
			_suggestion_popup.hide()
		_:
			return
	
	get_tree().set_input_as_handled()


func _on_SuggestionsPopup_focus_entered() -> void:
	grab_focus()


func _on_SuggestionsPopup_focus_exited() -> void:
	var focused_on = get_focus_owner()
	if not focused_on:
		call_deferred("_deferred_on_SuggestionsPopup_focus_exited")
		return
	
	if focused_on != self:
		_suggestion_popup.hide()


func _deferred_on_SuggestionsPopup_focus_exited() -> void:
	var focused_on = get_focus_owner()
	if focused_on != self:
		_suggestion_popup.hide()


func _on_SuggestionsPopup_idx_pressed(idx: int) -> void:
	var tag = _suggestion_popup.get_item_text(idx)
	
	var extent := get_phrase_extent_near_caret()
	select(extent[0], extent[1])
	var new_text_start:String = text.substr(0, extent[0]) + tag
	var new_text_end:String =  text.substr(extent[1])
	var new_text : String = "%s%s"
	
	if not new_text_start.rstrip(" ").ends_with(",") and new_text_end.begins_with(","):
		new_text_start = "%s, " % [new_text_start.rstrip(" ")]
		new_text_end = new_text_end.substr(1).lstrip(" ")
	elif new_text_end.empty():
		new_text_start = "%s, " % [new_text_start.rstrip(" ")]
	
	new_text = new_text % [new_text_start, new_text_end]
	
	text = new_text
	
	caret_position = new_text_start.length()
	
	emit_signal("text_changed", text)
	
	emit_signal("suggestion_picked", tag)


func _on_SuggestiveLineEdit_text_changed(_new_text:String) -> void:
	_calculate_suggestions()
	if _suggestion_popup.visible:
		var popup_position = _calculate_suggestions_popup_global_position()
		_suggestion_popup.rect_global_position = popup_position


func _on_SuggestiveLineEdit_text_entered(new_text: String) -> void:
	if not new_text.rstrip(" ").ends_with(","):
		new_text = "%s, " % new_text.rstrip(" ")
	
	if not new_text.lstrip(" ").begins_with(","):
		new_text = ", %s" % new_text.lstrip(" ")
	
	text = new_text
