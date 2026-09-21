extends Node

## Temporary instrument: measures, in pixels, what a jump and a stack of copies actually
## reach.
##
## It exists to settle one number before any level geometry is drawn. The GDD assumes a
## copy is worth one floor of height (32 px), which only holds when the copy is placed
## standing still — placed at the top of a jump it is worth far more. Geometry built on
## the wrong number is geometry the player walks straight over.
##
## Delete this file and its node when B5 closes. It is evidence, not a system.

## The player being measured.
@export var player: PlayerMotor

## Height of the floor this level starts on, in global coordinates. Captured once, on the
## first real ground contact.
var _floor_y: float = 0.0
var _has_floor: bool = false

var _airborne: bool = false
var _takeoff: Vector2 = Vector2.ZERO
var _peak_y: float = 0.0

## Last position the player was seen standing on something.
## 📖 Take-off cannot be read at the first airborne frame: by then the jump has already
## carried the player a full physics tick upward (400 px/s ÷ 60 Hz ≈ 7 px), and every
## reported rise would be short by that much. The last grounded sample is the real one.
var _last_grounded: Vector2 = Vector2.ZERO


func _ready() -> void:
	assert(player != null, "JumpProbe: assign the Player in the Inspector.")
	# 📖 Sampling has to happen after the player's own _physics_process, or every reading
	# would be one physics tick stale. The priority is explicit because sibling order in
	# the scene tree is a convention, not a contract.
	process_physics_priority = 10


func _physics_process(_delta: float) -> void:
	var on_floor: bool = player.is_on_floor()

	if not _has_floor:
		# 📖 Waits for actual ground contact instead of reading the start marker: the
		# marker may well sit in mid-air, and every number here is relative to the floor
		# the player jumps from.
		if on_floor:
			_has_floor = true
			_floor_y = player.global_position.y
			_last_grounded = player.global_position
			print("[JumpProbe] ground at y = ", roundi(_floor_y))
		return

	if on_floor:
		_last_grounded = player.global_position

	if _airborne:
		_peak_y = minf(_peak_y, player.global_position.y)

	if not on_floor and not _airborne:
		_airborne = true
		_takeoff = _last_grounded
		_peak_y = player.global_position.y
		return

	if on_floor and _airborne:
		_airborne = false
		_report()


## Prints the three numbers one flight produced.
## 📖 "air", not "jump": placing a copy mid-flight teleports the player upward and ends
## the flight there, so this reports what was gained in the air however it was gained.
## Measure plain jumps first and chains afterwards, or the two end up in one number.
func _report() -> void:
	var rise: int = roundi(_takeoff.y - _peak_y)
	var run: int = roundi(absf(player.global_position.x - _takeoff.x))
	var above_ground: int = roundi(_floor_y - _peak_y)
	print(
		"[JumpProbe] air rise: ", rise,
		" px | run: ", run,
		" px | peak above ground: ", above_ground, " px"
	)
