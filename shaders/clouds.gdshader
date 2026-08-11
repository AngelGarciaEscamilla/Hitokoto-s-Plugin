shader_type sky;
render_mode use_half_res_pass, use_quarter_res_pass;

uniform sampler3D worlnoise : filter_linear_mipmap, repeat_enable;
uniform sampler3D perlworlnoise : filter_linear_mipmap, repeat_enable;
uniform sampler2D weathermap : filter_linear_mipmap, repeat_enable;

uniform bool clouds_enabled = true;

uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_speed : hint_range(0.0, 20.0) = 1.0;
uniform float _density : hint_range(0.01, 0.2) = 0.05;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.25;
uniform float _time_offset : hint_range(0.0, 1000.0, 0.5) = 0.0;

uniform int cloud_steps : hint_range(8, 64) = 48;
uniform int light_steps : hint_range(1, 4) = 2;

const float g_radius = 6000000.0;
const float sky_b_radius = 6001500.0;
const float sky_t_radius = 6004000.0;

uniform float rayleigh_night : hint_range(0, 64) = 2.0;
uniform float rayleigh_day : hint_range(0, 64) = 2.0;

uniform vec4 rayleigh_color_day : source_color =
	vec4(0.26, 0.41, 0.58, 1.0);

uniform vec4 rayleigh_color_night : source_color =
	vec4(0.015686, 0.035294, 0.062745, 1.0);

uniform float mie : hint_range(0, 1) = 0.005;

uniform float mie_eccentricity : hint_range(-1, 1, 0.0001) = 0.8;

uniform vec4 mie_color : source_color =
	vec4(0.63, 0.77, 0.92, 1.0);

uniform float turbidity : hint_range(0, 1000) = 10.0;
uniform float sun_size : hint_range(0, 360) = 3.0;

uniform vec4 ground_color : source_color =
	vec4(0.0, 0.0, 0.0, 1.0);

uniform float exposure : hint_range(0, 128) = 0.2;

const vec3 UP = vec3(0.0, 1.0, 0.0);

const float rayleigh_zenith_size = 8.4e3;
const float mie_zenith_size = 1.25e3;

uniform sampler2D moon_texture : filter_linear_mipmap, repeat_disable;

uniform float moon_size : hint_range(0.01, 0.5) = 0.022;
uniform float moon_brightness : hint_range(0.1, 5.0) = 1.0;

uniform sampler2D star_map : filter_linear, repeat_disable;

uniform float star_map_intensity : hint_range(-0.3, 5.0) = -0.1;
uniform float stars_rotation_speed = 0.001;
uniform vec3 stars_rotation_axis = vec3(0.0, 0.8, 0.6);


vec3 rotate_axis(vec3 dir, vec3 axis, float angle) {
	axis = normalize(axis);

	float s = sin(angle);
	float c = cos(angle);

	return dir * c +
		cross(axis, dir) * s +
		axis * dot(axis, dir) * (1.0 - c);
}


vec2 starUV(vec3 dir) {
	return vec2(
		0.5 + atan(dir.z, dir.x) * 0.15915494309,
		0.5 - asin(dir.y) * 0.31830988618
	);
}


float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;

	return fract(
		p.x *
		p.y *
		p.z *
		(p.x + p.y + p.z)
	);
}


float remap(
	float value,
	float inMin,
	float inMax,
	float outMin,
	float outMax
) {
	return outMin +
		(value - inMin) *
		(outMax - outMin) /
		(inMax - inMin);
}


float henyey_greenstein(
	float cos_theta,
	float g
) {
	return 0.0795774715459 *
		(1.0 - g * g) /
		pow(
			1.0 +
			g * g -
			2.0 * g * cos_theta,
			1.5
		);
}


