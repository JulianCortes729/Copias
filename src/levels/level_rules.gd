class_name LevelRules
extends Node

## The only thing that decides whether a level is won.
##
## The goal and, later, the death zones merely report that something touched them. Every
## rule about what that means — whose body counts, what happens next, what is ignored
## once the level is over — lives here and nowhere else.

## Emitted once, when the level becomes completed.
signal completed

## The player whose body is the only one that can complete this level.
@export var player: PlayerMotor

## The area the player has to reach to finish the level.
@export var goal: Area2D

## Where the player stands when this level starts or restarts.
@export var start_marker: Marker2D

## The areas that kill the player in this level. R4.4 — a level may declare none, one or
## many. Wired by hand rather than discovered by searching the tree: an empty list has to
## mean "this level has no death zones", not "the search found nothing".
@export var death_zones: Array[Area2D] = []

## The copy system of this level, reset along with everything else.
@export var copy_system: CopySystem

## This level's rules. LevelRules owns it and hands it to whoever needs it, so a level
## declares its data exactly once.
@export var level_data: LevelData

var _completed: bool = false


func _ready() -> void:
	assert(player != null, "LevelRules: assign the Player in the Inspector.")
	assert(goal != null, "LevelRules: assign the Goal in the Inspector.")
	assert(start_marker != null, "LevelRules: assign the LevelStart marker in the Inspector.")
	assert(copy_system != null, "LevelRules: assign the CopySystem in the Inspector.")
	assert(level_data != null, "LevelRules: assign a LevelData resource in the Inspector.")

	goal.body_entered.connect(_on_goal_body_entered)

	for zone in death_zones:
		assert(zone != null, "LevelRules: one of the Death Zones entries is empty.")
		zone.body_entered.connect(_on_death_zone_body_entered)

	# D5 — the copy system gets its data from here, never from its own Inspector slot.
	copy_system.setup(level_data)

	# R3.1, R3.2 — a level always begins the same way, whatever the previous attempt did
	# and wherever the player node happened to be left in the editor.
	restart()


func _physics_process(_delta: float) -> void:
	if InputReader.is_restart_level_pressed():
		restart()


## Returns the level to its starting state.
## 📖 R2.4 — deliberately not guarded by _completed: restarting is the one thing that
## still has to work after the level is won.
func restart() -> void:
	_completed = false
	InputReader.set_enabled(true)

	# R2.1, R2.3 — back to the start with no inherited motion.
	player.reset_to(start_marker.global_position)
	# R2.2 — every placed copy is withdrawn and the count returns to the level's total.
	copy_system.clear()


func _exit_tree() -> void:
	# 📖 The switch outlives this node. Leaving a level while it is off would carry a
	# frozen game into whatever comes next, and the bug would look like broken input.
	InputReader.set_enabled(true)


func _on_goal_body_entered(body: Node2D) -> void:
	# R1.6 — only the player's body completes a level. A copy touching the goal is
	# ignored, otherwise a puzzle could be won by throwing a copy instead of arriving.
	if body != player:
		return

	# R1.3 — touching the goal again changes nothing.
	if _completed:
		return

	_complete()


func _on_death_zone_body_entered(body: Node2D) -> void:
	# R4.2 — copies fall into pits constantly, and a copy dying would restart the level
	# out from under a player who did nothing wrong. Only their own body kills them.
	if body != player:
		return

	# R4.3 — a level already won cannot be lost afterwards. Verified in T4.
	if _completed:
		return

	restart()


func _complete() -> void:
	_completed = true

	# R1.2 — input stops, the simulation does not. A player who reached the goal in
	# mid-air keeps falling, because freezing physics would be a behaviour nobody asked
	# for and the spec does not describe.
	InputReader.set_enabled(false)
	completed.emit()

	# R1.5 — hand over to the next level.
	# 📖 Deferred, per D4: this runs inside an Area2D signal, which fires during the
	# physics step, and changing scenes frees the very node making the call. Deferring
	# costs nothing; getting it wrong costs an intermittent crash.
	_advance_to_next_level.call_deferred()


func _advance_to_next_level() -> void:
	if level_data.next_level == null:
		# 📖 push_error rather than a silent return: reaching the end of the chain is an
		# unfinished design decision, and it has to be impossible to miss in development.
		push_error("LevelRules: this level declares no next level. See spec 001, open question.")
		return

	get_tree().change_scene_to_packed(level_data.next_level)
