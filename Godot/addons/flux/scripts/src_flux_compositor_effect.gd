@tool
extends CompositorEffect
class_name FluxCompositorEffect

var flux_compute_shader : FluxComputeShader
				
func _render_callback(p_effect_callback_type, p_render_data):
	if flux_compute_shader:
		flux_compute_shader.render_callback(p_effect_callback_type, p_render_data)
		
