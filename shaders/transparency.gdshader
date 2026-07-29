shader_type spatial;
render_mode blend_mix, depth_prepass_alpha;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float transparency : hint_range(0, 1) = 0.5;

void fragment() {
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a * transparency;
}