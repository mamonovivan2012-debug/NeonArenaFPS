extends Node3D

const MAP_DATA = [
	{"name":"FACTORY","desc":"INDUSTRIAL CORE","accent":Color("#25d9ff"),"base":Color("#18232d"),"floor":Color("#242b32"),"kind":0,"bounds":Vector2(76,58)},
	{"name":"LABORATORY","desc":"HELIX RESEARCH","accent":Color("#b17aff"),"base":Color("#242033"),"floor":Color("#303044"),"kind":1,"bounds":Vector2(68,54)},
	{"name":"CYBER CITY","desc":"NEON DISTRICT","accent":Color("#ff35c8"),"base":Color("#29172b"),"floor":Color("#201a29"),"kind":2,"bounds":Vector2(88,62)},
	{"name":"UNDERGROUND","desc":"METRO SECTOR 09","accent":Color("#ffad45"),"base":Color("#30251b"),"floor":Color("#292522"),"kind":3,"bounds":Vector2(78,52)},
	{"name":"SPACEPORT","desc":"ORBITAL TERMINAL","accent":Color("#6dffae"),"base":Color("#142a29"),"floor":Color("#1d2a2a"),"kind":4,"bounds":Vector2(94,66)},
	{"name":"WASTELAND","desc":"DEAD ZONE","accent":Color("#ff5a55"),"base":Color("#332522"),"floor":Color("#3a2b25"),"kind":5,"bounds":Vector2(100,72)}
]

var map_index := 0
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var hp_label: Label
var ammo_label: Label
var title_label: Label
var score_label: Label
var status_label: Label
var enemies: Array[CharacterBody3D] = []
var hp := 100
var ammo := 30
var reserve := 180
var score := 0
var fire_timer := 0.0
var reload_timer := 0.0
var pitch := 0.0
var yaw := 0.0
var rng := RandomNumberGenerator.new()
var weapon_root: Node3D
var muzzle_light: OmniLight3D
var map_root: Node3D
var reload_token := 0

func _ready():
	rng.randomize()
	_build_player()
	_build_hud()
	load_map(0)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.002
		pitch = clamp(pitch - event.relative.y * 0.002, -1.35, 1.35)
		player.rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			load_map(event.keycode - KEY_1)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	fire_timer = maxf(0.0, fire_timer - delta)
	reload_timer = maxf(0.0, reload_timer - delta)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_move_player(delta)
		if Input.is_action_pressed("shoot"):
			_shoot()
		if Input.is_action_just_pressed("reload"):
			_reload()
		if Input.is_action_just_pressed("jump") and player.is_on_floor():
			player.velocity.y = 7.0
	_update_enemies(delta)
	_update_hud()

func _physics_process(delta):
	if is_instance_valid(player):
		player.velocity.y -= 20.0 * delta
		player.move_and_slide()
		if player.global_position.y < -12.0:
			_respawn()

