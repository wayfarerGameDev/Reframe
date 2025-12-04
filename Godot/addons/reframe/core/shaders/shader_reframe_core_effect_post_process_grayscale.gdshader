shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;

void vertex()
{
    // Fill screen by mapping to camera
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment()
{
   vec3 color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
   ALBEDO = vec3(color.r * 0.2125 + color.g * 0.7154 + color.b * 0.0721);
}
