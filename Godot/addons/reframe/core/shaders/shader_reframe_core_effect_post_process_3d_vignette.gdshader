shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform float softness = 0.4;
uniform float radius = 1.4;

void vertex()
{
    // Fill screen by mapping to camera
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment()
{
	vec2 normalized_uv = (UV - 0.5) * 2.0;
 	float dist = length(normalized_uv);
	float vignette_factor = smoothstep(radius, radius - softness, dist);
	ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).rgb * vignette_factor;
}
