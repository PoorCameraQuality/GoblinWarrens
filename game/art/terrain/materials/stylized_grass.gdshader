shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_lambert, specular_disabled;

// Stylized cursed-forest grass. Base stays planted; tips sway from shared wind globals.

global uniform vec3 gw_wind_direction = vec3(1.0, 0.0, 0.2);
global uniform float gw_wind_strength = 0.35;
global uniform float gw_wind_gust = 0.0;
global uniform float gw_time_of_day = 0.35;

uniform vec4 color_bottom : source_color = vec4(0.18, 0.28, 0.12, 1.0);
uniform vec4 color_top : source_color = vec4(0.42, 0.55, 0.22, 1.0);
uniform float blade_height_m : hint_range(0.15, 1.5, 0.01) = 0.55;
uniform float sway_amplitude : hint_range(0.0, 0.8, 0.01) = 0.28;
uniform float alpha_scissor : hint_range(0.0, 1.0, 0.01) = 0.35;

varying float v_height_norm;
varying float v_instance_phase;

float _hash11(float n) {
	return fract(sin(n) * 43758.5453123);
}

void vertex() {
	float phase = float(INSTANCE_ID) * 0.137 + NODE_POSITION_WORLD.x * 0.07 + NODE_POSITION_WORLD.z * 0.05;
	v_instance_phase = phase;
	v_height_norm = clamp(VERTEX.y / max(blade_height_m, 0.001), 0.0, 1.0);

	vec3 wind_dir = normalize(vec3(gw_wind_direction.x, 0.0, gw_wind_direction.z));
	float gust = clamp(gw_wind_gust, 0.0, 1.5);
	float strength = (gw_wind_strength + gust * 0.55) * sway_amplitude;
	float wave = sin(TIME * (1.7 + _hash11(phase) * 1.3) + phase * 6.2831);
	float noise_break = sin(NODE_POSITION_WORLD.x * 0.35 + NODE_POSITION_WORLD.z * 0.29 + TIME * 0.8);
	float bend = v_height_norm * v_height_norm * strength * (0.65 + 0.35 * wave + 0.15 * noise_break);
	VERTEX.xz += wind_dir.xz * bend;
	// Slight tip lift so blades don't flatten into the ground.
	VERTEX.y += bend * 0.08;
}

void fragment() {
	vec3 col = mix(color_bottom.rgb, color_top.rgb, v_height_norm);
	// Tiny per-instance tint so fields don't look painted.
	float tint = 0.92 + 0.16 * _hash11(v_instance_phase * 13.7);
	col *= tint;
	// Cooler night cast from shared time-of-day stub (0 day -> 1 night).
	col = mix(col, col * vec3(0.75, 0.85, 1.05), clamp(gw_time_of_day, 0.0, 1.0) * 0.35);
	ALBEDO = col;
	ROUGHNESS = 0.92;
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
}
