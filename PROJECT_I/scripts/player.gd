extends CharacterBody3D

@onready var neck = $neck
@onready var head = $neck/head
@onready var standing_collisionshape_3d = $standing_collisionshape3D
@onready var crouching_collisionshape_3d = $crouching_collisionshape3D
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/eyes/Camera3D
@onready var eyes = $neck/head/eyes
@onready var animation_player = $neck/head/eyes/AnimationPlayer
@onready var weapons = $neck/head/weapons
@onready var simple_1 = $neck/head/weapons/simple1
@onready var simple_2 = $neck/head/weapons/simple2


var current_speed = 5.0

const jump_velocity = 4.5
const walk_speed = 5.0
const sprint_speed = 8.0
const crouch_speed = 3.0

const mouse_sens = 0.4

const lerp_speed = 10.0
const air_lerp_speed = 3.0

var direction = Vector3.ZERO
var crouch_depth = -0.5
var free_look_tilt_amount = 3
var last_velocity = Vector3.ZERO

#states
var walking = true
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

#Slide vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

#head bobbing vars
const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0


#its a mess, i know
var melee_damage = 10.0
var super_jump_velocity = 100.0

#stats
var active_style = null
var combo = 0
var dmg = 20
var health = 100
var is_busy = false 
#attack_status
var attack_status = 0 # 0- free; 1- prepare  3- coming back 4 - parry 5-block


func _set_attack_status(status_id):
	if status_id == 0:
		combo = 0
	attack_status = status_id

func hurt(dmg) :
	if attack_status == 4:
		dmg = 0
		animation_player.play("parried")
	elif attack_status == 5:
		dmg /= 2
	health -= dmg
	print(health)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _attack():
	for body in active_style.get_node("area").get_overlapping_bodies():
		if body.has_method("hurt") && body != self:
			body.hurt(dmg)
			
func _melee():
	var anim = active_style.get_node("AnimationPlayer")
	if attack_status != 1:
		if combo == 0:
			anim.play("hit1")
			combo += 1
		elif combo == 1:
			anim.play("hit2")
			combo += 1
		elif combo == 2:
			anim.play("hit3")
			combo = 0
			

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(-deg_to_rad(event.relative.x*mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
		else:
			rotate_y(-deg_to_rad(event.relative.x*mouse_sens))
		head.rotate_x(-deg_to_rad(event.relative.y*mouse_sens))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))
	#weaponseletct
	if Input.is_action_pressed("weapon1"):
		if(active_style != null):
			active_style.visible = false
		active_style = simple_1
		#TODO: befejezni hogy a tobbit tuntesse el
		active_style.visible = true
	elif Input.is_action_pressed("weapon2"):
		if(active_style!=null):
			active_style.visible = false
		active_style = simple_2
		active_style.visible = true
	#BLOCK
	if Input.is_action_just_pressed("block"):
		_set_attack_status(4)
	#ATTACKING
	if Input.is_action_pressed("hit1"):
		_melee()
	
		

#func melee():
#	if Input.is_action_just_pressed("hit1"):
#		
#		for body in hitbox.get_overlapping_bodies():
#			if body.is_in_group("enemy"):
	#			body.health -= melee_damage
	#			print(body.health)

func _physics_process(delta):
	#getting movement inputs
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	if health <= 0.0:
		print("deadge") 
	if Input.is_action_pressed("crouch") || sliding:
		current_speed = lerp(current_speed,crouch_speed,delta * lerp_speed)
		head.position.y = lerp(head.position.y,crouch_depth, delta * lerp_speed)
		
		standing_collisionshape_3d.disabled = true
		crouching_collisionshape_3d.disabled = false
		
		#Slide begin logic
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			print("slide begin")
		
		walking = false
		sprinting = false
		crouching = true
		
	elif !ray_cast_3d.is_colliding():
		standing_collisionshape_3d.disabled = false
		crouching_collisionshape_3d.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		if(Input.is_action_pressed("sprint")):
			current_speed = lerp(current_speed, sprint_speed, delta * lerp_speed)
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed = lerp(current_speed, walk_speed, delta * lerp_speed)
			walking = true
			sprinting = false
			crouching = false
	
	# Handle FreeLooking
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(7.0),delta*lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z,0.0,delta*lerp_speed)
	
	# Handle sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
			print("Slide end")
			
	# Head bobbing
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
		
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y,head_bobbing_vector.y * (head_bobbing_current_intensity/2.0),delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,head_bobbing_vector.x * head_bobbing_current_intensity,delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y,0.0,delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,0.0,delta*lerp_speed)
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		if last_velocity.y < -20.0:
			animation_player.play("landing")
		
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false
		animation_player.play("jump")
		
	#handle landing
	if is_on_floor():
		if last_velocity.y < -10.0:
			animation_player.play("roll")
			print(last_velocity.y)
		elif last_velocity.y < -1.0:
			animation_player.play("landing")
			print(last_velocity.y)
			

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*air_lerp_speed)
			
			
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x,0,slide_vector.y)).normalized()
		current_speed = (slide_timer + 0.1) * slide_speed
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	

	last_velocity = velocity

	move_and_slide()
	
	
