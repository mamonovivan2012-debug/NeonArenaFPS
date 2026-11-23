extends Node3D

var player: CharacterBody3D
var cam: Camera3D
var enemies: Array[CharacterBody3D] = []
var hp := 100
var ammo := 30
var score := 0
var cooldown := 0.0
var rng := RandomNumberGenerator.new()
var hud: Label

func _ready():
    rng.randomize()
    _make_world()
    _spawn_player()
    for i in 8: _spawn_enemy(i)
    _make_hud()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
    cooldown = max(0.0, cooldown - delta)
    for e in enemies.duplicate():
        if not is_instance_valid(e):
            enemies.erase(e)
    hud.text = "HP: %d   AMMO: %d   SCORE: %d\nWASD move  |  Mouse aim  |  LMB fire  |  R reload/respawn" % [hp, ammo, score]

func _unhandled_input(event):
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        player.rotate_y(-event.relative.x * 0.002)
        cam.rotate_x(-event.relative.y * 0.002)
        cam.rotation.x = clamp(cam.rotation.x, -1.45, 1.45)
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        _shoot()
    if event is InputEventKey and event.pressed and event.keycode == KEY_R:
        ammo = 30
        if hp <= 0: _respawn()

func _physics_process(delta):
    if hp <= 0: return
    var dir = Vector3.ZERO
    if Input.is_action_pressed("move_forward"): dir -= player.transform.basis.z
    if Input.is_action_pressed("move_back"): dir += player.transform.basis.z
    if Input.is_action_pressed("move_left"): dir -= player.transform.basis.x
    if Input.is_action_pressed("move_right"): dir += player.transform.basis.x
    dir.y = 0
    dir = dir.normalized()
    player.velocity.x = dir.x * 7.0
    player.velocity.z = dir.z * 7.0
    if not player.is_on_floor(): player.velocity.y -= 18.0 * delta
    else: player.velocity.y = -0.5
    player.move_and_slide()
    for e in enemies:
        if is_instance_valid(e):
            var to_p = player.global_position - e.global_position
            to_p.y = 0
            if to_p.length() > 2:
                e.velocity = to_p.normalized() * 2.0
                e.look_at(player.global_position, Vector3.UP)
                e.move_and_slide()
            elif rng.randf() < delta * 0.35:
                hp -= 8

func _make_world():
    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.015,0.02,0.035)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.3,0.35,0.5)
    e.ambient_light_energy = 0.8
    env.environment = e
    add_child(env)
    var light = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55,-25,0)
    light.light_energy = 1.2
    add_child(light)
    _box(Vector3(0,-0.5,0), Vector3(30,1,30), Color(0.08,0.09,0.12))
    for p in [Vector3(0,2,-15),Vector3(0,2,15),Vector3(-15,2,0),Vector3(15,2,0)]:
        _box(p, Vector3(30 if p.x==0 else 1,4,1 if p.x==0 else 30), Color(0.12,0.14,0.18))
    for p in [Vector3(-7,1,-6),Vector3(7,1,-5),Vector3(-5,1,6),Vector3(8,1,7)]:
        _box(p, Vector3(3,2,3), Color(0.18,0.2,0.25))

func _box(pos, size, color):
    var body = StaticBody3D.new()
    body.position = pos
    var mesh = MeshInstance3D.new()
    var bm = BoxMesh.new(); bm.size = size
    mesh.mesh = bm
    var mat = StandardMaterial3D.new(); mat.albedo_color = color
    mesh.material_override = mat
    body.add_child(mesh)
    var cs = CollisionShape3D.new(); var shape = BoxShape3D.new(); shape.size = size
    cs.shape = shape; body.add_child(cs); add_child(body)

func _spawn_player():
    player = CharacterBody3D.new()
    player.position = Vector3(0,1,10)
    add_child(player)
    var shape = CollisionShape3D.new(); var capsule = CapsuleShape3D.new()
    capsule.height = 1.8; capsule.radius = 0.35; shape.shape = capsule; player.add_child(shape)
    cam = Camera3D.new(); cam.position = Vector3(0,0.65,0); player.add_child(cam)
    cam.current = true

func _spawn_enemy(i):
    var e = CharacterBody3D.new()
    e.position = Vector3(rng.randf_range(-11,11),1,rng.randf_range(-10,7))
    if e.position.distance_to(player.position) < 5: e.position.z -= 8
    add_child(e)
    var shape = CollisionShape3D.new(); var capsule = CapsuleShape3D.new()
    capsule.height = 1.8; capsule.radius = 0.45; shape.shape = capsule; e.add_child(shape)
    var mesh = MeshInstance3D.new(); var cm = CapsuleMesh.new()
    cm.height = 1.8; cm.radius = 0.45; mesh.mesh = cm
    var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.85,0.12,0.2); mesh.material_override = mat
    e.add_child(mesh)
    enemies.append(e)

func _shoot():
    if cooldown > 0 or ammo <= 0 or hp <= 0: return
    ammo -= 1; cooldown = 0.12
    var from = cam.global_position
    var to = from + -cam.global_transform.basis.z * 1000
    var q = PhysicsRayQueryParameters3D.create(from,to)
    q.exclude = [player]
    var hit = get_world_3d().direct_space_state.intersect_ray(q)
    if hit and hit.collider in enemies:
        score += 100
        hit.collider.queue_free()

func _respawn():
    hp = 100; ammo = 30; player.position = Vector3(0,1,10)
    for e in enemies: if is_instance_valid(e): e.queue_free()
    enemies.clear()
    for i in 8: _spawn_enemy(i)

func _make_hud():
    hud = Label.new()
    hud.position = Vector2(24,24)
    hud.add_theme_font_size_override("font_size", 22)
    add_child(hud)
