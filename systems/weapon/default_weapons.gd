class_name NeonDefaultWeapons
extends RefCounted

static func pistol() -> NeonWeaponData:
    var w := NeonWeaponData.new()
    w.weapon_name = "Pulse Pistol"
    w.magazine_size = 12
    w.reserve_ammo = 96
    w.damage = 28.0
    w.fire_rate = 4.0
    w.reload_time = 1.3
    w.spread = 0.01
    w.automatic = false
    return w

static func smg() -> NeonWeaponData:
    var w := NeonWeaponData.new()
    w.weapon_name = "Neon SMG"
    w.magazine_size = 36
    w.reserve_ammo = 216
    w.damage = 12.0
    w.fire_rate = 13.0
    w.reload_time = 1.7
    w.spread = 0.035
    return w

static func shotgun() -> NeonWeaponData:
    var w := NeonWeaponData.new()
    w.weapon_name = "Arc Shotgun"
    w.magazine_size = 8
    w.reserve_ammo = 64
    w.damage = 16.0
    w.fire_rate = 1.4
    w.reload_time = 2.1
    w.spread = 0.09
    w.automatic = false
    return w

static func plasma() -> NeonWeaponData:
    var w := NeonWeaponData.new()
    w.weapon_name = "Plasma Rifle"
    w.magazine_size = 24
    w.reserve_ammo = 144
    w.damage = 31.0
    w.fire_rate = 6.0
    w.reload_time = 2.0
    w.spread = 0.02
    return w
