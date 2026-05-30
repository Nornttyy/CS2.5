extends Node2D

# 游戏入口场景。玩法尚未确定，先作为占位与启动验证。
func _ready() -> void:
	print("游戏已启动 — Godot ", Engine.get_version_info().string)
