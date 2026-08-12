class_name StatusLog
extends Panel

const MAX_MESSAGES: int = 9

@onready var message_label: Label = %LogMessageLabel

var _messages: Array[String] = []


func _ready() -> void:
	clip_contents = true
	resized.connect(_on_panel_resized)
	_update_message_bounds()


func add_message(message: String) -> void:
	var normalized_message: String = message.strip_edges()
	if normalized_message.is_empty():
		return

	_messages.append(normalized_message)
	while _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	_refresh_display()


func get_messages() -> Array[String]:
	return _messages.duplicate()


func _on_panel_resized() -> void:
	_update_message_bounds()


func _update_message_bounds() -> void:
	if message_label == null:
		return
	message_label.position = Vector2(20.0, 72.0)
	message_label.size = Vector2(
		maxf(size.x - 40.0, 1.0),
		maxf(size.y - 92.0, 1.0),
	)
	_refresh_display()


func _refresh_display() -> void:
	if message_label == null:
		return
	var wrapped_messages: PackedStringArray = PackedStringArray()
	for message: String in _messages:
		wrapped_messages.append(_wrap_message(message))
	message_label.text = "\n".join(wrapped_messages)


func _wrap_message(message: String) -> String:
	var font: Font = message_label.get_theme_font("font")
	var font_size: int = message_label.get_theme_font_size("font_size")
	var max_width: float = maxf(message_label.size.x, 1.0)
	var wrapped_lines: PackedStringArray = PackedStringArray()
	for source_line: String in message.split("\n"):
		var current_line: String = ""
		for word: String in source_line.split(" "):
			if word.is_empty():
				continue
			var candidate: String = word if current_line.is_empty() else "%s %s" % [current_line, word]
			if (
				not current_line.is_empty()
				and font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > max_width
			):
				wrapped_lines.append(current_line)
				current_line = word
			else:
				current_line = candidate
		if not current_line.is_empty():
			wrapped_lines.append(current_line)
	return "\n".join(wrapped_lines)
