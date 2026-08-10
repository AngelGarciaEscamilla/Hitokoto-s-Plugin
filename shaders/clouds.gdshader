shader_type sky;
render_mode use_half_res_pass, use_quarter_res_pass;

uniform sampler3D worlnoise : filter_linear_mipmap, repeat_enable;
uniform sampler3D perlworlnoise : filter_linear_mipmap, repeat_enable;
uniform sampler2D weathermap : filter_linear_mipmap, repeat_enable;

uniform vec2 wind_direction = vec2(1, 0);
uniform float wind_speed : hint_range(0.0, 20.0) = 1.0;
uniform float _density : hint_range(0.01, 0.2) = 0.05;
uniform float cloud_coverage :hint_range(0.0, 1.0) = 0.25;
uniform float _time_offset : hint_range(0.0, 1000.0, 0.5) = 0.0;

uniform int cloud_steps : hint_range(16, 96) = 48;
uniform int light_steps : hint_range(2, 6) = 4;
uniform bool high_quality_lighting = false;
uniform float cloud_detail : hint_range(0.1, 1.0) = 0.8;

const float g_radius = 6000000.0;
const float sky_b_radius = 6001500.0;
const float sky_t_radius = 6004000.0;

uniform float rayleigh_night : hint_range(0, 64) = 2.0;
uniform float rayleigh_day : hint_range(0, 64) = 2.0;
uniform vec4 rayleigh_color_day : source_color = vec4(0.26, 0.41, 0.58, 1.0);
uniform vec4 rayleigh_color_night : source_color = vec4(0.05, 0.1, 0.15, 1.0);
uniform float mie : hint_range(0, 1) = 0.005;
uniform float mie_eccentricity : hint_range(-1, 1) = 0.8;
uniform vec4 mie_color : source_color = vec4(0.63, 0.77, 0.92, 1.0);

uniform float turbidity : hint_range(0, 1000) = 10.0;
uniform float sun_disk_scale : hint_range(0, 360) = 1.0;
uniform vec4 ground_color : source_color = vec4(0.0,0.0,0.0,1.0);
uniform float exposure : hint_range(0, 128) = 0.2;

const vec3 UP = vec3(0.0, 1.0, 0.0);
const float SUN_SIZE = 0.00872663806;
const float rayleigh_zenith_size = 8.4e3;
const float mie_zenith_size = 1.25e3;

uniform sampler2D moon_texture : filter_linear_mipmap, repeat_disable;
uniform float moon_size : hint_range(0.01, 0.5) = 0.1;
uniform float moon_brightness : hint_range(0.1, 5.0) = 1.0;

uniform sampler2D star_map : filter_linear, repeat_disable;
uniform float star_map_intensity : hint_range(0.0, 5.0) = 1.0;

vec2 starUV(vec3 dir) {
    return vec2(0.5 + atan(dir.z, dir.x) * 0.15915494309, 
           0.5 - asin(dir.y) * 0.31830988618);
}

float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float remap(float value, float inMin, float inMax, float outMin, float outMax) {
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin);
}

float henyey_greenstein(float cos_theta, float g) {
    return 0.0795774715459 * (1.0 - g*g) / pow(1.0 + g*g - 2.0*g*cos_theta, 1.5);
}

