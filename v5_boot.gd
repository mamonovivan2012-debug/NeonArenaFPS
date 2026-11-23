extends Node

# Neon Arena v5 boot/diagnostic controller.
# This script deliberately starts with no post-processing or heavy effects.
# It proves that the scene tree, viewport and gameplay scene can initialize.

signal boot_ready
signal boot_failed(reason: String)

var status_label: Label
var stage := "BOOT"

func _ready() -> void:
    _make_boot_ui()
    _set_stage("BOOT", "Starting Neon Arena v5...")
    await get_tree().process_frame

    _set_stage("SCENE", "Scene tree online")
    await get_tree().process_frame

    var main_scene := load("res://main.tscn")
    if main_scene == null:
        _fail("Could not load res://main.tscn")
        return

    _set_stage("GAMEPLAY", "Gameplay scene found")
    await get_tree().process_frame

    # Do not instantiate a second gameplay scene if the current scene already is it.
    # This boot script is intended as a diagnostic scene or autoload, not a replacement.
    _set_stage("RENDER", "Renderer online")
    await get_tree().process_frame

    _set_stage("READY", "NEON ARENA READY")
    boot_ready.emit()

func _make_boot_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "V5BootLayer"
    add_child(layer)

    var panel := ColorRect.new()
    panel.color = Color("#070b14")
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(panel)

    var title := Label.new()
    title.text = "NEON ARENA // V5"
    title.position = Vector2(70, 60)
    title.add_theme_font_size_override("font_size", 34)
    layer.add_child(title)

    status_label = Label.new()
    status_label.text = "BOOT"
    status_label.position = Vector2(72, 120)
    status_label.add_theme_font_size_override("font_size", 22)
    layer.add_child(status_label)

func _set_stage(new_stage: String, message: String) -> void:
    stage = new_stage
    if is_instance_valid(status_label):
        status_label.text = "[%s]  %s" % [new_stage, message]

func _fail(reason: String) -> void:
    _set_stage("ERROR", reason)
    boot_failed.emit(reason)
