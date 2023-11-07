shader_type spatial;

group_uniforms light_parameters;

uniform vec3 albedo : source_color;
uniform float rim : hint_range(0.0, 1.0, 0.1);
uniform float roughness : hint_range(0.0, 1.0, 0.005);
uniform float metallic : hint_range(0.0, 1.0, 0.1);

group_uniforms vertex_parameters;

uniform float max_peak : hint_range(0.0, 10.0, 0.1);
uniform float peak_offset : hint_range(0.5, 2.0, 0.1);
uniform float wave_drag : hint_range(0.0, 30.0, 0.1);
uniform float initial_speed : hint_range(3.0, 6.0, 0.1);
uniform float speed_multiplier : hint_range(0.8, 1.0, 0.01);
uniform float initial_amplitude : hint_range(0.5, 2.0, 0.001);
uniform float amplitude_multiplier : hint_range(0.5, 1.0, 0.01);
uniform float initial_frequency : hint_range(0.1, 0.2, 0.001);
uniform float frequency_multiplier : hint_range(1.0, 2.0, 0.01);

uniform float wind_direction_degrees : hint_range(0, 360, 0.5);
uniform float wind_direction_increment : hint_range(0, 90, 0.5);

uniform int wave_count : hint_range(0, 50, 1);

float phase(float speed, float frequency) {
	return speed * frequency;
}

float wave(vec2 position, vec2 normalized_direction, float frequency, float time, float phase) {
	return dot(normalized_direction, position) * frequency + time * phase;
}

vec2 direction(float degree) {
	float wind_direction = radians(degree);
	return vec2(cos(wind_direction), sin(wind_direction));
}

vec3 sharp_euler_sine_wave(float amplitude, float wave) {
	return vec3(0.0, amplitude * pow(E, max_peak * sin(wave) - peak_offset), 0.0);
}

vec3 sharp_euler_sine_partial_derivative(float frequency, vec2 normalized_direction, float amplitude, float wave) {
	vec2 derivative = frequency * normalized_direction * amplitude * max_peak * pow(E, max_peak * sin(wave) - peak_offset) * cos(wave);
	return vec3(derivative.x, 0.0, derivative.y);
}

void fragment() {
	float fresnel = sqrt(1.0 - dot(NORMAL, VIEW));
	
	RIM = rim;
	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness * (1.0 - fresnel);
}

void vertex() {
	vec3 vertex_accumulator = vec3(0.0);
	vec3 normal_accumulator = vec3(0.0);
	
	float time = TIME;
	vec2 position = VERTEX.xz;
	
	float speed = initial_speed;
	float amplitude = initial_amplitude;
	float frequency = initial_frequency;
	float wind_direction = wind_direction_degrees;
	
	vec3 previous_derivative = vec3(0.0);
	
	for (int i = 0; i < wave_count; i++) {
		vec2 normalized_direction = normalize(direction(wind_direction));
		float phase = phase(speed, frequency);
		float wave = wave(position, normalized_direction, frequency, time, phase);
		
		vec3 wave_state = sharp_euler_sine_wave(amplitude, wave);
		vec3 derivative = sharp_euler_sine_partial_derivative(frequency, normalized_direction, amplitude, wave);
		
		position += normalized_direction * -derivative.xz * amplitude * wave_drag;
		
		speed *= speed_multiplier;
		amplitude *= amplitude_multiplier;
		frequency *= frequency_multiplier;
		wind_direction += wind_direction_increment;
		
		vertex_accumulator += wave_state;
		normal_accumulator += derivative;
	}

	NORMAL = normalize(vec3(-normal_accumulator.x, 1.0 - normal_accumulator.y, -normal_accumulator.z));
	// Local coords vertex y starts in zero so we can do this
	VERTEX += vertex_accumulator;
}
