shader_type spatial;

const int MAX_WAVE_COUNT = 4;

uniform vec3 albedo: source_color;

uniform float exponent : hint_range(1.0, 4.0, 0.25);
uniform float speeds[MAX_WAVE_COUNT];
uniform float amplitudes[MAX_WAVE_COUNT];
uniform float wavelengths[MAX_WAVE_COUNT];

uniform int wind_directions[MAX_WAVE_COUNT];

float frequency(float wavelength) {
	return 2.0 / wavelength;
}

float phase(float speed, float wavelength) {
	return speed * 2.0 / wavelength;
}

float sine_wave_state(vec2 position, float time, float amplitude, float frequency, vec2 normalized_direction, float phase) {
	float wave = dot(normalized_direction, vec2(position.x, position.y)) * frequency + time * phase;
	return amplitude * sin(wave);
}

float sharper_sine_wave_state(vec2 position, float time, float amplitude, float frequency, vec2 normalized_direction, float phase) {
	float wave = dot(normalized_direction, vec2(position.x, position.y)) * frequency + time * phase;
	return 2.0 * amplitude * pow((sin(wave) + 1.0) / 2.0, exponent);
}

vec2 partial_derivative(vec2 position, float time, float frequency, vec2 normalized_direction, float amplitude, float phase) {
	float wave = dot(normalized_direction, vec2(position.x, position.y)) * frequency + time * phase;
	return frequency * normalized_direction * amplitude * cos(wave);
}

vec2 sharper_partial_derivative(vec2 position, float time, float frequency, vec2 normalized_direction, float amplitude, float phase) {
	vec2 partial = exponent * normalized_direction * frequency * amplitude;
	float wave = dot(normalized_direction, vec2(position.x, position.y)) * frequency + time * phase;
	float second_partial = pow((sin(wave) + 1.0) / 2.0, exponent - 1.0);
	return frequency * normalized_direction * amplitude * second_partial * cos(wave);
}

void fragment() {
	ALBEDO = albedo;
}

void vertex() {
	float vertex_y_accumulator = 0.0;
	vec3 normal_accumulator = vec3(0.0);
	
	float time = TIME;
	vec2 position = VERTEX.xz;

	for (int i = 0; i < MAX_WAVE_COUNT; i++) {
		float wind_direction = radians(float(wind_directions[i]));
		vec2 direction = vec2(cos(wind_direction), sin(wind_direction));
		vec2 normalized_direction = normalize(direction);
		float frequency = frequency(wavelengths[i]);
		float phase = phase(speeds[i], wavelengths[i]);
		float sine_wave_state = sharper_sine_wave_state(position, time, amplitudes[i], frequency, normalized_direction, phase);
		vec2 partial_derivative = sharper_partial_derivative(position, time, frequency, normalized_direction, amplitudes[i], phase);
		vertex_y_accumulator += sine_wave_state;
		normal_accumulator += vec3(partial_derivative.x, partial_derivative.y, 0);
	}

	NORMAL = normalize(vec3(-normal_accumulator.x, 1.0, -normal_accumulator.y));
	VERTEX.y = vertex_y_accumulator;
}

