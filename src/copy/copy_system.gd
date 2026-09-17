class_name CopySystem
extends Node

## Owns the copies placed in a level: how many are left, where they go, which one is
## removed. The player knows nothing about this system — copies are placed *at* the
## player, not *by* it.

## Emitted whenever the number of available copies changes. The HUD (B6) listens to
## this instead of reaching into the system for the count.
signal copies_changed(remaining: int, total: int)

## The player copies spawn from, and who gets lifted on top of each new copy.
@export var player: PlayerMotor

## The scene instantiated for each copy. Exported rather than preloaded so a level can
## eventually grant a different kind of copy without touching this script.
@export var copy_scene: PackedScene

## This level's rules. The copy limit lives here so that building a level means editing
## a resource, not this script.
@export var level_data: LevelData

## How many copies this level grants, read straight from its data resource.
var copy_limit: int:
	get:
		return level_data.copy_limit

var _placed: Array[PlayerCopy] = []
var _copy_height: float = 0.0

# 📖 Built once and reused: rebuilding the query object on every placement would
# allocate for no reason, and the only field that actually changes is the transform.
var _space_query := PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	# 📖 assert() is stripped from release builds, so these cost nothing in the shipped
	# game while still failing loudly the moment a level is wired up wrong.
	assert(player != null, "CopySystem: assign the Player in the Inspector.")
	assert(copy_scene != null, "CopySystem: assign the copy scene in the Inspector.")
	assert(level_data != null, "CopySystem: assign a LevelData resource in the Inspector.")

	_copy_height = _measure_copy_height()

	var exclusions: Array[RID] = [player.get_rid()]
	_space_query.shape = player.get_collision_shape()
	_space_query.collision_mask = player.collision_mask
	# 📖 margin stays at its 0.0 default on purpose: with any margin, a copy sitting
	# flush against the destination would count as occupying it.
	_space_query.margin = 0.0
	_space_query.exclude = exclusions

	copies_changed.emit(remaining(), copy_limit)


func _physics_process(_delta: float) -> void:
	# 📖 elif, not three ifs: two actions pressed on the same tick would otherwise both
	# run, and "place then undo" in one frame is never what the player meant.
	if InputReader.is_place_copy_pressed():
		try_place()
	elif InputReader.is_undo_copy_pressed():
		undo()
	elif InputReader.is_clear_copies_pressed():
		clear()


## Places a copy at the player's feet and lifts the player on top of it. Returns true
## when a copy was actually placed.
func try_place() -> bool:
	if remaining() <= 0:
		return false

	var copy_position: Vector2 = player.global_position
	# 📖 Player and copy are the same size, so standing on top means moving up by exactly
	# one copy height: the player's feet land on the copy's ceiling.
	var stand_position: Vector2 = copy_position + Vector2.UP * _copy_height

	if _is_occupied(stand_position):
		# Temporary readout until B12 turns this into real in-game feedback.
		print("[CopySystem] blocked: no room above")
		return false

	var copy: PlayerCopy = copy_scene.instantiate()
	# 📖 add_child() first: global_position only means anything once the node has a
	# parent to be global relative to.
	add_child(copy)
	copy.global_position = copy_position

	player.land_at(stand_position)

	_placed.append(copy)
	copies_changed.emit(remaining(), copy_limit)

	print("[CopySystem] placed, remaining ", remaining(), "/", copy_limit)
	return true


## Removes the most recently placed copy. Returns true when one was removed.
## 📖 The player is not moved back: if they were standing on that copy they simply
## fall, which is the outcome physics would give anyway and the one they can predict.
func undo() -> bool:
	if _placed.is_empty():
		return false

	var copy: PlayerCopy = _placed.pop_back()
	# 📖 queue_free(), not free(): the copy may be mid-collision this very frame, and
	# freeing it right now is how you get a crash instead of a bug.
	copy.queue_free()
	copies_changed.emit(remaining(), copy_limit)

	print("[CopySystem] undone, remaining ", remaining(), "/", copy_limit)
	return true


## Removes every placed copy. Returns how many were removed.
func clear() -> int:
	if _placed.is_empty():
		return 0

	var removed: int = _placed.size()
	for copy in _placed:
		copy.queue_free()
	_placed.clear()
	copies_changed.emit(remaining(), copy_limit)

	print("[CopySystem] cleared ", removed, ", remaining ", remaining(), "/", copy_limit)
	return removed


## How many copies the player may still place.
func remaining() -> int:
	return copy_limit - _placed.size()


## True when something already occupies the space the player would stand in.
## 📖 This asks about *overlap*, not contact. test_move() with recovery_as_collision
## answers "would this body touch anything", which counts a copy or a wall sitting
## flush alongside the destination — and those leave the space perfectly free.
func _is_occupied(stand_position: Vector2) -> bool:
	_space_query.transform = Transform2D(player.global_rotation, stand_position)
	var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	# 📖 max_results = 1: the question is whether anything is there, not what.
	# The returned array allocates, but this runs on a key press, never per frame.
	return not space.intersect_shape(_space_query, 1).is_empty()


## Instantiates one copy at load time purely to read its height, so a blocked placement
## later costs no allocation at all.
func _measure_copy_height() -> float:
	var probe: PlayerCopy = copy_scene.instantiate()
	var height: float = probe.get_height()
	probe.queue_free()
	return height
