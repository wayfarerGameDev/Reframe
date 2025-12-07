@tool
extends CompositorEffect
class_name ReframeCompositorEffect

var refram_compute_shader : ReframeCompositorComputeShader
				
func _render_callback(p_effect_callback_type, p_render_data):
	if refram_compute_shader:
		refram_compute_shader.render_callback(p_effect_callback_type, p_render_data)
		
