class_name NeonWeaponSystem
extends Node

signal fired(weapon: NeonWeaponData)
signal ammo_changed(current: int, reserve: int)
signal reloaded

var weapon: NeonWeaponData
var ammo := 0
var reserve := 0
var cooldown := 0.0
var reload_timer := 0.0
var is_reloading := false

func equip(data: NeonWeaponData) -> void:
    weapon = data
    ammo = data.magazine_size
    reserve = data.reserve_ammo
    cooldown = 0.0
    is_reloading = false
    ammo_changed.emit(ammo, reserve)

func tick(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if is_reloading:
        reload_timer -= delta
        if reload_timer <= 0.0:
            _finish_reload()

func can_fire() -> bool:
    return weapon != null and not is_reloading and ammo > 0 and cooldown <= 0.0

func fire() -> bool:
    if not can_fire():
        return false
    ammo -= 1
    cooldown = 1.0 / maxf(weapon.fire_rate, 0.1)
    fired.emit(weapon)
    ammo_changed.emit(ammo, reserve)
    return true

func reload() -> void:
    if weapon == null or is_reloading:
        return
    if ammo >= weapon.magazine_size or reserve <= 0:
        return
    is_reloading = true
    reload_timer = weapon.reload_time

func _finish_reload() -> void:
    var needed := weapon.magazine_size - ammo
    var amount := mini(needed, reserve)
    ammo += amount
    reserve -= amount
    is_reloading = false
    reload_timer = 0.0
    ammo_changed.emit(ammo, reserve)
    reloaded.emit()
