class_name PrototypeHUD
extends CanvasLayer

var status_label: Label
var telemetry_label: Label
var balance_bar: ProgressBar
var host_button: Button
var join_button: Button
var solo_button: Button
var timer_label: Label
var result_panel: PanelContainer
var result_label: Label
var name_input: LineEdit
var address_input: LineEdit
var roster_label: Label
var ready_button: Button
var lobby_panel: PanelContainer
var internet_label: Label
var relay_input: LineEdit
var room_input: LineEdit
var create_room_button: Button
var join_room_button: Button

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
	title.text = "GURNEY SIMULATOR — PARKING GARAGE"
	title.add_theme_color_override("font_color", Color("#31596c"))
	title.add_theme_font_size_override("font_size", 19)
	stack.add_child(title)
	var objective := Label.new()
	objective.text = "ROOF → STREET  •  GET THE PATIENT DOWN ALIVE"
	objective.add_theme_color_override("font_color", Color("#617d87"))
	objective.add_theme_font_size_override("font_size", 12)
	stack.add_child(objective)
	timer_label = Label.new()
	timer_label.text = "DELIVERY  00:00.0"
	timer_label.add_theme_color_override("font_color", Color("#31596c"))
	timer_label.add_theme_font_size_override("font_size", 16)
	stack.add_child(timer_label)
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
	_build_result_panel()
	_build_lobby_panel()
	_build_room_controls()

func _field(placeholder: String, value: String) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.text = value
	field.custom_minimum_size = Vector2(250, 38)
	return field

func _build_lobby_panel() -> void:
	lobby_panel = PanelContainer.new()
	lobby_panel.position = Vector2(18, 330)
	lobby_panel.custom_minimum_size = Vector2(380, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff4de", 0.96)
	style.border_color = Color("#31596c", 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	lobby_panel.add_theme_stylebox_override("panel", style)
	add_child(lobby_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	lobby_panel.add_child(stack)
	var heading := Label.new()
	heading.text = "SHIFT LOBBY"
	heading.add_theme_color_override("font_color", Color("#31596c"))
	heading.add_theme_font_size_override("font_size", 17)
	stack.add_child(heading)
	name_input = _field("Your name", "Orderly")
	address_input = _field("Host address", "127.0.0.1:8910")
	stack.add_child(name_input)
	stack.add_child(address_input)
	roster_label = Label.new()
	roster_label.text = "No crew connected"
	roster_label.add_theme_color_override("font_color", Color("#31596c"))
	stack.add_child(roster_label)
	internet_label = Label.new()
	internet_label.text = "LAN or public IP:port • host may need UDP port forwarding"
	internet_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	internet_label.add_theme_color_override("font_color", Color("#617d87"))
	internet_label.add_theme_font_size_override("font_size", 11)
	stack.add_child(internet_label)
	ready_button = Button.new()
	ready_button.text = "Ready up"
	ready_button.disabled = true
	stack.add_child(ready_button)

func set_roster(names: Dictionary, ready: Dictionary) -> void:
	var lines: Array[String] = []
	var ids := names.keys()
	ids.sort()
	for id in ids:
		var mark := "READY" if ready.get(id, false) else "NOT READY"
		lines.append("%s  •  %s" % [names[id], mark])
	roster_label.text = "\n".join(lines) if !lines.is_empty() else "No crew connected"

func set_lobby_connected(connected: bool) -> void:
	ready_button.disabled = !connected
	name_input.editable = !connected

func set_internet_status(message: String) -> void:
	internet_label.text = message

func hide_lobby() -> void:
	lobby_panel.visible = false

func show_lobby() -> void:
	lobby_panel.visible = true

func _build_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.position = Vector2(-230, -90)
	result_panel.custom_minimum_size = Vector2(460, 180)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff4de", 0.97)
	style.border_color = Color("#31596c")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	result_panel.add_theme_stylebox_override("panel", style)
	add_child(result_panel)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_color_override("font_color", Color("#31596c"))
	result_label.add_theme_font_size_override("font_size", 24)
	result_panel.add_child(result_label)

func set_telemetry(speed: float, danger: float, patient_offset: float) -> void:
	telemetry_label.text = "Speed %d km/h   Patient drift %.2f m" % [roundi(speed), patient_offset]
	balance_bar.value = danger * 100.0

func set_run_time(seconds: float) -> void:
	var minutes := int(seconds) / 60
	var remaining := fmod(seconds, 60.0)
	timer_label.text = "DELIVERY  %02d:%04.1f" % [minutes, remaining]

func show_result(won: bool, reason: String, seconds: float) -> void:
	result_panel.visible = true
	var heading := "PATIENT DELIVERED!" if won else "SHIFT OVER"
	result_label.text = "%s\n%s\nTime %02d:%04.1f\n\nHost: press R to try again" % [heading, reason, int(seconds) / 60, fmod(seconds, 60.0)]

func hide_result() -> void:
	result_panel.visible = false

func _build_room_controls() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(510, 18)
	panel.custom_minimum_size = Vector2(340, 0)
	add_child(panel)
	var label := Label.new()
	label.text = "PLAY ONLINE — ROOM CODE"
	panel.add_child(label)
	relay_input = _field("Relay server (wss://…)", OS.get_environment("GURNEY_RELAY_URL"))
	panel.add_child(relay_input)
	room_input = _field("Room code from your friend", "")
	room_input.max_length = 8
	panel.add_child(room_input)
	create_room_button = Button.new()
	create_room_button.text = "Create room"
	panel.add_child(create_room_button)
	join_room_button = Button.new()
	join_room_button.text = "Join room"
	panel.add_child(join_room_button)