func _move_player(delta):
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	var dir := (player.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := 12.0 if Input.is_action_pressed("sprint") else 8.5
	player.velocity.x = move_toward(player.velocity.x, dir.x * speed, 42.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, dir.z * speed, 42.0 * delta)

func load_map(index:int):
	map_index = clampi(index, 0, MAP_DATA.size()-1)
	var d = MAP_DATA[map_index]
	if is_instance_valid(map_root):
		map_root.queue_free()
	map_root = Node3D.new()
	map_root.name = "Map_" + str(map_index+1)
	add_child(map_root)
	_build_environment(d)
	_build_map_geometry(d)
	player.global_position = Vector3(0, 1.2, 0)
	player.velocity = Vector3.ZERO
	yaw = 0
	pitch = 0
	player.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	hp = 100
	ammo = 30
	reserve = 180
	_spawn_enemies(8 + map_index * 2)
	status_label.text = "MAP %d / 6    PRESS 1-6 TO CHANGE MAP" % (map_index+1)

func _material(color:Color, metal:float=0.0, rough:float=0.55, glow:Color=Color.BLACK):
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	if glow != Color.BLACK:
		m.emission_enabled = true
		m.emission = glow
		m.emission_energy_multiplier = 2.8
	return m

func _add_box(parent:Node3D, pos:Vector3, size:Vector3, mat:Material, collision:=false):
	var body:Node3D
	if collision:
		var static_body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		static_body.add_child(cs)
		body = static_body
	else:
		body = Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	body.position = pos
	parent.add_child(body)
	return body

func _add_cylinder(parent:Node3D, pos:Vector3, radius:float, height:float, mat:Material):
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _build_environment(d):
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = d.base.darkened(0.65)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = d.accent.lerp(Color.WHITE, 0.45)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 1.15
	env.glow_strength = 1.35
	env.glow_bloom = 0.12
	env.fog_enabled = true
	env.fog_light_color = d.base.lightened(0.25)
	env.fog_density = 0.012 if map_index != 5 else 0.025
	world.environment = env
	map_root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color(0.72,0.82,1.0) if map_index != 5 else Color(1.0,0.68,0.42)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	map_root.add_child(sun)

func _build_map_geometry(d):
	var b:Vector2 = d.bounds
	var floor_mat = _material(d.floor, 0.42, 0.48)
	var wall_mat = _material(d.base, 0.62, 0.36)
	var accent_mat = _material(d.accent, 0.25, 0.25, d.accent)
	var dark_mat = _material(Color("#080d14"), 0.8, 0.24)
	_add_box(map_root, Vector3(0,-0.55,0), Vector3(b.x,1,b.y), floor_mat, true)
	# Perimeter with thick structural walls and glowing trim.
	_add_box(map_root, Vector3(0,4,-b.y/2), Vector3(b.x,8,1.5), wall_mat, true)
	_add_box(map_root, Vector3(0,4,b.y/2), Vector3(b.x,8,1.5), wall_mat, true)
	_add_box(map_root, Vector3(-b.x/2,4,0), Vector3(1.5,8,b.y), wall_mat, true)
	_add_box(map_root, Vector3(b.x/2,4,0), Vector3(1.5,8,b.y), wall_mat, true)
	for x in range(-int(b.x/2)+3, int(b.x/2), 6):
		_add_box(map_root, Vector3(x,0.04,0), Vector3(0.08,0.08,b.y-4), accent_mat)
	for z in range(-int(b.y/2)+3, int(b.y/2), 6):
		_add_box(map_root, Vector3(0,0.05,z), Vector3(b.x-4,0.08,0.08), dark_mat)
	# Map-specific landmarks, lanes, verticality and cover.
	match map_index:
		0: _factory_layout(b, wall_mat, accent_mat, dark_mat)
		1: _lab_layout(b, wall_mat, accent_mat, dark_mat)
		2: _city_layout(b, wall_mat, accent_mat, dark_mat)
		3: _metro_layout(b, wall_mat, accent_mat, dark_mat)
		4: _spaceport_layout(b, wall_mat, accent_mat, dark_mat)
		5: _wasteland_layout(b, wall_mat, accent_mat, dark_mat)
	# Common clutter and accent lights.
	for i in range(18):
		var x = rng.randf_range(-b.x*0.43,b.x*0.43)
		var z = rng.randf_range(-b.y*0.43,b.y*0.43)
		if Vector2(x,z).length() < 11: continue
		var h = rng.randf_range(0.6,2.2)
		_add_box(map_root, Vector3(x,h/2,z), Vector3(rng.randf_range(0.8,2.0),h,rng.randf_range(0.8,2.0)), wall_mat, true)
	for i in range(12):
		var light := OmniLight3D.new()
		light.position = Vector3(rng.randf_range(-b.x*0.42,b.x*0.42),rng.randf_range(3.0,6.0),rng.randf_range(-b.y*0.42,b.y*0.42))
		light.light_color = d.accent
		light.light_energy = 2.2
		light.omni_range = 11
		light.shadow_enabled = i < 4
		map_root.add_child(light)

func _cover_line(z:float, count:int, mat:Material, accent:Material):
	for i in range(count):
		var x = (float(i)-float(count-1)/2.0)*5.5
		_add_box(map_root, Vector3(x,0.75,z), Vector3(3.3,1.5,1.1), mat, true)
		_add_box(map_root, Vector3(x,1.55,z), Vector3(3.3,0.08,1.12), accent)

func _factory_layout(b, wall, accent, dark):
	for x in [-24,-12,12,24]:
		_add_box(map_root, Vector3(x,5,-8), Vector3(1.3,10,1.3), wall, true)
		_add_box(map_root, Vector3(x,10,-8), Vector3(5,0.35,1.8), accent)
	for z in [-18,18]:
		_cover_line(z,7,wall,accent)
	for x in [-28,28]:
		_add_box(map_root, Vector3(x,2,0), Vector3(5,4,9), dark, true)
		_add_cylinder(map_root, Vector3(x,5,0), 1.2, 6, wall)
	_add_box(map_root, Vector3(0,7,-22), Vector3(30,0.8,1.2), wall, true)
	_add_box(map_root, Vector3(0,7,-22.6), Vector3(30,0.12,0.12), accent)

func _lab_layout(b, wall, accent, dark):
	for x in [-20,0,20]:
		_add_box(map_root, Vector3(x,1.5,0), Vector3(7,3,7), dark, true)
		_add_cylinder(map_root, Vector3(x,4.0,0), 2.1, 1.2, accent)
		_add_cylinder(map_root, Vector3(x,5.1,0), 1.7, 1.0, wall)
	for z in [-18,18]:
		_add_box(map_root, Vector3(0,2,z), Vector3(38,4,1.2), wall, true)
	for x in [-27,27]:
		_add_box(map_root, Vector3(x,3,0), Vector3(1,6,34), accent, true)
	_add_box(map_root, Vector3(0,0.5,-22), Vector3(16,1,5), dark, true)

func _city_layout(b, wall, accent, dark):
	for x in [-30,-15,15,30]:
		var h = rng.randf_range(8,15)
		_add_box(map_root, Vector3(x,h/2,-19), Vector3(10,h,8), wall, true)
		_add_box(map_root, Vector3(x,h+0.1,-14.9), Vector3(8,0.18,0.1), accent)
		_add_box(map_root, Vector3(x,h/2,20), Vector3(10,h,8), dark, true)
		_add_box(map_root, Vector3(x,h+0.1,15.9), Vector3(8,0.18,0.1), accent)
	_cover_line(0,7,wall,accent)
	for x in [-36,36]:
		_add_box(map_root, Vector3(x,5,0), Vector3(2,10,50), wall, true)
	_add_box(map_root, Vector3(0,9,-23), Vector3(70,0.7,1), dark, true)

func _metro_layout(b, wall, accent, dark):
	for z in [-16,16]:
		_add_box(map_root, Vector3(0,5,z), Vector3(b.x-4,10,1.2), wall, true)
		_add_box(map_root, Vector3(0,10.3,z), Vector3(b.x-4,0.16,0.18), accent)
	for x in [-25,25]:
		_add_box(map_root, Vector3(x,3,0), Vector3(2,6,34), dark, true)
		_add_box(map_root, Vector3(x,6.2,0), Vector3(2.3,0.18,34), accent)
	for z in [-8,8]:
		_add_box(map_root, Vector3(0,0.6,z), Vector3(44,1.2,2), wall, true)
	_add_cylinder(map_root, Vector3(0,1.2,-20), 3.5, 1.4, dark)

func _spaceport_layout(b, wall, accent, dark):
	for x in [-30,30]:
		_add_box(map_root, Vector3(x,7,0), Vector3(3,14,b.y-8), wall, true)
		for z in range(-24,25,8):
			_add_box(map_root, Vector3(x,14.2,z), Vector3(4,0.18,2), accent)
	_add_box(map_root, Vector3(0,1.4,-20), Vector3(22,2.8,10), dark, true)
	_add_box(map_root, Vector3(0,3,-20), Vector3(17,0.18,7), accent)
	for x in [-18,18]:
		_add_cylinder(map_root, Vector3(x,3,12), 3.5, 6, wall)
		_add_cylinder(map_root, Vector3(x,6.2,12), 2.6, 0.2, accent)
	_cover_line(0,7,wall,accent)

func _wasteland_layout(b, wall, accent, dark):
	for i in range(24):
		var x = rng.randf_range(-b.x*0.43,b.x*0.43)
		var z = rng.randf_range(-b.y*0.43,b.y*0.43)
		if Vector2(x,z).length() < 10: continue
		var size = rng.randf_range(2.0,5.5)
		_add_box(map_root, Vector3(x,size*0.35,z), Vector3(size,size*0.7,size*0.8), wall, true)
	for x in [-30,-10,10,30]:
		_add_box(map_root, Vector3(x,2,-20), Vector3(1,4,12), dark, true)
		_add_box(map_root, Vector3(x+2,4,-20), Vector3(5,0.18,0.18), accent)
	_cover_line(15,5,wall,accent)

func _build_player():
	player = CharacterBody3D.new()
	player.name = "Player"
	add_child(player)
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.36
	col.shape = capsule
	col.position.y = 0.9
	player.add_child(col)
	camera = Camera3D.new()
	camera.position = Vector3(0,1.55,0)
	camera.current = true
	camera.fov = 84
	player.add_child(camera)
	weapon_root = Node3D.new()
	weapon_root.position = Vector3(0.32,-0.28,-0.68)
	camera.add_child(weapon_root)
	var gunmat = _material(Color("#171e28"),0.88,0.22)
	var gripmat = _material(Color("#394654"),0.55,0.3)
	_local_box(weapon_root,Vector3(0.0,0.0,0.0),Vector3(0.34,0.22,0.88),gunmat)
	_local_box(weapon_root,Vector3(0,-0.16,0.17),Vector3(0.18,0.32,0.22),gripmat)
	_local_box(weapon_root,Vector3(0,0,-0.55),Vector3(0.12,0.12,0.55),gripmat)
	_local_box(weapon_root,Vector3(0,0.14,-0.05),Vector3(0.24,0.045,0.42),_material(Color("#2bdfff"),0.2,0.2,Color("#2bdfff")))
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = Vector3(0,0,-0.88)
	muzzle_light.light_color = Color("#ffcf7a")
	muzzle_light.omni_range = 5
	muzzle_light.light_energy = 0
	weapon_root.add_child(muzzle_light)

func _local_box(parent,pos,size,mat):
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)