vec3 atmosphere(vec3 eye_dir) {

	vec3 sun_dir = normalize(LIGHT0_DIRECTION);
	vec3 moon_dir = normalize(LIGHT1_DIRECTION);

	float day_factor =
		smoothstep(
			-0.15,
			0.15,
			LIGHT0_DIRECTION.y
		);

	float sun_zenith_angle =
		clamp(
			dot(UP, sun_dir),
			-1.0,
			1.0
		);

	float moon_zenith_angle =
		clamp(
			dot(UP, moon_dir),
			-1.0,
			1.0
		);

	float sun_energy =
		max(
			0.0,
			1.0 -
			exp(
				-(
					(PI * 0.5) -
					acos(sun_zenith_angle)
				)
			)
		) *
		(LIGHT0_ENERGY * 1000.0);

	float moon_energy =
		max(
			0.0,
			1.0 -
			exp(
				-(
					(PI * 0.5) -
					acos(moon_zenith_angle)
				)
			)
		) *
		(LIGHT1_ENERGY * 1000.0);

	float sun_fade =
		1.0 -
		clamp(
			1.0 -
			exp(LIGHT0_DIRECTION.y),
			0.0,
			1.0
		);

	float moon_fade =
		1.0 -
		clamp(
			1.0 -
			exp(LIGHT1_DIRECTION.y),
			0.0,
			1.0
		);

	float current_rayleigh =
		mix(
			rayleigh_night,
			rayleigh_day,
			day_factor
		);

	vec3 current_rayleigh_color =
		mix(
			rayleigh_color_night.rgb,
			rayleigh_color_day.rgb,
			day_factor
		);

	float current_fade =
		mix(
			moon_fade,
			sun_fade,
			day_factor
		);

	float rayleigh_coefficient =
		current_rayleigh -
		(1.0 - current_fade);

	vec3 rayleigh_beta =
		rayleigh_coefficient *
		current_rayleigh_color *
		0.0001;

	vec3 mie_beta =
		turbidity *
		mie *
		mie_color.rgb *
		0.000434;

	float zenith =
		acos(
			max(
				0.0,
				dot(UP, eye_dir)
			)
		);

	float optical_mass =
		1.0 /
		(
			cos(zenith) +
			0.15 *
			pow(
				93.885 - degrees(zenith),
				-1.253
			)
		);

	float rayleigh_scatter =
		rayleigh_zenith_size *
		optical_mass;

	float mie_scatter =
		mie_zenith_size *
		optical_mass;

	vec3 extinction =
		exp(
			-(
				rayleigh_beta *
				rayleigh_scatter +
				mie_beta *
				mie_scatter
			)
		);

	float sun_cos_theta =
		dot(eye_dir, sun_dir);

	float moon_cos_theta =
		dot(eye_dir, moon_dir);

	float sun_mie_phase =
		henyey_greenstein(
			sun_cos_theta,
			mie_eccentricity
		);

	float moon_fullness =
		dot(
			moon_dir,
			-sun_dir
		);

	float moon_mie_eccentricity =
		clamp(
			mie_eccentricity -
			moon_fullness,
			-0.5,
			0.8
		);

	float moon_mie_phase =
		henyey_greenstein(
			moon_cos_theta,
			moon_mie_eccentricity
		);

	float sun_mie_strength =
		smoothstep(
			-0.25,
			0.1,
			LIGHT0_DIRECTION.y
		);

	float moon_mie_strength =
		smoothstep(
			0.1,
			-0.25,
			LIGHT0_DIRECTION.y
		);

	float sun_mie =
		sun_mie_phase *
		sun_mie_strength;

	float moon_mie =
		moon_mie_phase *
		moon_mie_strength;

	vec3 betaMTheta =
		mie_beta *
		(
			sun_mie +
			moon_mie
		);

	float cos_theta =
		mix(
			moon_cos_theta,
			sun_cos_theta,
			day_factor
		);

	float rayleigh_phase =
		(3.0 / (16.0 * PI)) *
		(
			1.0 +
			pow(
				cos_theta * 0.5 + 0.5,
				2.0
			)
		);

	vec3 betaRTheta =
		rayleigh_beta *
		rayleigh_phase;

	float current_energy =
		mix(
			moon_energy,
			sun_energy,
			day_factor
		);

	vec3 scattering =
		(
			betaRTheta +
			betaMTheta
		) /
		(rayleigh_beta + mie_beta);

	vec3 Lin =
		pow(
			current_energy *
			scattering *
			(1.0 - extinction),
			vec3(1.5)
		);

	Lin *= mix(
		vec3(1.0),
		pow(
			current_energy *
			scattering *
			extinction,
			vec3(0.5)
		),
		clamp(
			pow(
				1.0 -
				mix(
					moon_zenith_angle,
					sun_zenith_angle,
					day_factor
				),
				5.0
			),
			0.0,
			1.0
		)
	);

	Lin *= mix(
		ground_color.rgb,
		vec3(1.0),
		smoothstep(
			-0.1,
			0.1,
			dot(UP, eye_dir)
		)
	);

	float sundisk =
		smoothstep(
			cos(
				0.00872663806 *
				sun_size
			),
			cos(
				0.00872663806 *
				sun_size *
				0.5
			),
			sun_cos_theta
		);

	vec3 L0 =
		sun_energy *
		1900.0 *
		extinction *
		sundisk *
		LIGHT0_COLOR *
		day_factor;

	vec3 color =
		(Lin + L0) *
		0.04;

	color =
		pow(
			color,
			vec3(
				1.0 /
				(
					1.2 +
					1.2 * current_fade
				)
			)
		);

	return color * exposure;
}


