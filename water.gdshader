shader_type spatial;

const int MAX_WAVE_COUNT = 4;

const int WAVE_TYPE_SINE = 0;
const int WAVE_TYPE_SHARPER_SINE = 1;
const int WAVE_TYPE_GERSTNER = 2;

uniform vec3 albedo: source_color;

uniform float exponent : hint_range(1.0, 4.0, 0.25);
uniform float speeds[MAX_WAVE_COUNT];
uniform float amplitudes[MAX_WAVE_COUNT];
uniform float wavelengths[MAX_WAVE_COUNT];
uniform float steepnesses[MAX_WAVE_COUNT];

uniform int wave_type : hint_range(0, 2, 1) = 0;
uniform int wind_directions[MAX_WAVE_COUNT];

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
	return dot(normalized_direction, vec2(position.x, position.y)) * frequency + time * phase;
}

// Sine
vec3 sine_wave_state(float amplitude, float wave) {
	return vec3(0.0, amplitude * sin(wave), 0.0);
}

vec2 partial_derivative(float frequency, vec2 normalized_direction, float amplitude, float wave) {
	return frequency * normalized_direction * amplitude * cos(wave);
}

// Sharper Sine
vec3 sharper_sine_wave_state(float amplitude, float wave) {
	return vec3(0.0, 2.0 * amplitude * pow((sin(wave) + 1.0) / 2.0, exponent), 0.0);
}

vec2 sharper_sine_partial_derivative(float frequency, vec2 normalized_direction, float amplitude, float wave) {
	vec2 partial = exponent * normalized_direction * frequency * amplitude;
	float second_partial = pow((sin(wave) + 1.0) / 2.0, exponent - 1.0);
	return frequency * normalized_direction * amplitude * second_partial * cos(wave);
}

// Gerstner
vec3 gerstner_wave_state(vec2 normalized_direction, float amplitude, float steepness, float wave) {
	vec2 position = steepness * amplitude * normalized_direction * cos(wave);
	float displacement = amplitude * sin(wave);
	return vec3(position.x, displacement, position.y);
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
		float wind_direction = radians(float(wind_directions[i]));
		vec2 direction = vec2(cos(wind_direction), sin(wind_direction));
		vec2 normalized_direction = normalize(direction);
		float frequency = frequency(wavelengths[i]);
		float phase = phase(speeds[i], wavelengths[i]);
		
		vec3 wave_state = vec3(0.0);
		vec2 derivative = vec2(0.0);
		
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
				break;
		}
		vertex_accumulator += wave_state;
		normal_accumulator += vec3(derivative.x, derivative.y, 0);
	}

	NORMAL = normalize(vec3(-normal_accumulator.x, 1.0, -normal_accumulator.y));
	// Local coords vertex y starts in zero so we can do this
	VERTEX += vertex_accumulator;
}

