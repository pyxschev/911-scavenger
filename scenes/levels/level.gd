extends Node
class_name Level

var next_level : PackedScene

@export var level_num : int

@export var flip_blocks : bool
@export var flip_timer : float
var tik_flags = [false, false, false]

@onready var playerRespawn : Vector2 = $Player.position

@export var outerwidth : float
@export var outerheight : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if (flip_blocks):
		$TickTimer.start(flip_timer)
		$TickTimer.connect("timeout", $Player.flip_collision)
	
	# Gives the level objects references to the player and the level
	for child in get_children():
		if (child is LevelObject):
			child.player = $Player
			child.level = self
			
	#$LevelTileMap.update_internals()
	for child in $LevelTileMap.get_children():
		if (child is LevelObject):
			child.player = $Player
			child.level = self
	# Give the player a reference to the tile map
	$Player.tile_map_layer = $LevelTileMap

	$Camera2D.set_limits(get_limits())
	
	#$"Previous Level Image".texture = load()

func _input(event) -> void:
	# pause button pressed!
	if event.is_action_pressed("ui_cancel"):
		Global.play_button_press_sound()
		Global.pause_game()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# center camera on the player
	$Camera2D.global_position = $Player.position
	
	for i in range(0, 3):
		if (!tik_flags[i] and $TickTimer.time_left <= (i+1) * flip_timer/4):
			tik_flags[i] = true
			if $SmallTickSound:
				$SmallTickSound.play()

# return the boundaries of the level
func get_limits() -> Rect2i:
	# rectangle used by tileset in tile units
	var used_rect: Rect2i = $LevelTileMap.get_used_rect()
	var tile_size: Vector2i = $LevelTileMap.tile_set.tile_size
	
	used_rect.position.x -= outerwidth
	used_rect.position.y -= outerheight
	used_rect.position.x *= tile_size.x
	used_rect.position.y *= tile_size.y
	used_rect.size.x += outerwidth * 2
	used_rect.size.y += outerheight * 2
	used_rect.size.x *= tile_size.x
	used_rect.size.y *= tile_size.y
	
	return used_rect

# loads the next level scene and bring up level cleared screen
func level_cleared(level_path : String) -> void:
	Global.prev_level = Global.current_level
	var next_level = randi_range(1, Global.total_levels - 1)
	Global.current_level = next_level
	$ClearScreen.show()
	Global.levels_cleared += 1
	var game_scene = load(Global.levels[next_level]) as PackedScene
	Global.change_level(game_scene)
	
func attempt_exit():
	$Confirm.show()
	$Confirm/CenterContainer/VBoxContainer/Yes.grab_focus()
	get_tree().paused = true

func _on_yes_pressed():
	#Yes
	get_tree().paused = false
	$Confirm.hide()
	var clear = load("res://scenes/game/clear_screen.tscn") as PackedScene
	Global.change_level(clear)

func _on_no_pressed():
	#no
	get_tree().paused = false
	$Confirm.hide()
	

func _on_player_player_dead():
	var clear = load("res://scenes/game/clear_screen.tscn") as PackedScene
	Global.change_level(clear)

const greenTilesheets = [preload("res://assets/art/flip_block_green_off_tilesheet.png"),
						 preload("res://assets/art/flip_block_green_on_tilesheet.png")]
const pinkTilesheets = [preload("res://assets/art/flip_block_pink_off_tilesheet.png"),
						preload("res://assets/art/flip_block_pink_on_tilesheet.png")]

# for flipping appearance of blocks
var tick : bool = 0
func _on_tick_timer_timeout():
	tik_flags = [false, false, false]
	if $BigTickSound:
		$BigTickSound.play()
	
	tick = !tick 
	var ts : TileSet = $LevelTileMap.tile_set
	ts.get_source(ts.get_source_id(2)).texture = greenTilesheets[int(!tick)]
	ts.get_source(ts.get_source_id(3)).texture = pinkTilesheets[int(tick)]

func set_respawn(pos : Vector2):
	playerRespawn = pos
