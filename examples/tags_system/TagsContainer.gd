extends VBoxContainer

const PillLabel := preload("res://addons/jm/more_ui/pill_label/PillLabel.tscn")

onready var grid : GridContainer = $GridContainer
onready var suggestive_edit = $SuggestiveLineEdit

func _ready() -> void:
	
	suggestive_edit.connect("text_changed", self, "_on_SuggestiveLineEdit_text_changed")
	suggestive_edit.connect("calculated_suggestions", self, "_generate_labels_from_suggestive_edit_phrases")


func _generate_labels_from_suggestive_edit_phrases() -> void:
	var phrases:PoolStringArray = suggestive_edit.get_phrases()
	for child in grid.get_children():
		grid.remove_child(child)
	
	for phrase in phrases:
		if phrase.strip_edges().empty():
			continue
		
		var pill = PillLabel.instance()
		pill.set_pill_bg_color(Color(0.6, 0.5, 0.6))
		pill.text = phrase
		grid.add_child(pill)


func _on_SuggestiveLineEdit_text_changed(_t) -> void:
	_generate_labels_from_suggestive_edit_phrases()
