extends RigidBody3D

class Thruster:
	var raycast: RayCast3D
	var p = 1
	var i = 0
	var d = 0
	var set_distance = 0.25
	var prev_error = 0
	var integral = 0
	var max_force = 500
	var min_force = -500
	func _init(raycast, p, i, d) -> void:
		self.raycast = raycast
		self.p = p
		self.i = i
		self.d = d
		prev_error = 0
		integral = 0
		
	func update_physics(delta: float) -> float:
		if(!raycast.is_colliding()):
			integral = 0
			prev_error = 0
			return 0
		var origin = raycast.global_transform.origin
		var collision_point = raycast.get_collision_point()
		var distance = origin.distance_to(collision_point)
		var error = set_distance - distance
		
		var p_out = p * error
		
		integral += error * delta
		var i_out = i * integral
		
		var derivative = (error - prev_error) / delta
		var d_out = d * derivative;
		
		
		var output = p_out + i_out + d_out;
		
		if(output > max_force):
			output = max_force
		elif(output < min_force):
			output = min_force
			
		
		
		prev_error = error
		
		# apply_force(delta * Vector3(0,output,0), raycast.transform.origin)
		
		return output
		

var left_thruster:Thruster
var right_thruster:Thruster
var front_thruster:Thruster
var back_thruster:Thruster

func _ready() -> void:
	left_thruster = Thruster.new($Raycasters/LeftRay, 800, 1, 50)
	right_thruster = Thruster.new($Raycasters/RightRay, 800, 1, 50)
	front_thruster = Thruster.new($Raycasters/FrontRay, 800, 1, 50)
	back_thruster = Thruster.new($Raycasters/BackRay, 800, 1, 50)
	
func _physics_process(delta: float) -> void:
	apply_force(delta * transform.basis.x.inverse() * (Vector3(0,left_thruster.update_physics(delta),0)), to_global(left_thruster.raycast.transform.origin) - self.transform.origin)
	apply_force(delta * transform.basis.x.inverse() * (Vector3(0,right_thruster.update_physics(delta),0)), to_global(right_thruster.raycast.transform.origin) - self.transform.origin)
	apply_force(delta * transform.basis.x.inverse() * (Vector3(0,front_thruster.update_physics(delta),0)), to_global(front_thruster.raycast.transform.origin) - self.transform.origin)
	apply_force(delta * transform.basis.x.inverse() * (Vector3(0,back_thruster.update_physics(delta),0)), to_global(back_thruster.raycast.transform.origin) - self.transform.origin)
	
	if(Input.is_action_pressed("ui_up")):
		apply_force(delta * (Vector3(0,0,-20)))
	if(Input.is_action_pressed("ui_down")):
		apply_force(delta * (Vector3(0,0,20)))
	if(Input.is_action_pressed("ui_right")):
		apply_torque(delta * to_global(Vector3(0,-20,-5)))
	if(Input.is_action_pressed("ui_left")):
		apply_torque(delta * to_global(Vector3(0,20,5)))
		
	#apply_force(delta * to_global(to_local(linear_velocity) * Vector3(5,0,1)) * -5)
	print(to_local(linear_velocity))
