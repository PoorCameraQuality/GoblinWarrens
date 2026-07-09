shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 color_mud_clearing = vec3(0.82, 0.62, 0.28);
uniform vec3 color_moss = vec3(0.35, 0.72, 0.28);
uniform vec3 color_forest_floor = vec3(0.18, 0.48, 0.16);
uniform vec3 color_rocky_slope = vec3(0.62, 0.58, 0.50);
uniform vec3 color_mud_mossy = vec3(0.48, 0.55, 0.28);
uniform vec3 color_cliff = vec3(0.38, 0.38, 0.42);
uniform vec3 color_warren_ground = vec3(0.72, 0.42, 0.22);

varying flat int terrain_class;

void vertex() {
	terrain_class = int(round(COLOR.r * 6.0));
}

vec3 class_color(int class_id) {
	if (class_id == 0) {
		return color_mud_clearing;
	}
	if (class_id == 1) {
		return color_moss;
	}
	if (class_id == 2) {
		return color_forest_floor;
	}
	if (class_id == 3) {
		return color_rocky_slope;
	}
	if (class_id == 4) {
		return color_mud_mossy;
	}
	if (class_id == 5) {
		return color_cliff;
	}
	return color_warren_ground;
}

void fragment() {
	ALBEDO = class_color(terrain_class);
}
