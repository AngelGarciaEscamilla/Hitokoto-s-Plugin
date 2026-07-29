extends SkeletonIK3D

@export var stop : bool 
@export var transition : float = 10
@export var user : Node3D

var timer : Timer = Timer.new()

func _ready() -> void:
	add_child(timer)
	timer.timeout.connect(func():
			stop=false)
	start()
	if !user && (get_parent().get_parent().get_parent().get_parent() is Node3D):
		user = get_parent().get_parent().get_parent().get_parent()


func _process(delta:float)  -> void:
	if !(user && user is PhysicsBody3D):return
	if stop:
		influence = lerp(influence,0.0,transition*delta)
		return
	if user.velocity.length() > 0.01 || !user.is_on_floor():
		influence = lerp(influence,0.0,transition*delta)
	else:
		influence = lerp(influence,1.0,transition*delta)

func stop_ik(time) -> void:
	if !timer.is_stopped():
		timer.stop()
	if time > 0.01:
		timer.wait_time = time
		timer.start()
	stop = true

func play_ik() -> void:
	stop = false