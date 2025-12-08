@tool
extends Resource
class_name ReframeCompositorComputeShader

enum Domain { COMPOSITOR, RENDERTARGET}

var shader_functions_code: String = "":
	set(value):
		if value == "": value = "//None" # Needed to recompile shaders for empty code
		mutex.lock()
		shader_functions_code = value
		shader_is_dirty = true
		mutex.unlock()
var shader_main_code: String = "":
	set(value):
		if value == "": value = "//None" # Needed to recompile shaders for empty code
		mutex.lock()
		shader_main_code = value
		shader_is_dirty = true
		mutex.unlock()
var world_resolution : Vector2i = Vector2i(256,256);
var world_alpha : float = 1;
var rendering_device: RenderingDevice
var shader: RID
var pipeline: RID
var mutex: Mutex = Mutex.new()
var shader_is_dirty: bool = true
var domain : Domain = Domain.COMPOSITOR
var uniforms : Array
var image_target : RID

const template_shader: String = """
#version 450

// Layout
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(rgba32f, set = 0, binding = 0) uniform image2D image_scene_color;
layout(push_constant, std430) uniform World
{
	vec2 resolution;
	vec2 time_alpha;
} world;

#COMPUTE_FUNCTIONS_CODE

// The code we want to execute in each invocation
void main() 
{
	// Index | UV
	ivec2 index_in = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv_in = gl_GlobalInvocationID.xy;
	
	// World
	ivec2 world_resolution_in = ivec2(world.resolution);
    float world_time_in = world.time_alpha.x;
    float world_alpha_in = world.time_alpha.y;
	
	vec4 color = imageLoad(image_scene_color, index_in);

	#COMPUTE_MAIN_CODE
	
	// Result
	imageStore(image_scene_color, index_in, color);
}
"""

func init():
	rendering_device = RenderingServer.get_rendering_device()
	
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			rendering_device.free_rid(shader)
			
func compile_shader() -> bool:
	# Code (new)
	var new_main_code: String = ""
	var new_functions_code: String = ""
	# Check if our shader is dirty.
	mutex.lock()
	if shader_is_dirty:
		new_main_code = shader_main_code # Your existing #COMPUTE_CODE content
		new_functions_code = shader_functions_code # The new content for #COMPUTE_FUNCTIONS_CODE
		shader_is_dirty = false
	mutex.unlock()
	# We don't have a (new) shader?
	if new_main_code.is_empty() and new_functions_code.is_empty():
		return pipeline.is_valid()
	# Apply template.
	var new_shader_code = template_shader.replace("#COMPUTE_MAIN_CODE", new_main_code)
	new_shader_code = new_shader_code.replace("#COMPUTE_FUNCTIONS_CODE", new_functions_code)
	# Out with the old.
	if shader.is_valid():
		if pipeline.is_valid():
			rendering_device.free_rid(pipeline)
		rendering_device.free_rid(shader)
		shader = RID()
		pipeline = RID()
	# New
	var shader_source: RDShaderSource = RDShaderSource.new()
	shader_source.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	shader_source.source_compute = new_shader_code
	var shader_spirv: RDShaderSPIRV = rendering_device.shader_compile_spirv_from_source(shader_source)
	# Errors
	if shader_spirv.compile_error_compute != "":
		push_error(shader_spirv.compile_error_compute)
		push_error("In: " + new_shader_code)
		return false
	# Compile
	shader = rendering_device.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		return false
	# Create compute shader from compiled shader
	pipeline = rendering_device.compute_pipeline_create(shader)
	return pipeline.is_valid()
	
func render_callback(p_effect_callback_type, p_render_data):
	dispatch_shader_to_compositor(p_effect_callback_type, p_render_data)
	dispatch_shader_to_render_target()

func render_to_render_target() -> void:
	pass

func dispatch_shader_to_compositor(p_effect_callback_type, p_render_data):
	if domain == Domain.COMPOSITOR and compile_shader():
		var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
		if render_scene_buffers:
			world_resolution = render_scene_buffers.get_internal_size()
			var view_count = render_scene_buffers.get_view_count()
			for view in range(view_count):
				image_target = render_scene_buffers.get_color_layer(view)
				dispatch_shader()
				

func dispatch_shader_to_render_target():
	if domain == Domain.RENDERTARGET and compile_shader():
		for uniform in uniforms:
			if typeof(uniform) == TYPE_STRING_NAME and uniform != "":
				ReframeCompositorUtilities.create_texture_rid(uniform, world_resolution)
				image_target = ReframeCompositorUtilities.fetch_texture_rid(uniform)
				dispatch_shader()

func dispatch_shader():
	# Validate
	if image_target == null:
		return	
	# Compute List
	var compute_list:= rendering_device.compute_list_begin()
	rendering_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	# Groups
	var x_groups = (world_resolution.x - 1) / 8 + 1
	var y_groups = (world_resolution.y - 1) / 8 + 1
	var z_groups = 1
	# Uniforms
	var uniforms = []
	var color_uniform: RDUniform = RDUniform.new()
	color_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	color_uniform.binding = 0
	color_uniform.add_id(image_target)
	uniforms.append(color_uniform)
	rendering_device.compute_list_bind_uniform_set(compute_list, UniformSetCacheRD.get_cache(shader, 0, uniforms), 0)
	# World (Push constant)
	var world_push_constant: PackedFloat32Array = PackedFloat32Array()
	world_push_constant.push_back(world_resolution.x)
	world_push_constant.push_back(world_resolution.y)
	world_push_constant.push_back(Time.get_ticks_msec() / 1000.0)
	world_push_constant.push_back(world_alpha)
	rendering_device.compute_list_set_push_constant(compute_list, world_push_constant.to_byte_array(),  world_push_constant.size() * 4)
	# Run compute shader.
	rendering_device.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
	rendering_device.compute_list_end()
