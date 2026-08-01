class_name StatusLog
extends Panel

const MAX_MESSAGES: int = 9

@onready var message_label: Label = %LogMessageLabel

var _messages: Array[String] = []


func add_message(message: String) -> void:
	var normalized_message: String = message.strip_edges()
	if normalized_message.is_empty():
		return

	_messages.append(normalized_message)
	while _messages.size() > MAX_MESSAGES:
		_messages.pop_front()
	message_label.text = "\n".join(_messages)


func get_messages() -> Array[String]:
	return _messages.duplicate()
