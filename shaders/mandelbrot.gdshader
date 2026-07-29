shader_type canvas_item;

uniform int limit = 1;
uniform vec2 center;
const vec2 margin = vec2(2.5,1.5);

bool mandelbrot(float y,float x) {
	float origin_y = y;
	float origin_x = x;
	int i = 0;

	while (i++ < limit) {
		if (x*x+y*y > 4.0){
			return false;

		}
		float new_x = x * x - y * y + origin_x;
		y = 2.0 * x * y + origin_y;
		x = new_x;
	}

	return true;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float x = mix(center.x - margin.x, center.x + center.x, SCREEN_UV.x);
	float y = mix(center.y - margin.y, center.y + center.y, SCREEN_UV.y);
	if (mandelbrot(y,x)) {
		COLOR = vec4(0.0,0.0,0.0,1.0);
	} else {
		COLOR = vec4(1.0,1.0,1.0,1.0);


	}

}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
