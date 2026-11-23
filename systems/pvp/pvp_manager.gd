class_name NeonPvpManager
extends Node

signal match_started
signal player_scored(player_id: int, score: int)
signal match_finished(winner_id: int)

var state := NeonPvpMatchState.new()
var active := false

func start_match(mode: NeonPvpMatchState.Mode = NeonPvpMatchState.Mode.DEATHMATCH) -> void:
    state = NeonPvpMatchState.new()
    state.mode = mode
    active = true
    match_started.emit()

func register_kill(player_id: int) -> void:
    if not active:
        return
    state.add_kill(player_id)
    player_scored.emit(player_id, state.get_score(player_id))
    if state.get_score(player_id) >= state.score_limit:
        active = false
        match_finished.emit(player_id)