float GetHeightFractionForPoint(float inPosition) {
	return clamp(
		(inPosition - sky_b_radius) /
		(sky_t_radius - sky_b_radius),
		0.0,
		1.0
	);
}


vec4 mixGradients(float cloudType) {

	const vec4 STRATUS_GRADIENT =
		vec4(0.02, 0.05, 0.09, 0.11);

	const vec4 STRATOCUMULUS_GRADIENT =
		vec4(0.02, 0.2, 0.48, 0.625);

	const vec4 CUMULUS_GRADIENT =
		vec4(0.01, 0.0625, 0.78, 1.0);

	float stratus =
		1.0 -
		clamp(
			cloudType * 2.0,
			0.0,
			1.0
		);

	float stratocumulus =
		1.0 -
		abs(cloudType - 0.5) * 2.0;

	float cumulus =
		clamp(
			cloudType - 0.5,
			0.0,
			1.0
		) * 2.0;

	return
		STRATUS_GRADIENT * stratus +
		STRATOCUMULUS_GRADIENT * stratocumulus +
		CUMULUS_GRADIENT * cumulus;
}


float densityHeightGradient(
	float heightFrac,
	float cloudType
) {

	vec4 cloudGradient =
		mixGradients(cloudType);

	return
		smoothstep(
			cloudGradient.x,
			cloudGradient.y,
			heightFrac
		) -
		smoothstep(
			cloudGradient.z,
			cloudGradient.w,
			heightFrac
		);
}


float intersectSphere(
	vec3 pos,
	vec3 dir,
	float r
) {

	float a = dot(dir, dir);
	float b = 2.0 * dot(dir, pos);
	float c = dot(pos, pos) - r * r;

	float discriminant =
		b * b -
		4.0 * a * c;

	if (discriminant <= 0.0)
		return 0.0;

	float d = sqrt(discriminant);

	return max(
		-b - d,
		-b + d
	) / (2.0 * a);
}


float density(
	vec3 pip,
	vec3 weather,
	float mip
) {

	float time = TIME;

	vec3 p = pip;

	float height_fraction =
		GetHeightFractionForPoint(
			length(p)
		);

	p.xz +=
		time *
		20.0 *
		normalize(wind_direction) *
		wind_speed *
		0.6;

	float adjusted_mip =
		mip *
		(2.0);

	vec4 n =
		textureLod(
			perlworlnoise,
			p * 0.00008,
			adjusted_mip - 2.0
		);

	float fbm =
		n.g * 0.625 +
		n.b * 0.25 +
		n.a * 0.125;

	float g =
		densityHeightGradient(
			height_fraction,
			weather.r
		);

	float base_cloud =
		remap(
			n.r,
			-(1.0 - fbm),
			1.0,
			0.0,
			1.0
		);

	float weather_coverage =
		cloud_coverage *
		weather.b;

	base_cloud =
		remap(
			base_cloud * g,
			1.0 - weather_coverage,
			1.0,
			0.0,
			1.0
		);

	base_cloud *=
		weather_coverage;

	p.xz -=
		time *
		normalize(wind_direction) *
		40.0;

	p.y -=
		time *
		40.0;

	vec3 hn =
		textureLod(
			worlnoise,
			p * 0.001,
			adjusted_mip
		).rgb;

	float hfbm =
		hn.r * 0.625 +
		hn.g * 0.25 +
		hn.b * 0.125;

	hfbm =
		mix(
			hfbm,
			1.0 - hfbm,
			clamp(
				height_fraction * 4.0,
				0.0,
				1.0
			)
		);

	base_cloud =
		remap(
			base_cloud,
			hfbm *
			0.4 *
			height_fraction,
			1.0,
			0.0,
			1.0
		);

	return pow(
		clamp(
			base_cloud,
			0.0,
			1.0
		),
		(1.0 - height_fraction) *
		0.8 +
		0.5
	);
}


