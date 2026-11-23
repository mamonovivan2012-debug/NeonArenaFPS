class_name NeonBotBrain
extends Node

enum Difficulty { EASY, NORMAL, HARD, NIGHTMARE }

@export var difficulty := Difficulty.NORMAL
@export var detection_range := 32.0
@export var reaction_time := 0.35
@export var aim_error := 0.12
@export var aggression := 0.55

var target: Node3D
var think_timer := 0.0

func configure(level: Difficulty) -> void:
    difficulty = level
    match level:
        Difficulty.EASY:
            reaction_time = 0.9
            aim_error = 0.30
            aggression = 0.25
        Difficulty.NORMAL:
            reaction_time = 0.45
            aim_error = 0.16
            aggression = 0.55
        Difficulty.HARD:
            reaction_time = 0.25
            aim_error = 0.08
            aggression = 0.75
        Difficulty.NIGHTMARE:
            reaction_time = 0.12
            aim_error = 0.035
            aggression = 0.95

func _process(delta: float) -> void:
    think_timer -= delta
    if think_timer > 0.0:
        return
    think_timer = reaction_time
    _think()

func _think() -> void:
    # v5 brain hook. Navigation, cover selection and team tactics can be
    # attached here without changing the weapon or player code.
    if is_instance_valid(target):
        return
