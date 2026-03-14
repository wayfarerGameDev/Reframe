class_name AgentContextSteeringBatch 
extends Resource

# Samples
var samples : PackedVector3Array = PackedVector3Array()
var sample_count : int = 0
# Plane
var is_3d : bool = false
# Agents
var agent_batch_count : int = 0
var agent_batch_active: PackedInt32Array = PackedInt32Array()
var agent_batch_pool: PackedInt32Array = PackedInt32Array()
var agent_batch_positions : PackedVector3Array = PackedVector3Array()
var agent_batch_heading_currents : PackedVector3Array = PackedVector3Array()
var agent_batch_heading_desireds : PackedVector3Array = PackedVector3Array()
var agent_batch_radii : PackedFloat32Array = PackedFloat32Array()
var agent_batch_turn_weights : PackedFloat32Array = PackedFloat32Array()
var agent_batch_debugs : PackedByteArray = PackedByteArray()

func batch_create_as_circle(agent_batch_count_in: int, sample_count_in : int, is_3d_in : bool) -> void:
	# Batch
	agent_batch_count = agent_batch_count_in
	agent_batch_active.clear()
	agent_batch_pool.clear()
	agent_batch_positions.resize(agent_batch_count_in)
	agent_batch_heading_currents.resize(agent_batch_count_in)
	agent_batch_heading_desireds.resize(agent_batch_count_in)
	agent_batch_radii.resize(agent_batch_count_in)
	agent_batch_turn_weights.resize(agent_batch_count_in)
	agent_batch_debugs.resize(agent_batch_count_in)
	for i in range(agent_batch_count_in):
		agent_batch_pool.append(i)
	# Plane
	is_3d = is_3d_in
	# Samples
	samples.resize(sample_count_in)
	sample_count = sample_count_in
	var step = (2 * PI / sample_count_in)
	for i in range(sample_count_in):
		var angle = step * i
		match is_3d:
			false: samples[i] = Vector3(cos(angle), sin(angle), 0.0)
			true: samples[i] = Vector3(cos(angle), 0.0, sin(angle))

func agent_add() -> int:
	# Validate
	if agent_batch_pool.size() == 0:
		return -1
	# Add
	var agent = agent_batch_pool[0]
	agent_batch_pool.remove_at(0)
	agent_batch_active.append(agent)
	return agent

func agent_remove(agent_in : int) -> void:
	# Remove
	agent_batch_pool.append(agent_in)
	agent_batch_active.erase(agent_in)
	
func agent_remove_safe(agent_in : int) -> void:
	# Remove
	if agent_batch_active.has(agent_in) and agent_in >= 0:
		agent_batch_pool.append(agent_in)
		agent_batch_active.erase(agent_in)
		
func agent_set_position(agent_in : int, position_in : Vector3) -> void:
	agent_batch_positions[agent_in] = position_in

func agent_set_heading_current(agent_in : int, heading_current_in : Vector3) -> void:
	agent_batch_heading_currents[agent_in] = heading_current_in
	
func agent_set_heading_desired(agent_in : int, heading_desired_in : Vector3) -> void:
	agent_batch_heading_desireds[agent_in] = heading_desired_in
	
func agent_set_radius(agent_in : int, radius_in : float) -> void:
	agent_batch_radii[agent_in] = radius_in
	
func agent_set_turn_weight(agent_in : int, turn_weight_in : float) -> void:
	agent_batch_turn_weights[agent_in] = turn_weight_in

func agent_set_debug(agent_in : int, debug_in : bool) -> void:
	agent_batch_debugs[agent_in] = debug_in

func agent_batch_process (delta: float) -> void:
	pass

func agent_batch_single_process(delta : float, agent_in : int) -> void:
	if is_3d : _agent_batch_single_process_3d(delta,agent_in)
	else : _agent_batch_single_process_2d(delta,agent_in)

func _agent_batch_single_process_2d(delta:float, agent_in : int) -> void:
	pass

func _agent_batch_single_process_3d(delta:float, agent_in : int) -> void:
	# Agent Data
	var agent_position = agent_batch_positions[agent_in]
	var agent_radius = agent_batch_radii[agent_in]
	var agent_debug = agent_batch_debugs[agent_in]
	var agent_heading_current = agent_batch_heading_currents[agent_in]
	var agent_heading_desired = agent_batch_heading_desireds[agent_in]
	# Debug (Heading)
	# if agent_debug:
	#	DebugDraw3D.draw_arrow_ray(agent_position, agent_heading_current,agent_radius,Color.YELLOW)
	#	DebugDraw3D.draw_arrow_ray(agent_position, agent_heading_desired,agent_radius,Color.BLUE)
	# Process
	# for sample in samples:
		# Debug
	#	if agent_debug == 1:
	#		DebugDraw3D.draw_line(agent_position, agent_position + sample * agent_radius,Color.GREEN,0)