func _build_hud():
	hud = CanvasLayer.new()
	add_child(hud)
	title_label = _hud_label("NEON ARENA",Vector2(28,20),26,Color("#4be6ff"))
	hp_label = _hud_label("HP 100",Vector2(28,820),28,Color("#8dffbb"))
	ammo_label = _hud_label("30 / 180",Vector2(1370,810),32,Color("#ffffff"))
	score_label = _hud_label("SCORE 000000",Vector2(28,58),18,Color("#ffffff"))
	status_label = _hud_label("MAP 1 / 6",Vector2(28,90),16,Color("#9fb8ca"))
	var cross := _hud_label("+",Vector2(792,432),30,Color("#ffffff"))
	cross.add_theme_color_override("font_shadow_color",Color("#2bdfff"))
	cross.add_theme_constant_override("shadow_offset_x",1)
	cross.add_theme_constant_override("shadow_offset_y",1)
	_hud_label("WASD MOVE   SHIFT SPRINT   SPACE JUMP   LMB FIRE   R RELOAD   1-6 MAPS",Vector2(28,866),16,Color("#a9bdcc"))

func _hud_label(text:String,pos:Vector2,size:int,color:Color):
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	hud.add_child(label)
	return label

func _shoot():
	if fire_timer > 0 or reload_timer > 0: return
	if ammo <= 0:
		_reload()
		return
	ammo -= 1
	fire_timer = 0.095
	muzzle_light.light_energy = 10
	get_tree().create_timer(0.055).timeout.connect(func():
		if is_instance_valid(muzzle_light): muzzle_light.light_energy = 0
	)
	var origin = camera.global_position
	var end = origin - camera.global_transform.basis.z * 150
	var query = PhysicsRayQueryParameters3D.create(origin,end)
	query.exclude = [player]
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		_spawn_impact(result.position, MAP_DATA[map_index].accent)
		var target = result.collider
		if target is Node and target.has_meta("enemy"):
			target.set_meta("health",int(target.get_meta("health"))-34)
			if int(target.get_meta("health")) <= 0:
				score += 100
				enemies.erase(target)
				target.queue_free()
				if enemies.is_empty(): _spawn_enemies(8 + map_index*2)

