extends CharacterBody3D
# 玩家：第一人称控制 + 开枪
# 鼠标转视角，WASD 走动，空格跳，左键开枪，R 换弹，Esc 松开鼠标

const SPEED := 5.0
const JUMP := 7.0
const GRAVITY := 20.0
const MOUSE_SENS := 0.003

var hp := 100
var max_ammo := 30
var ammo := 30
var reloading := false
var _reload_t := 0.0
var _shoot_cd := 0.0

@onready var cam: Camera3D = $Camera3D
@onready var ray: RayCast3D = $Camera3D/RayCast3D

func _ready() -> void:
	add_to_group("player")
	ray.add_exception(self)  # 不要打到自己
	# 锁定鼠标（无头测试时跳过，免得报错）
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# 鼠标转视角
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		cam.rotate_x(-event.relative.y * MOUSE_SENS)
		cam.rotation.x = clamp(cam.rotation.x, -1.4, 1.4)
	# 左键开枪
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # 点一下重新锁鼠标
		else:
			_try_shoot()
	# R 换弹
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_start_reload()
	# Esc 松开鼠标
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	# 走动
	var input_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.z -= 1.0
	if Input.is_key_pressed(KEY_S): input_dir.z += 1.0
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D): input_dir.x += 1.0
	var dir := (transform.basis * input_dir)
	dir.y = 0.0
	if dir.length() > 0.0:
		dir = dir.normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	# 重力 + 跳
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP
	else:
		velocity.y = 0.0
	move_and_slide()
	# 换弹计时
	if reloading:
		_reload_t -= delta
		if _reload_t <= 0.0:
			reloading = false
			ammo = max_ammo
	if _shoot_cd > 0.0:
		_shoot_cd -= delta

func _try_shoot() -> void:
	if reloading or _shoot_cd > 0.0:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	_shoot_cd = 0.12
	# 射线命中敌人
	if ray.is_colliding():
		var c = ray.get_collider()
		if c and c.is_in_group("enemy") and c.has_method("take_damage"):
			c.take_damage(1)
	if ammo <= 0:
		_start_reload()

func _start_reload() -> void:
	if reloading or ammo == max_ammo:
		return
	reloading = true
	_reload_t = 1.5

func take_damage(d: int) -> void:
	hp -= d
	if hp <= 0:
		hp = 0
		var w = get_tree().get_first_node_in_group("world")
		if w and w.has_method("on_player_died"):
			w.on_player_died()
