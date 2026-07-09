shader_type spatial;
render_mode cull_back, unshaded;

uniform sampler2D blend_control : source_color, filter_linear;
uniform vec2 map_size_m = vec2(350.0, 350.0);
uniform bool blend_enabled = false;

varying vec2 world_xz;
varying flat int terrain_class;

void vertex() {
	world_xz = vec2(VERTEX.x, VERTEX.z);
	terrain_class = int(round(COLOR.r * 6.0));
}

vec3 class_color(int class_id) {
	if (class_id == 0) {
		return vec3(0.55, 0.42, 0.28);
	}
	if (class_id == 1) {
		return vec3(0.22, 0.62, 0.28);
	}
	if (class_id == 2) {
		return vec3(0.16, 0.48, 0.22);
	}
	if (class_id == 3) {
		return vec3(0.52, 0.50, 0.46);
	}
	if (class_id == 4) {
		return vec3(0.34, 0.46, 0.30);
	}
	if (class_id == 5) {
		return vec3(0.38, 0.38, 0.40);
	}
	return vec3(0.72, 0.58, 0.34);
}

void fragment() {
	if (!blend_enabled) {
		ALBEDO = class_color(terrain_class);
		return;
	}
	vec2 blend_uv = world_xz / map_size_m;
	blend_uv = clamp(blend_uv, vec2(0.0), vec2(1.0));
	vec3 blend_data = texture(blend_control, blend_uv).rgb;
	int primary_class = int(round(blend_data.r * 6.0));
	int secondary_class = int(round(blend_data.g * 6.0));
	float blend_weight = blend_data.b;
	vec3 primary_col = class_color(primary_class);
	vec3 secondary_col = class_color(secondary_class);
	vec3 mixed = mix(primary_col, secondary_col, blend_weight);
	ALBEDO = mix(primary_col, mixed, step(0.001, blend_weight));
}
