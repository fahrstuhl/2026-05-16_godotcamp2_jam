extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for enemy in $Enemies.get_children():
		enemy.retarget.connect(_on_enemy_retarget)

func _on_enemy_retarget(enemy) -> void:
	enemy.set_movement_target(%Player.global_position)
