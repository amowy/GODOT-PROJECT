extends CharacterBody3D
@onready var hitbox = $hitbox


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var health = 100.0

var time_in_seconds = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func hurt(dmg) :
	health -= dmg

func attack() :
	for body in hitbox.get_overlapping_bodies():
		if body.has_method("hurt"):
			body.hurt(10)
			
	pass

func _ready():
	pass

func _process(delta):
	if health <= 0.0 :
		print("kms")
		queue_free()

func _physics_process(delta):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		attack()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
