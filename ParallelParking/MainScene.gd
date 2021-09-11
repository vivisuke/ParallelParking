extends Node2D

const VELOCITY_UNIT = 5		# 速度単位
const ANGLE_UNIT = 5		# 車角度単位
const ANGLE_MAX = 45		# 最大車角度（右に切った場合）
const ANGLE_MIN = -45		# 最小車角度（左に切った場合）

var car_angle = 0.0				# 車向き（上向き）
var velocity = 0.0				# 車速度


func _ready():
	pass # Replace with function body.
	
func _physics_process(delta):
	if Input.is_action_just_pressed("ui_up"):		# ↑キー押下時
		velocity = VELOCITY_UNIT
	elif Input.is_action_just_pressed("ui_down"):	# ↓キー押下時
		velocity = -VELOCITY_UNIT
	else:
		velocity = 0
		if Input.is_action_just_pressed("ui_left"):		# ←キー押下時
			car_angle = clamp(car_angle - ANGLE_UNIT, ANGLE_MIN, ANGLE_MAX)
		elif Input.is_action_just_pressed("ui_right"):	# →キー押下時
			car_angle = clamp(car_angle + ANGLE_UNIT, ANGLE_MIN, ANGLE_MAX)
		else:
			return
		$Car.rotation = car_angle
		return
	if velocity != 0.0:
		var vx = velocity * sin(car_angle * PI / 180)
		var vy = velocity * cos(car_angle * PI / 180)
