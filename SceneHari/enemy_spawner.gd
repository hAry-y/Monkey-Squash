extends Node3D

var enemy_scene =  preload("res://SceneHari/enemy_ai.tscn")


@export var spawn_interval: float = 5.0
@export var min_spawn_dist: float = 20.0
@export var max_spawn_dist: float = 40.0

@onready var main_character = get_node("/root/Node3D/CharacterBody3D")
@onready var enemy_container = get_node("/root/Node3D/ENEMY")

var timer: float = 0.0