shader_type spatial;

const int MAX_WAVE_COUNT = 4;

const int WAVE_TYPE_SINE = 0;
const int WAVE_TYPE_SHARPER_SINE = 1;
const int WAVE_TYPE_GERSTNER = 2;

uniform vec3 albedo: source_color;

uniform float specular_size;
uniform float specular_intensity : hint_range(0.0, 2.0, 0.01);
uniform float exponent : hint_range(1.0, 4.0, 0.25);
uniform float speeds[MAX_WAVE_COUNT];
uniform float amplitudes[MAX_WAVE_COUNT];
uniform float wavelengths[MAX_WAVE_COUNT];
uniform float steepnesses[MAX_WAVE_COUNT];

uniform int wave_type : hint_range(0, 2, 1) = 0;
uniform int wind_directions[MAX_WAVE_COUNT];

varying vec3 normal;

float frequency(float wavelength) {
	return 2.0 / wavelength;
}

float phase(float speed, float wavelength) {
	return speed * 2.0 / wavelength;
}

float steepness(float base_stepness, float frequency, float amplitude) {
	return base_stepness / frequency * amplitude;
}

float wave(vec2 position, vec2 normalized_direction, float frequency, float time, float phase) {
	return dot(normalized_direction, position) * frequency + time * phase;
}

vec2 normalized_direction(float degree) {
	float wind_direction = radians(degree);
	vec2 direction = vec2(cos(wind_direction), sin(wind_direction));
	return normalize(direction);
}

// Sine
vec3 sine_wave_state(float amplitude, float wave) {
	return vec3(0.0, amplitude * sin(wave), 0.0);
}

vec3 partial_derivative(float frequency, vec2 normalized_direction, float amplitude, float wave) {
	vec2 derivative = frequency * normalized_direction * amplitude * cos(wave);
	return vec3(derivative.x, 0.0, derivative.y);
}

// Sharper Sine
vec3 sharper_sine_wave_state(float amplitude, float wave) {
	return vec3(0.0, 2.0 * amplitude * pow((sin(wave) + 1.0) / 2.0, exponent), 0.0);
}

vec3 sharper_sine_partial_derivative(float frequency, vec2 normalized_direction, float amplitude, float wave) {
	vec2 partial = exponent * normalized_direction * frequency * amplitude;
	float second_partial = pow((sin(wave) + 1.0) / 2.0, exponent - 1.0);
	vec2 derivative = frequency * normalized_direction * amplitude * second_partial * cos(wave);
	return vec3(derivative.x, 0.0, derivative.y);
}

// Gerstner
vec3 gerstner_wave_state(vec2 normalized_direction, float amplitude, float steepness, float wave) {
	vec2 position = steepness * amplitude * normalized_direction * cos(wave);
	float displacement = amplitude * sin(wave);
	return vec3(position.x, displacement, position.y);
}

vec3 gerstner_partial_derivative(vec2 normalized_direction, float amplitude, float steepness, float frequency, float wave) {
	vec2 derivative = frequency * normalized_direction * amplitude * cos(wave);
	float displacement = steepness * frequency * amplitude * sin(wave);
	return vec3(derivative.x, displacement, derivative.y);
}

void light() {
	vec3 halfway = normalize(LIGHT + VIEW);
	float clamped_direction = clamp(dot(halfway, NORMAL), 0.0, 1.0);
	SPECULAR_LIGHT = ALBEDO + LIGHT_COLOR * pow(clamped_direction * specular_intensity, specular_size);
}

void fragment() {
	ALBEDO = albedo;
}

void vertex() {
	vec3 vertex_accumulator = vec3(0.0);
	vec3 normal_accumulator = vec3(0.0);
	
	float time = TIME;
	vec2 position = VERTEX.xz;

	for (int i = 0; i < MAX_WAVE_COUNT; i++) {
		float frequency = frequency(wavelengths[i]);
		float phase = phase(speeds[i], wavelengths[i]);
		vec2 normalized_direction = normalized_direction(float(wind_directions[i]));
		
		vec3 wave_state = vec3(0.0);
		vec3 derivative = vec3(0.0);
		
		float wave = wave(position, normalized_direction, frequency, time, phase);
		
		switch(wave_type) {
			case WAVE_TYPE_SINE:
				wave_state = sine_wave_state(amplitudes[i], wave);
				derivative = partial_derivative(frequency, normalized_direction, amplitudes[i], wave);
				break;
			case WAVE_TYPE_SHARPER_SINE: 
				wave_state = sharper_sine_wave_state(amplitudes[i], wave);
				derivative = sharper_sine_partial_derivative(frequency, normalized_direction, amplitudes[i], wave);
				break;
			case WAVE_TYPE_GERSTNER: 
				float steepness = steepness(steepnesses[i], frequency, amplitudes[i]);
				wave_state = gerstner_wave_state(normalized_direction, amplitudes[i], steepness, wave);
				derivative = gerstner_partial_derivative(normalized_direction, amplitudes[i], steepness, frequency, wave);
				break;
		}
		vertex_accumulator += wave_state;
		normal_accumulator += derivative;
	}

	NORMAL = normalize(vec3(-normal_accumulator.x, 1.0 - normal_accumulator.y, -normal_accumulator.z));
	// Local coords vertex y starts in zero so we can do this
	VERTEX += vertex_accumulator;
	
	normal = NORMAL;
}