func _spawn_impact(pos:Vector3,color:Color):
	var particles := GPUParticles3D.new()
	particles.amount = 22
	particles.lifetime = 0.42
	particles.one_shot = true
	particles.position = pos
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0,1,0)
	pm.spread = 180
	pm.initial_velocity_min = 1.8
	pm.initial_velocity_max = 5.5
	pm.gravity = Vector3(0,-8,0)
	pm.scale_min = 0.035
	pm.scale_max = 0.09
	pm.color = color
	particles.process_material = pm
	var sphere := SphereMesh.new()
	sphere.radius = 0.045
	sphere.height = 0.09
	particles.draw_pass_1 = sphere
	map_root.add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(particles): particles.queue_free()
	)

func _reload():
	if reload_timer > 0 or ammo >= 30 or reserve <= 0: return
	reload_timer = 1.35
	var amount = min(30-ammo,reserve)
	ammo += amount
	reserve -= amount

func _spawn_enemies(count:int):
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	for i in range(count):
		var enemy := CharacterBody3D.new()
		enemy.name = "Sentinel"
		enemy.set_meta("enemy",true)
		enemy.set_meta("health",100 + map_index*12)
		var angle = TAU * float(i) / float(count)
		enemy.position = Vector3(cos(angle)*rng.randf_range(19,29),0,sin(angle)*rng.randf_range(15,23))
		var col := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.height = 2.0
		shape.radius = 0.48
		col.shape = shape
		col.position.y = 1
		enemy.add_child(col)
		var body := MeshInstance3D.new()
		var capsule_mesh := CapsuleMesh.new()
		capsule_mesh.height = 2.0
		capsule_mesh.radius = 0.48
		body.mesh = capsule_mesh
		body.position.y = 1
		body.material_override = _material(Color("#b52642"),0.55,0.25,Color("#5a1028"))
		enemy.add_child(body)
		var eye := MeshInstance3D.new()
		var eye_mesh := BoxMesh.new()
		eye_mesh.size = Vector3(0.48,0.08,0.08)
		eye.mesh = eye_mesh
		eye.position = Vector3(0,1.5,-0.43)
		eye.material_override = _material(MAP_DATA[map_index].accent,0.1,0.18,MAP_DATA[map_index].accent)
		enemy.add_child(eye)
		map_root.add_child(enemy)
		enemies.append(enemy)

func _update_enemies(delta):
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy): continue
		var direction = player.global_position - enemy.global_position
		direction.y = 0
		if direction.length() > 2.2:
			var move = direction.normalized()
			enemy.velocity.x = move.x * 2.5
			enemy.velocity.z = move.z * 2.5
			enemy.look_at(Vector3(player.global_position.x,enemy.global_position.y,player.global_position.z),Vector3.UP)
			enemy.move_and_slide()
		else:
			hp = maxi(0,hp-int(18*delta))
			if hp == 0: _respawn()

func _respawn():
	hp = 100
	ammo = 30
	player.global_position = Vector3(0,1.2,0)
	player.velocity = Vector3.ZERO

func _update_hud():
	if not is_instance_valid(hud): return
	var d = MAP_DATA[map_index]
	title_label.text = "NEON ARENA  //  " + d.name
	hp_label.text = "HP  %03d" % hp
	ammo_label.text = "%02d  /  %03d" % [ammo,reserve]
	score_label.text = "SCORE  %06d" % score
	status_label.text = "%s  //  %s    |    ENEMIES %02d" % [d.name,d.desc,enemies.size()]