vec3 atmosphere(vec3 eye_dir) {
	vec3 current_light_direction = vec3(0.0);
	float current_light_energy = 0.0;
	vec3 current_light_color = vec3(0.0);
	vec4 current_rayleigh_color = vec4(0.0);
	float current_rayleigh = 0.0;
	if (LIGHT0_DIRECTION.y > 0.0) {
		current_light_direction = LIGHT0_DIRECTION;
		current_light_energy = LIGHT0_ENERGY;
		current_light_color = LIGHT0_COLOR;
		current_rayleigh = rayleigh_day;
		current_rayleigh_color = rayleigh_color_day;
	} else{
		current_light_direction = LIGHT1_DIRECTION;
		current_light_energy = LIGHT1_ENERGY;
		current_light_color = LIGHT1_COLOR;
		current_rayleigh = rayleigh_night;
		current_rayleigh_color = rayleigh_color_night;
	}
	float zenith_angle = clamp( dot(UP, normalize(current_light_direction)), -1.0, 1.0 );
	float sun_energy = max(0.0, 1.0 - exp(-((PI * 0.5) - acos(zenith_angle)))) * (current_light_energy * 1000.0);
	float sun_fade = 1.0 - clamp(1.0 - exp(current_light_direction.y), 0.0, 1.0);

    float rayleigh_coefficient = current_rayleigh - (1.0 * (1.0 - sun_fade));
    vec3 rayleigh_beta = rayleigh_coefficient * current_rayleigh_color.rgb * 0.0001;
    vec3 mie_beta = turbidity * mie * mie_color.rgb * 0.000434;

    float zenith = acos(max(0.0, dot(UP, eye_dir)));
    float optical_mass = 1.0 / (cos(zenith) + 0.15 * pow(93.885 - degrees(zenith), -1.253));
    float rayleigh_scatter = rayleigh_zenith_size * optical_mass;
    float mie_scatter = mie_zenith_size * optical_mass;

    vec3 extinction = exp(-(rayleigh_beta * rayleigh_scatter + mie_beta * mie_scatter));

    float cos_theta = dot(eye_dir, normalize(current_light_direction));
    float rayleigh_phase = (3.0 / (16.0 * PI)) * (1.0 + pow(cos_theta * 0.5 + 0.5, 2.0));
    vec3 betaRTheta = rayleigh_beta * rayleigh_phase;
    float mie_phase = henyey_greenstein(cos_theta, mie_eccentricity);
    vec3 betaMTheta = mie_beta * mie_phase;

    vec3 Lin = pow(sun_energy * ((betaRTheta + betaMTheta) / (rayleigh_beta + mie_beta)) * (1.0 - extinction), vec3(1.5));
    Lin *= mix(vec3(1.0), pow(sun_energy * ((betaRTheta + betaMTheta) / (rayleigh_beta + mie_beta)) * extinction, vec3(0.5)),
              clamp(pow(1.0 - zenith_angle, 5.0), 0.0, 1.0));
    Lin *= mix(ground_color.rgb, vec3(1.0), smoothstep(-0.1, 0.1, dot(UP, eye_dir)));

    float sundisk = smoothstep(cos(SUN_SIZE * sun_disk_scale), cos(SUN_SIZE * sun_disk_scale*0.5), cos_theta);
    vec3 L0 = (sun_energy * 1900.0 * extinction) * sundisk * current_light_color;

    vec3 color = (Lin + L0) * 0.04;
    color = pow(color, vec3(1.0 / (1.2 + (1.2 * sun_fade))));
    return color * exposure;
}

float GetHeightFractionForPoint(float inPosition) {
    return clamp((inPosition - sky_b_radius) / (sky_t_radius - sky_b_radius), 0.0, 1.0);
}

vec4 mixGradients(float cloudType) {
    const vec4 STRATUS_GRADIENT = vec4(0.02, 0.05, 0.09, 0.11);
    const vec4 STRATOCUMULUS_GRADIENT = vec4(0.02, 0.2, 0.48, 0.625);
    const vec4 CUMULUS_GRADIENT = vec4(0.01, 0.0625, 0.78, 1.0);

    float stratus = 1.0 - clamp(cloudType * 2.0, 0.0, 1.0);
    float stratocumulus = 1.0 - abs(cloudType - 0.5) * 2.0;
    float cumulus = clamp(cloudType - 0.5, 0.0, 1.0) * 2.0;

    return STRATUS_GRADIENT * stratus + STRATOCUMULUS_GRADIENT * stratocumulus + CUMULUS_GRADIENT * cumulus;
}

float densityHeightGradient(float heightFrac, float cloudType) {
    vec4 cloudGradient = mixGradients(cloudType);
    return smoothstep(cloudGradient.x, cloudGradient.y, heightFrac) - smoothstep(cloudGradient.z, cloudGradient.w, heightFrac);
}

