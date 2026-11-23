class_name NeonPvpMatchState
extends Resource

enum Mode { DEATHMATCH, TEAM_DEATHMATCH, DUEL }

@export var mode := Mode.DEATHMATCH
@export var score_limit := 30
@export var time_limit_seconds := 600
@export var friendly_fire := false

var player_scores: Dictionary = {}

func add_kill(player_id: int) -> void:
    player_scores[player_id] = int(player_scores.get(player_id, 0)) + 1

func get_score(player_id: int) -> int:
    return int(player_scores.get(player_id, 0))