vec4 drawMoonWithTexture(
	vec3 dir,
	vec3 moon_dir,
	vec3 sun_dir
) {

	float angle =
		acos(
			clamp(
				dot(dir, moon_dir),
				-1.0,
				1.0
			)
		);

	float radius = moon_size;

	if (angle > radius)
		return vec4(0.0);

	vec3 rel_dir =
		normalize(dir);

	vec3 right;
	vec3 up;

	if (abs(moon_dir.y) < 0.999) {

		right =
			normalize(
				cross(
					vec3(0.0, 1.0, 0.0),
					moon_dir
				)
			);

		up =
			normalize(
				cross(
					moon_dir,
					right
				)
			);

	} else {

		right =
			vec3(1.0, 0.0, 0.0);

		up =
			normalize(
				cross(
					moon_dir,
					right
				)
			);
	}

	float u =
		dot(rel_dir, right) *
		0.5 /
		radius +
		0.5;

	float v =
		dot(rel_dir, up) *
		0.5 /
		radius +
		0.5;

	if (
		u < 0.0 ||
		u > 1.0 ||
		v < 0.0 ||
		v > 1.0
	)
		return vec4(0.0);

	float x =
		u * 2.0 - 1.0;

	float y =
		v * 2.0 - 1.0;

	float z =
		sqrt(
			max(
				0.0,
				1.0 -
				x * x -
				y * y
			)
		);

	vec3 moon_surface =
		normalize(
			right * x +
			up * y +
			moon_dir * z
		);

	float illumination =
		dot(
			moon_surface,
			sun_dir
		);

	float phase_raw =
		illumination * 0.5 +
		0.5;

	float phase =
		smoothstep(
			0.35,
			0.65,
			phase_raw
		);

	float sun_distance =
		dot(
			moon_dir,
			sun_dir
		);

	float sun_proximity =
		smoothstep(
			-0.2,
			1.0,
			sun_distance
		);

	float moon_visibility =
		1.0 -
		pow(
			sun_proximity,
			2.5
		);

	float sun_angle =
		acos(
			clamp(
				dot(
					dir,
					sun_dir
				),
				-1.0,
				1.0
			)
		);

	float sun_radius =
		0.00872663806 *
		sun_size;

	float eclipse_mask =
		smoothstep(
			sun_radius * 1.2,
			sun_radius * 0.8,
			sun_angle
		);

	vec4 moon_color =
		textureLod(
			moon_texture,
			vec2(u, v),
			0.0
		);

	float edge =
		smoothstep(
			radius,
			radius * 0.85,
			angle
		);

	float mie_cos =
		dot(
			normalize(dir),
			sun_dir
		);

	float mie_phase =
		henyey_greenstein(
			mie_cos,
			mie_eccentricity
		);

	mie_phase =
		clamp(
			mie_phase * 0.05,
			0.0,
			1.0
		);

	float moon_mie =
		mie_phase *
		pow(phase, 2.0);

	vec3 moon_light =
		moon_color.rgb *
		moon_brightness;

	moon_light +=
		mie_color.rgb *
		moon_mie *
		moon_brightness;

	float normal_alpha =
		phase *
		edge *
		moon_visibility;

	vec3 normal_moon =
		moon_light *
		edge *
		phase *
		moon_visibility;

	vec3 eclipse_moon =
		vec3(0.0);

	float final_alpha =
		max(
			normal_alpha,
			eclipse_mask
		);

	vec3 final_moon =
		mix(
			normal_moon,
			eclipse_moon,
			eclipse_mask
		);

	return vec4(
		final_moon,
		final_alpha
	);
}


