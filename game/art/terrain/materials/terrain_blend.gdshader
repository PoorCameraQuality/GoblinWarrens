shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform sampler2D tex_mud_clearing : source_color, repeat_enable;
uniform sampler2D tex_moss : source_color, repeat_enable;
uniform sampler2D tex_forest_floor : source_color, repeat_enable;
uniform sampler2D tex_rocky_slope : source_color, repeat_enable;
uniform sampler2D tex_mud_mossy : source_color, repeat_enable;
uniform sampler2D tex_cliff : source_color, repeat_enable;
uniform sampler2D tex_warren_ground : source_color, repeat_enable;
uniform sampler2D blend_control : source_color, filter_linear;
uniform bool blend_enabled = false;
uniform vec2 map_size_m = vec2(350.0, 350.0);
uniform float uv_scale = 0.35;
uniform float roughness = 0.92;
uniform float blend_noise_strength = 0.15;
uniform float blend_noise_scale = 0.08;

varying vec2 terrain_uv;
varying vec2 world_xz;
varying flat int terrain_class;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec3 sample_class(int class_id, vec2 uv) {
	if (class_id == 0) {
		return texture(tex_mud_clearing, uv).rgb;
	}
	if (class_id == 1) {
		return texture(tex_moss, uv).rgb;
	}
	if (class_id == 2) {
		return texture(tex_forest_floor, uv).rgb;
	}
	if (class_id == 3) {
		return texture(tex_rocky_slope, uv).rgb;
	}
	if (class_id == 4) {
		return texture(tex_mud_mossy, uv).rgb;
	}
	if (class_id == 5) {
		return texture(tex_cliff, uv).rgb;
	}
	return texture(tex_warren_ground, uv).rgb;
}

void vertex() {
	terrain_uv = vec2(VERTEX.x, VERTEX.z) * uv_scale;
	world_xz = vec2(VERTEX.x, VERTEX.z);
	terrain_class = int(round(COLOR.r * 6.0));
}

void fragment() {
	int primary_class = terrain_class;
	int secondary_class = terrain_class;
	float blend_weight = 0.0;

	if (blend_enabled) {
		vec2 blend_uv = world_xz / map_size_m;
		blend_uv = clamp(blend_uv, vec2(0.0), vec2(1.0));
		vec3 blend_data = texture(blend_control, blend_uv).rgb;
		primary_class = int(round(blend_data.r * 6.0));
		secondary_class = int(round(blend_data.g * 6.0));
		blend_weight = blend_data.b;
		float noise = value_noise(terrain_uv * blend_noise_scale) * 2.0 - 1.0;
		blend_weight = clamp(blend_weight + noise * blend_noise_strength, 0.0, 1.0);
	}

	vec3 primary_albedo = sample_class(primary_class, terrain_uv);
	vec3 secondary_albedo = sample_class(secondary_class, terrain_uv);
	ALBEDO = mix(primary_albedo, secondary_albedo, blend_weight);
	ROUGHNESS = roughness;
}
