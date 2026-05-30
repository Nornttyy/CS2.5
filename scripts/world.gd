extends Node3D
# 沙漠小镇世界：读取 maps/desert_town.json，搭成 3D 地图
# 2D 编辑器里的坐标(px) → 3D 世界坐标(米)：每 10 像素 = 1 米

const DIV := 8.0       # 多少像素算 1 米（数值越小，地图越大）
const MAP_W := 760.0   # 2D 地图宽
const MAP_H := 580.0   # 2D 地图高
const HEIGHTS := {"house": 3.4, "barrier": 1.6, "crate": 1.5}
const COLORS := {
	"house": Color(0.79, 0.66, 0.42),
	"barrier": Color(0.35, 0.70, 0.88),
	"crate": Color(0.66, 0.46, 0.24),
}

func _ready() -> void:
	add_to_group("world")
	_setup_light_and_sky()
	_build_floor_and_walls()
	_build_from_map()

# 把 2D 像素坐标转成 3D 世界坐标（地图中心 = 世界原点）
func _to_world(px: float, py: float) -> Vector3:
	return Vector3((px - MAP_W / 2.0) / DIV, 0.0, (py - MAP_H / 2.0) / DIV)

func _setup_light_and_sky() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.72, 0.9)   # 天空蓝
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.73, 0.68)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-40), 0.0)
	sun.light_energy = 1.1
	add_child(sun)

func _build_floor_and_walls() -> void:
	var w := MAP_W / DIV
	var d := MAP_H / DIV
	# 沙地地板
	_static_box(Vector3(0, -0.5, 0), Vector3(w, 1.0, d), Color(0.89, 0.79, 0.55), 0.0)
	# 四面围墙（别走出地图）
	var t := 1.0
	var hh := 4.0
	_static_box(Vector3(0, hh / 2, -d / 2), Vector3(w, hh, t), Color(0.61, 0.48, 0.27), 0.0)
	_static_box(Vector3(0, hh / 2, d / 2), Vector3(w, hh, t), Color(0.61, 0.48, 0.27), 0.0)
	_static_box(Vector3(-w / 2, hh / 2, 0), Vector3(t, hh, d), Color(0.61, 0.48, 0.27), 0.0)
	_static_box(Vector3(w / 2, hh / 2, 0), Vector3(t, hh, d), Color(0.61, 0.48, 0.27), 0.0)

func _build_from_map() -> void:
	var items := _load_map()
	var ct_pos := Vector3(0, 0, 10)   # 默认警察出生点
	for it in items:
		var ty: String = it.get("type", "")
		if ty == "route":
			continue
		if ty == "tspawn" or ty == "ctspawn":
			var c := _to_world(it["x"] + it["w"] / 2.0, it["y"] + it["h"] / 2.0)
			var col := Color(0.94, 0.64, 0.35) if ty == "tspawn" else Color(0.44, 0.71, 0.88)
			_visual_box(Vector3(c.x, 0.06, c.z), Vector3(it["w"] / DIV, 0.1, it["h"] / DIV), col, 0.0)
			_label(c + Vector3(0, 2.2, 0), "🥷出生" if ty == "tspawn" else "👮出生")
			if ty == "ctspawn":
				ct_pos = c
			continue
		if ty == "A" or ty == "B":
			var c2 := _to_world(it["x"] + it["w"] / 2.0, it["y"] + it["h"] / 2.0)
			_visual_box(Vector3(c2.x, 0.07, c2.z), Vector3(it["w"] / DIV, 0.12, it["h"] / DIV), Color(0.85, 0.25, 0.25, 0.55), 0.0)
			_label(c2 + Vector3(0, 2.6, 0), ty + " 点 💣")
			continue
		# house / barrier / crate → 实体方块
		if HEIGHTS.has(ty):
			var h: float = HEIGHTS[ty]
			var c3 := _to_world(it["x"] + it["w"] / 2.0, it["y"] + it["h"] / 2.0)
			var rot: float = it.get("rot", 0.0)
			_static_box(Vector3(c3.x, h / 2.0, c3.z), Vector3(it["w"] / DIV, h, it["h"] / DIV), COLORS[ty], -rot)
	# 把玩家放到警察出生点
	var p := get_node_or_null("Player")
	if p:
		p.global_position = Vector3(ct_pos.x, 1.5, ct_pos.z)

func _load_map() -> Array:
	var path := "res://maps/desert_town.json"
	if not FileAccess.file_exists(path):
		push_warning("找不到地图文件: " + path)
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if typeof(data) == TYPE_ARRAY else []

# 带碰撞的方块（墙、房子、箱子）
func _static_box(center: Vector3, size: Vector3, color: Color, rot_y: float) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = size
	col.shape = shp
	body.add_child(col)
	body.add_child(_make_mesh(size, color))
	body.position = center
	body.rotation.y = rot_y
	add_child(body)

# 只看不挡（地面标记、出生点、A/B 区）
func _visual_box(center: Vector3, size: Vector3, color: Color, rot_y: float) -> void:
	var m := _make_mesh(size, color)
	m.position = center
	m.rotation.y = rot_y
	add_child(m)

func _make_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	m.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	return m

func _label(pos: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	add_child(l)
