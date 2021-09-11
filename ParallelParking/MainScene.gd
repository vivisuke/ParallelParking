extends Node2D

enum {
	FORWARD = 0,
	BACKWARD,
	LEFT,
	RIGHT,
	N_ACTION,
}
const INIT_POS = Vector2(192, 256)
const VELOCITY_UNIT = 500		# 速度単位
const ANGLE_UNIT = 5		# 車角度単位
const ANGLE_MAX = 45		# 最大車角度（右に切った場合）
const ANGLE_MIN = -45		# 最小車角度（左に切った場合）

var started = false
var car_angle = 0.0				# 車向き（上向き）
var velocity = 0.0				# 車速度

var rng = RandomNumberGenerator.new()
func initCar():
	$Car.position = INIT_POS
	$Car.rotation = 0
	car_angle = 0
func updateCarPos():
	$Panel/PosLabel.text = "Pos: (%.2f, %.2f)" % [$Car.position.x, $Car.position.y]
	var x : int = int($Car.position.x - 32) / 16
	var y : int = int($Car.position.y - 32) / 16
	$Panel/PosLabel.text += ", ix = %d" % (y*16+x)

func _ready():
	rng.randomize()
	initCar()
	updateCarPos()
	pass # Replace with function body.
	
func _physics_process(delta):
	if started:
		velocity = 0
		match rng.randi_range(FORWARD, RIGHT):
			FORWARD:
				velocity = VELOCITY_UNIT
			BACKWARD:
				velocity = -VELOCITY_UNIT
			LEFT:
				if car_angle == ANGLE_MIN: return
				car_angle -= ANGLE_UNIT
			RIGHT:
				if car_angle == ANGLE_MAX: return
				car_angle += ANGLE_UNIT
	else:
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
	if velocity == 0.0:
		$Panel/AngleLabel.text = "Angle: %d" % car_angle
		$Car.rotation = car_angle * PI / 180
	else:
		var vx = velocity * sin(car_angle * PI / 180)
		var vy = -velocity * cos(car_angle * PI / 180)
		#$Car.position += Vector2(vx, vy)
		var lst = $Car.move_and_collide(Vector2(vx, vy)*delta)
		updateCarPos()
		#print(lst)
		if lst != null:
			print("colided.")
			started = false

func _on_StartButton_pressed():
	initCar()
	started = true;
	pass # Replace with function body.