vec4 march(
	vec3 pos,
	vec3 end,
	vec3 dir,
	int depth,
	vec3 atmosphere_sun,
	vec3 atmosphere_ambient,
	vec3 atmosphere_ground
) {

	const vec3 RANDOM_VECTORS[6] = vec3[](
		vec3(0.38051305, 0.92453449, -0.02111345),
		vec3(-0.50625799, -0.03590792, -0.86163418),
		vec3(-0.32509218, -0.94557439, 0.01428793),
		vec3(0.09026238, -0.27376545, 0.95755106),
		vec3(0.28128598, 0.42443639, -0.86065785),
		vec3(-0.16852403, 0.14748697, 0.97460106)
	);

	float T = 1.0;
	float alpha = 0.0;

	float ss = length(dir);

	dir = normalize(dir);

	vec3 p =
		pos +
		dir *
		hash(pos * 10.0) *
		ss;

	const float t_dist =
		sky_t_radius -
		sky_b_radius;

	float lss =
		t_dist /
		36.0;

	vec3 ldir =
		normalize(LIGHT0_DIRECTION);

	float costheta =
		dot(ldir, dir);

	float phase =
		max(
			max(
				henyey_greenstein(
					costheta,
					0.6
				),
				henyey_greenstein(
					costheta,
					0.4 -
					1.4 * ldir.y
				)
			),
			henyey_greenstein(
				costheta,
				-0.2
			)
		);

	float time =
		TIME * 0.001 +
		0.005 * _time_offset;

	const float weather_scale =
		0.00006;

	vec2 weather_pos =
		time *
		normalize(wind_direction) *
		wind_speed;

	vec3 L =
		vec3(0.0);

	for (int i = 0; i < depth; i++) {

		if (T < 0.01)
			break;

		p +=
			dir *
			ss;

		vec3 weather_sample =
			texture(
				weathermap,
				p.xz *
				weather_scale +
				0.5 +
				weather_pos
			).xyz;

		float height_fraction =
			GetHeightFractionForPoint(
				length(p)
			);

		float t =
			density(
				p,
				weather_sample,
				0.0
			);

		if (t <= 0.001)
			continue;

		float dt =
			exp(
				-_density *
				t *
				ss
			);

		float absorption =
			1.0 - dt;

		T *= dt;

		vec3 lp = p;

		float cd = 0.0;

		int steps =
			max(
				light_steps - 1,
				1
			);

		for (int j = 0; j < steps; j++) {

			lp +=
				(
					ldir +
					RANDOM_VECTORS[j] *
					float(j)
				) *
				lss;

			vec3 lweather =
				texture(
					weathermap,
					lp.xz *
					weather_scale +
					0.5 +
					weather_pos
				).xyz;

			cd +=
				density(
					lp,
					lweather,
					float(j)
				);
		}

		lp =
			p +
			ldir *
			18.0 *
			lss;

		vec3 lweather =
			texture(
				weathermap,
				lp.xz *
				weather_scale +
				0.5
			).xyz;

		cd +=
			density(
				lp,
				lweather,
				3.0
			);

		float beers =
			exp(
				-_density *
				cd *
				lss
			);

		float beers2 =
			exp(
				-_density *
				cd *
				lss *
				0.25
			) *
			0.7;

		float beers_total =
			max(
				beers,
				beers2
			);

		vec3 ambient =
			mix(
				atmosphere_ground,
				vec3(1.0),
				smoothstep(
					0.0,
					1.0,
					height_fraction
				)
			) *
			_density *
			mix(
				atmosphere_ambient,
				vec3(1.0),
				0.4
			) -
			LIGHT0_DIRECTION.y;

		alpha +=
			absorption *
			(1.0 - alpha);

		L +=
			(
				ambient +
				beers_total *
				atmosphere_sun *
				phase *
				alpha
			) *
			T *
			t;
	}

	return clamp(
		vec4(L, alpha),
		0.0,
		1.0
	);
}


