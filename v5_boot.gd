extends Node

var boot_layer: CanvasLayer
var status_label: Label

func _ready() -> void:
	_show_boot_screen()
	_set_status("BOOT", "Запуск Neon Arena...")
	await get_tree().process_frame

	var packed_scene: PackedScene = load("res://main.tscn") as PackedScene
	if packed_scene == null:
		_fail("Не удалось загрузить main.tscn. Проверь ошибки скрипта main.gd в Godot Output.")
		return

	_set_status("SCENE", "Сцена загружена. Создаю игровой мир...")
	await get_tree().process_frame

	var gameplay := packed_scene.instantiate()
	if gameplay == null:
		_fail("Не удалось создать экземпляр main.tscn.")
		return

	add_child(gameplay)

	_set_status("GAMEPLAY", "Игровая сцена запущена...")
	await get_tree().process_frame
	await get_tree().process_frame

	if is_instance_valid(boot_layer):
		boot_layer.queue_free()


func _show_boot_screen() -> void:
	boot_layer = CanvasLayer.new()
	boot_layer.name = "BootDiagnostics"
	add_child(boot_layer)

	var background := ColorRect.new()
	background.color = Color("#080d18")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boot_layer.add_child(background)

	var title := Label.new()
	title.text = "NEON ARENA"
	title.position = Vector2(48, 42)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#45ddff"))
	boot_layer.add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(52, 108)
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.text = "Подготовка..."
	boot_layer.add_child(status_label)


func _set_status(stage: String, message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = "[%s] %s" % [stage, message]


func _fail(message: String) -> void:
	_set_status("ОШИБКА", message + "\nОткрой Godot → Output / Debugger → Errors.")
	push_error(message)
