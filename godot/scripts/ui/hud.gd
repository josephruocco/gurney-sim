class_name PrototypeHUD
extends CanvasLayer

var status_label: Label
var telemetry_label: Label
var balance_bar: ProgressBar
var host_button: Button
var join_button: Button
var solo_button: Button

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(380, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fff4de", 0.94)
	panel_style.border_color = Color("#31596c", 0.24)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "GURNEY SIMULATOR — CO-OP PROTOTYPE"
	title.add_theme_color_override("font_color", Color("#31596c"))
	title.add_theme_font_size_override("font_size", 19)
	stack.add_child(title)
	status_label = Label.new()
	status_label.text = "Choose Solo, Host, or Join"
	status_label.add_theme_color_override("font_color", Color("#d97058"))
	stack.add_child(status_label)
	telemetry_label = Label.new()
	telemetry_label.text = "Speed 0 km/h"
	telemetry_label.add_theme_color_override("font_color", Color("#31596c"))
	stack.add_child(telemetry_label)
	var balance_text := Label.new()
	balance_text.text = "BALANCE"
	balance_text.add_theme_color_override("font_color", Color("#31596c"))
	stack.add_child(balance_text)
	balance_bar = ProgressBar.new()
	balance_bar.max_value = 100
	balance_bar.show_percentage = false
	var balance_bg := StyleBoxFlat.new()
	balance_bg.bg_color = Color("#dce9eb")
	balance_bg.set_corner_radius_all(7)
	var balance_fill := StyleBoxFlat.new()
	balance_fill.bg_color = Color("#d97058")
	balance_fill.set_corner_radius_all(7)
	balance_bar.add_theme_stylebox_override("background", balance_bg)
	balance_bar.add_theme_stylebox_override("fill", balance_fill)
	stack.add_child(balance_bar)
	var buttons := HBoxContainer.new()
	stack.add_child(buttons)
	solo_button = Button.new(); solo_button.text = "Solo"
	host_button = Button.new(); host_button.text = "Host"
	join_button = Button.new(); join_button.text = "Join localhost"
	buttons.add_child(solo_button); buttons.add_child(host_button); buttons.add_child(join_button)
	for button in [solo_button, host_button, join_button]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#91c8d3")
		normal.set_corner_radius_all(9)
		normal.content_margin_left = 12
		normal.content_margin_right = 12
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_color_override("font_color", Color("#24495b"))
	var help := Label.new()
	help.text = "WASD move • E grab/release gurney • Space dig in heels"
	help.add_theme_color_override("font_color", Color("#617d87"))
	stack.add_child(help)

func set_telemetry(speed: float, danger: float, patient_offset: float) -> void:
	telemetry_label.text = "Speed %d km/h   Patient drift %.2f m" % [roundi(speed), patient_offset]
	balance_bar.value = danger * 100.0