vec3 drawStars(vec3 dir) {

	vec3 eye_dir =
		normalize(dir);

	float star_angle =
		TIME *
		stars_rotation_speed;

	vec3 star_dir =
		rotate_axis(
			eye_dir,
			stars_rotation_axis,
			star_angle
		);

	vec2 uv =
		starUV(star_dir);

	vec4 star_data =
		texture(
			star_map,
			uv
		);

	float stars =
		star_data.r *
		star_map_intensity;

	float star_id =
		hash(
			vec3(
				floor(uv.x * 2048.0),
				floor(uv.y * 1024.0),
				0.0
			)
		);

	float twinkle =
		sin(
			TIME * 2.0 +
			star_id * 10.0
		) *
		0.5 +
		0.5;

	stars *=
		mix(
			0.7,
			1.3,
			twinkle
		);

	stars *=
		smoothstep(
			0.0,
			0.2,
			dir.y
		);

	float milky_way =
		star_data.g *
		0.5;

	stars +=
		milky_way *
		smoothstep(
			0.0,
			0.3,
			dir.y
		);

	return vec3(stars);
}


void sky() {

	vec3 dir =
		EYEDIR;

	vec3 sun_dir =
		normalize(
			LIGHT0_DIRECTION
		);

	vec3 moon_dir =
		normalize(
			LIGHT1_DIRECTION
		);

	vec3 camPos =
		vec3(
			0.0,
			g_radius,
			0.0
		);

	vec3 start =
		camPos +
		dir *
		intersectSphere(
			camPos,
			dir,
			sky_b_radius
		);

	vec3 end =
		camPos +
		dir *
		intersectSphere(
			camPos,
			dir,
			sky_t_radius
		);

	float shelldist =
		length(
			end - start
		);

	float horizon =
		clamp(
			dir.y,
			0.0,
			1.0
		);

	float steps =
		mix(
			float(cloud_steps) * 0.75,
			float(cloud_steps),
			horizon
		);

	vec3 raystep =
		dir *
		shelldist /
		steps;

	vec3 atmosphere_sun =
		atmosphere(
			LIGHT0_DIRECTION
		);

	vec3 atmosphere_ambient =
		atmosphere(
			normalize(
				vec3(
					1.0,
					1.0,
					0.0
				)
			)
		);

	vec3 atmosphere_ground =
		atmosphere(
			normalize(
				vec3(
					1.0,
					-1.0,
					0.0
				)
			)
		);

	vec4 volume =
		vec4(0.0);

	if (clouds_enabled) {

		volume =
			march(
				start,
				end,
				raystep,
				int(steps),
				atmosphere_sun *
				LIGHT0_ENERGY *
				length(raystep) *
				0.1,
				atmosphere_ambient,
				atmosphere_ground
			);
	}

	float sun_moon_alignment =
		dot(
			sun_dir,
			moon_dir
		);

	float eclipse_darkness =
		smoothstep(
			0.98,
			1.0,
			sun_moon_alignment
		);

	vec3 background =
		atmosphere(dir);

	background *=
		mix(
			1.0,
			0.15,
			eclipse_darkness
		);

	float sun_height =
		sun_dir.y;

	float star_intensity =
		1.0 -
		smoothstep(
			-0.05,
			0.15,
			sun_height
		);

	vec3 stars =
		drawStars(dir) *
		star_intensity;

	vec4 moon =
		drawMoonWithTexture(
			dir,
			moon_dir,
			sun_dir
		);

	float day_factor =
		smoothstep(
			-0.35,
			0.45,
			LIGHT0_DIRECTION.y
		);

	float cloud_alpha =
		mix(
			volume.a,
			volume.r,
			day_factor
		);

	vec3 sky_with_moon =
		background *
		(1.0 - moon.a) +
		moon.rgb +
		stars *
		(1.0 - moon.a);

	vec3 final_color =
		sky_with_moon *
		(1.0 - cloud_alpha) +
		volume.rgb;

	final_color =
		mix(
			clamp(
				final_color,
				vec3(0.0),
				vec3(1.0)
			),
			clamp(
				background,
				vec3(0.0),
				vec3(1.0)
			),
			smoothstep(
				0.8,
				1.0,
				1.0 - dir.y
			)
		);

	COLOR =
		final_color;
}