float intersectSphere(vec3 pos, vec3 dir, float r) {
    float a = dot(dir, dir);
    float b = 2.0 * dot(dir, pos);
    float c = dot(pos, pos) - (r * r);
    float d = sqrt((b*b) - 4.0*a*c);
    return max(-b - d, -b + d) / (2.0 * a);
}

float density(vec3 pip, vec3 weather, float mip) {
    float time = TIME;
    vec3 p = pip;
    float height_fraction = GetHeightFractionForPoint(length(p));
    p.xz += time * 20.0 * normalize(wind_direction) * wind_speed * 0.6;
    float adjusted_mip = mip * (2.0 - cloud_detail);
    vec4 n = textureLod(perlworlnoise, p.xyz*0.00008, adjusted_mip-2.0);
    float fbm = n.g*0.625 + n.b*0.25 + n.a*0.125;
    float g = densityHeightGradient(height_fraction, weather.r);
    float base_cloud = remap(n.r, -(1.0-fbm), 1.0, 0.0, 1.0);
    float weather_coverage = cloud_coverage*weather.b;
    base_cloud = remap(base_cloud*g, 1.0-weather_coverage, 1.0, 0.0, 1.0);
    base_cloud *= weather_coverage;
    p.xz -= time * normalize(wind_direction) * 40.0;
    p.y -= time * 40.0;
    vec3 hn = textureLod(worlnoise, p*0.001, adjusted_mip).rgb;
    float hfbm = hn.r*0.625 + hn.g*0.25 + hn.b*0.125;
    hfbm = mix(hfbm, 1.0-hfbm, clamp(height_fraction*4.0, 0.0, 1.0));
    base_cloud = remap(base_cloud, hfbm*0.4 * height_fraction, 1.0, 0.0, 1.0);
    return pow(clamp(base_cloud, 0.0, 1.0), (1.0 - height_fraction) * 0.8 + 0.5);
}

vec3 drawMoonWithTexture(vec3 dir, vec3 moon_dir) {
    float angle = acos(dot(dir, moon_dir));
    float radius = moon_size;
    if (angle > radius) return vec3(0.0);
    vec3 rel_dir = normalize(dir);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), moon_dir));
    vec3 up = normalize(cross(moon_dir, right));
    float u = dot(rel_dir, right) * 0.5 / radius + 0.5;
    float v = dot(rel_dir, up) * 0.5 / radius + 0.5;
    if (u < 0.0 || u > 1.0 || v < 0.0 || v > 1.0) return vec3(0.0);
    vec4 moon_color = textureLod(moon_texture, vec2(u, v), 0.0);
	float edge = smoothstep(radius, radius * 0.85, angle);
	moon_color.a = 20.0;
    return moon_color.rgb * moon_brightness * edge;
}

