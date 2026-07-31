extends Control

@onready var start_button: Button = $CenterContainer/Content/StartButton
@onready var status_label: Label = $CenterContainer/Content/StatusLabel


func _ready() -> void:
	start_button.grab_focus()


func _on_start_button_pressed() -> void:
	status_label.text = "Ready to start!"
