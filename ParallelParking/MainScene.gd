extends Node2D

enum {
	FORWARD = 0,
	BACKWARD,
	LEFT,
	RIGHT,
	N_ACTION,
}
enum {
	TILE_GOAL = 0,
	TILE_WALL,
}
const ALPHA = 0.1
const GAMMA = 0.1
const INIT_POS = Vector2(32*6.5, 32*4)
const VELOCITY_UNIT = 500		# 速度単位
const ANGLE_UNIT = 5		# 車角度単位
const ANGLE_MAX = 110		# 最大車角度（右に切った場合）
const ANGLE_MIN = -20		# 最小車角度（左に切った場合）
const STEERING_UNIT = 1
const STEERING_MAX = 1
const STEERING_MIN = -1

const CELL_WIDTH = 16
const N_CELL_HORZ = 16
const N_CELL_VERT = 26
const N_ANGLE : int = ANGLE_MAX - ANGLE_MIN + 1			# [-20, +110]
const N_STEERING = 3		# -1, 0, 1
const N_STATE : int = N_CELL_HORZ * N_CELL_VERT * N_STEERING * N_ANGLE			# 状態数

var started = false
var car_angle = 0.0				# 車向き（0：上向き）
var velocity = 0.0				# 車速度
var steering = 0.0				# ステアリング、{-1, 0, +1}
var rng = RandomNumberGenerator.new()
var Q = []				# Q値テーブル

func initCar():
	$Car.position = INIT_POS
	$Car.rotation = 0
	car_angle = 0
func calcQIX() -> int:
	if car_angle < ANGLE_MIN || car_angle > ANGLE_MAX: return -1
	var x : int = int($Car.position.x - 32) / CELL_WIDTH
	var y : int = int($Car.position.y - 32) / CELL_WIDTH
	var s : int = (steering - STEERING_MIN) / STEERING_UNIT
	var a : int = int(car_angle - ANGLE_MIN)
	return ((y * N_CELL_HORZ + x) * N_ANGLE + a) * N_STEERING + s
	
func updateCarPosLabel():
	$Panel/PosLabel.text = "Pos: (%.2f, %.2f)" % [$Car.position.x, $Car.position.y]
	#$Panel/PosLabel.text += ", Qix = %d" % calcQIX()
func updateDirLabel():
	var txt = "Left" if steering < 0 else "Right" if steering > 0 else "Straight"
	$Panel/DirLabel.text = "Dir: " + txt
func updateCarAngleLabel():
	$Panel/AngleLabel.text = "Angle: %d" % car_angle
	$Car.rotation = car_angle * PI / 180
	#updateCarPosLabel()
func updateQValLabel():
	var qix = calcQIX()
	if qix < 0:
		$Panel/QValLabel.text = "Q[-1]"		# 状態範囲外
	else:
		var txt = "Q[%d] = [\n" % qix
		for i in range(Q[qix].size()):
			txt += "    %.3f,\n" % Q[qix][i]
		$Panel/QValLabel.text = txt + "]"
			
func _ready():
	rng.randomize()
	print("N_STATE = ", N_STATE)
	Q.resize(N_STATE)
	for i in range(Q.size()): Q[i] = [0.0, 0.0, 0.0, 0.0]
	initCar()
	updateCarPosLabel()
	updateDirLabel()
	updateQValLabel()
	pass # Replace with function body.
func is_on_the_goal():
	var xy = $TileMap.world_to_map($Car.position)
	return $TileMap.get_cellv(xy) == TILE_GOAL
func _physics_process(delta):
	var qix0 = calcQIX()
	#var colided = false
	var reward = 0			# 報酬
	var act = -1
	if started:
		velocity = 0
		act = rng.randi_range(FORWARD, RIGHT)
		match act:
			FORWARD:
				velocity = VELOCITY_UNIT
			BACKWARD:
				velocity = -VELOCITY_UNIT
			LEFT:
				steering = clamp(steering - STEERING_UNIT, STEERING_MIN, STEERING_MAX)
				updateDirLabel()
				#if car_angle == ANGLE_MIN: return
				#car_angle -= ANGLE_UNIT
			RIGHT:
				steering = clamp(steering + STEERING_UNIT, STEERING_MIN, STEERING_MAX)
				updateDirLabel()
				#if car_angle == ANGLE_MAX: return
				#car_angle += ANGLE_UNIT
	else:
		if Input.is_action_pressed("ui_up"):		# ↑キー押下時
			velocity = VELOCITY_UNIT
		elif Input.is_action_pressed("ui_down"):	# ↓キー押下時
			velocity = -VELOCITY_UNIT
		else:
			velocity = 0
			if Input.is_action_just_pressed("ui_left"):		# ←キー押下時
				steering = clamp(steering - STEERING_UNIT, STEERING_MIN, STEERING_MAX)
				#car_angle = clamp(car_angle - ANGLE_UNIT, ANGLE_MIN, ANGLE_MAX)
			elif Input.is_action_just_pressed("ui_right"):	# →キー押下時
				steering = clamp(steering + STEERING_UNIT, STEERING_MIN, STEERING_MAX)
				#car_angle = clamp(car_angle + ANGLE_UNIT, ANGLE_MIN, ANGLE_MAX)
			else:
				return
			updateDirLabel()
	#if velocity == 0.0:
		#$Panel/AngleLabel.text = "Angle: %d" % car_angle
		#$Car.rotation = car_angle * PI / 180
		#updateCarPosLabel()
	#else:
	if velocity != 0.0:
		var vx = velocity * sin(car_angle * PI / 180)
		var vy = -velocity * cos(car_angle * PI / 180)
		#$Car.position += Vector2(vx, vy)
		var lst = $Car.move_and_collide(Vector2(vx, vy)*delta)
		updateCarPosLabel()
		if velocity > 0:
			car_angle += steering * 1.0
		else:
			car_angle -= steering * 1.0
		updateCarAngleLabel()
		#print(lst)
		if lst != null:
			reward = -1.0
			print("colided.")
			started = false
		elif is_on_the_goal():
			reward = 0.5
			print("on the goel.")
			if car_angle >= -1 && car_angle <= 1:
				reward = 1.0
	updateQValLabel()
	if qix0 >= 0 && act >= 0:
		var qix = calcQIX()
		if qix != qix0:
			var maxQ = 0
			if qix < 0: reward = -1		# 車角度範囲外などの場合
			elif reward == 0: reward = 0.01		# 長くさまようのはマイナス報酬
			if qix >= 0:
				maxQ = Q[qix].max()
			Q[qix0][act] += ALPHA * (reward * GAMMA + maxQ - Q[qix0][act])
func _on_StartButton_pressed():
	initCar()
	started = true;
	pass # Replace with function body.


func _on_InitButton_pressed():
	initCar()
	updateCarPosLabel()
	updateDirLabel()
	updateQValLabel()
	pass # Replace with function body.
