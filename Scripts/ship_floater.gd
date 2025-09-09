extends RigidBody3D

class Thruster:
	var raycast: RayCast3D
	var p = 1
	var i = 0
	var d = 0
	var set_distance = 0.34
	var prev_error = 0
	var integral = 0
	var max_force = 900
	var min_force = -100
	var touch = false
	var current_output = 0
	func _init(raycast, p, i, d) -> void:
		self.raycast = raycast
		self.p = p
		self.i = i
		self.d = d
		prev_error = 0
		integral = 0
		
	func update_physics(delta: float) -> float:
		touch = false
		if(!raycast.is_colliding()):
			integral = 0
			prev_error = 0
			return 0
		touch = true
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
		current_output = output
		return output
		

var left_thruster:Thruster
var right_thruster:Thruster
var front_thruster:Thruster
var back_thruster:Thruster

func _ready() -> void:
	left_thruster = Thruster.new($Raycasters/LeftRay, 700, 70, 60)
	right_thruster = Thruster.new($Raycasters/RightRay, 700, 50, 60)
	front_thruster = Thruster.new($Raycasters/FrontRay, 700, 50, 60)
	back_thruster = Thruster.new($Raycasters/BackRay, 700, 70, 60)
	
func _physics_process(delta: float) -> void:
	apply_force(delta * (Vector3(0,left_thruster.update_physics(delta),0) * self.transform.basis.inverse()), to_global(left_thruster.raycast.transform.origin) - self.transform.origin)
	apply_force(delta * (Vector3(0,right_thruster.update_physics(delta),0) * self.transform.basis.inverse()), to_global(right_thruster.raycast.transform.origin) - self.transform.origin)
	apply_force(delta * (Vector3(0,front_thruster.update_physics(delta),0) * self.transform.basis.inverse()), to_global(front_thruster.raycast.transform.origin) - self.transform.origin)
	apply_force(delta * (Vector3(0,back_thruster.update_physics(delta),0) * self.transform.basis.inverse()), to_global(back_thruster.raycast.transform.origin) - self.transform.origin)
	var airbrake = 3
	var not_touching_ground = !(left_thruster.touch && right_thruster.touch && front_thruster.touch && back_thruster.touch)
	
	print((linear_velocity * self.transform.basis).y)
	if(!not_touching_ground):
		apply_torque(0.1 * delta * (Vector3(front_thruster.current_output,0,0) * self.transform.basis.inverse()))
		apply_torque(0.1 * delta * (Vector3(-back_thruster.current_output,0,0) * self.transform.basis.inverse()))
		
	
	
	
	if(not_touching_ground):
		gravity_scale = 1.5
	else:
		gravity_scale = 0.2
	
	if(Input.is_action_pressed("thrust")):
		if(!Input.is_action_pressed("alt_thrust")):
			apply_central_force(delta * (Vector3(0,0,-90) * self.transform.basis.inverse()))
		if(not_touching_ground):
			apply_torque(delta * (Vector3(-10,0,0) * self.transform.basis.inverse()))
	if(Input.is_action_pressed("alt_thrust")):
		apply_central_force(delta * (Vector3(0,0,-90) * self.transform.basis.inverse()))
	if(Input.is_action_pressed("reverse")):
		if(not_touching_ground):
			apply_torque(delta * (Vector3(10,0,0) * self.transform.basis.inverse()))
		else:
			apply_central_force(delta * (Vector3(0,0,50) * self.transform.basis.inverse()))
	if(Input.is_action_pressed("right")):
		if(not_touching_ground):
			apply_torque(delta * (Vector3(0,0,-10) * self.transform.basis.inverse()))
		else:
			apply_torque(delta * (Vector3(0,-20,-5) * self.transform.basis.inverse()))
	if(Input.is_action_pressed("left")):
		if(not_touching_ground):
			apply_torque(delta * (Vector3(0,0,10) * self.transform.basis.inverse()))
		else:
			apply_torque(delta * (Vector3(0,20,5) * self.transform.basis.inverse()))
	if(Input.is_action_pressed("left_airbrake")):
		$LeftAirbrake/OmniLight3D.light_energy = 2
		airbrake = 5
		if(not_touching_ground):
			apply_torque(delta * (Vector3(0,10,0) * self.transform.basis.inverse()))
		apply_force(delta * (Vector3(0,0,-10 * (linear_velocity * self.transform.basis).y) * self.transform.basis.inverse()), to_global($LeftAirbrake.transform.origin) - self.transform.origin)
	else:
		$LeftAirbrake/OmniLight3D.light_energy = 0
		
	if(Input.is_action_pressed("right_airbrake")):
		$RightAirbrake/OmniLight3D.light_energy = 2
		airbrake = 5
		if(not_touching_ground):
			apply_torque(delta * (Vector3(0,-10,0) * self.transform.basis.inverse()))
		apply_force(delta * (Vector3(0,0,-10 * (linear_velocity * self.transform.basis).y) * self.transform.basis.inverse()), to_global($RightAirbrake.transform.origin) - self.transform.origin)
	else:
		$RightAirbrake/OmniLight3D.light_energy = 0
		
	
	if(!not_touching_ground):
		var direction = 0
		if((linear_velocity * self.transform.basis).y < 0):
			direction = -1
		if((linear_velocity * self.transform.basis).y > 0):
			direction = 1
		apply_central_force(direction * airbrake * delta * Vector3(0,0,1 * abs((linear_velocity * self.transform.basis).x)) * self.transform.basis.inverse())
		apply_central_force(-5 * delta * ((linear_velocity * self.transform.basis) * Vector3(airbrake,0,0.3)) * self.transform.basis.inverse())
	if(not_touching_ground):
		apply_torque(-7 * delta * ((angular_velocity * self.transform.basis) * Vector3(1,1,1)) * self.transform.basis.inverse())
	else:
		apply_torque(-7 * delta * ((angular_velocity * self.transform.basis) * Vector3(0,1,0)) * self.transform.basis.inverse())
	if((linear_velocity * self.transform.basis).y < 0):
		$Camera3D.position.z = 2.3 - min(-0.2 * (linear_velocity * self.transform.basis).y, 1)
		$Camera3D.fov = 75 - max(2 * (linear_velocity * self.transform.basis).y, -40)