vec4 march(vec3 pos, vec3 end, vec3 dir, int depth) {
	const vec3 RANDOM_VECTORS[6] = vec3[](
		vec3(0.38051305, 0.92453449, -0.02111345),
		vec3(-0.50625799, -0.03590792, -0.86163418),
        vec3(-0.32509218, -0.94557439, 0.01428793),
        vec3(0.09026238, -0.27376545, 0.95755165),
        vec3(0.28128598, 0.42443639, -0.86065785),
        vec3(-0.16852403, 0.14748697, 0.97460106)
    );
    float T = 1.0;
    float alpha = 0.0;
    float ss = length(dir);
    dir = normalize(dir);
    vec3 p = pos + dir * hash(pos * 10.0) * ss;
    const float t_dist = sky_t_radius - sky_b_radius;
    float lss = t_dist / 36.0;
    vec3 ldir = normalize(LIGHT0_DIRECTION);
	float costheta = dot(ldir, dir);
	float phase = max(max(henyey_greenstein(costheta, 0.6),
	henyey_greenstein(costheta, (0.4 - 1.4 * ldir.y))),
	henyey_greenstein(costheta, -0.2));
    vec3 atmosphere_sun = atmosphere(LIGHT0_DIRECTION) * LIGHT0_ENERGY * ss * 0.1;
    vec3 atmosphere_ambient = atmosphere(normalize(vec3(1.0, 1.0, 0.0)));
    vec3 atmosphere_ground = atmosphere(normalize(vec3(1.0, -1.0, 0.0)));
    const float weather_scale = 0.00006;
    float time = TIME * 0.001 + 0.005 * _time_offset;
    vec2 weather_pos = time * normalize(wind_direction) * wind_speed;
    vec3 L = vec3(0.0);
    for (int i = 0; i < depth; i++) {
        p += dir * ss;
        vec3 weather_sample = texture(weathermap, p.xz * weather_scale + 0.5 + weather_pos).xyz;
        float height_fraction = GetHeightFractionForPoint(length(p));
        float t = density(p, weather_sample, 0.0);
        float dt = exp(-_density * t * ss);
        T *= dt;
        if (t > 0.0) {
            vec3 lp = p;
            float cd = 0.0;
            int steps = high_quality_lighting ? light_steps : max(light_steps - 2, 1);

            for (int j = 0; j < steps; j++) {
                lp += (ldir + RANDOM_VECTORS[j]*float(j)) * lss;
                vec3 lweather = texture(weathermap, lp.xz * weather_scale + 0.5 + weather_pos).xyz;
                cd += density(lp, lweather, float(j));
            }
            if (high_quality_lighting) {
                lp = p + ldir * 18.0 * lss;
                vec3 lweather = texture(weathermap, lp.xz * weather_scale + 0.5).xyz;
                cd += pow(density(lp, lweather, 5.0), (1.0 - GetHeightFractionForPoint(length(lp))) * 0.8 + 0.5);
            }
            float beers = exp(-_density * cd * lss);
            float beers2 = exp(-_density * cd * lss * 0.25) * 0.7;
            float beers_total = max(beers, beers2);

            vec3 ambient = mix(atmosphere_ground, vec3(1.0), smoothstep(0.0, 1.0, height_fraction)) *
                          _density * mix(atmosphere_ambient, vec3(1.0), 0.4) - (LIGHT0_DIRECTION.y);
            alpha += (1.0 - dt) * (1.0 - alpha);
            L += (ambient + beers_total * atmosphere_sun * phase * alpha) * T * t;
        }
    }
    return clamp(vec4(L, alpha), 0.0, 1.0);
}

vec3 drawStars(vec3 dir) {
	vec2 uv = starUV(dir);
	float star_map_value = texture(star_map, uv).r;
	float stars = star_map_value * star_map_intensity;
	float star_id = hash(vec3(
		floor(uv.x * 2048.0),
		floor(uv.y * 1024.0),
		0.0
	));
	float twinkle = sin(TIME * 2.0 + star_id * 10.0) * 0.5 + 0.5;
	stars *= mix(0.7, 1.3, twinkle);
	stars *= smoothstep(0.0, 0.2, dir.y);
	float milky_way = texture(star_map, uv).g * 0.5;
	stars += milky_way * smoothstep(0.0, 0.3, dir.y);
	return vec3(stars);
}

void sky() {
	vec3 dir = EYEDIR;
	vec3 camPos = vec3(0.0, g_radius, 0.0);
	vec3 start = camPos + dir * intersectSphere(camPos, dir, sky_b_radius);
	vec3 end = camPos + dir * intersectSphere(camPos, dir, sky_t_radius);
	float shelldist = length(end - start);
	float steps = mix(
		float(cloud_steps) * 0.75,
		float(cloud_steps),
		clamp(dot(dir, vec3(0.0, 1.0, 0.0)), 0.0, 1.0)
	);
	vec3 raystep = dir * shelldist / steps;
	vec4 volume = march(start, end, raystep, int(steps));
	vec3 background = atmosphere(dir);
	vec3 stars = drawStars(dir);
	vec3 moon_dir = -normalize(LIGHT0_DIRECTION);
	vec3 moon = drawMoonWithTexture(dir, moon_dir);
	vec3 sky_background = background + moon + stars;
	vec3 final_color = sky_background * (1.0 - volume.a) + volume.rgb;
	final_color = mix(
		clamp(final_color, vec3(0.0), vec3(1.0)),
		clamp(background, vec3(0.0), vec3(1.0)),
		smoothstep(0.6, 1.0, 1.0 - dir.y)
	);
	COLOR = final_color;
}