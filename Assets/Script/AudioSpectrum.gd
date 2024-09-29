@tool
extends Control
class_name AudioSpectrum

enum SmoothMethod { NONE, LINEAR }
enum FFTSize { FFT_256, FFT_512, FFT_1024, FFT_2048, FFT_4096 }

@export var MinimumFrequency = 100.0; # (float, 0, 48000)
@export var MaximumFrequency = 11050.0; # (float, 0, 96000)

@export var LegacyDivider = 40.0; # (float, 1, 200)
@export var LegacyMultiplier = 1.2; # (float, 1, 10)
@export var SmoothSpeed = 2.4; # (float, 0, 100)

@export var Smoothing: bool = false;
@export var SmoothingScale = 0.60; # (float, 0, 1)
@export var Decibil: bool = false: set = _set_decibil

@export var Amount = 16: set = _set_amount
@export var SmoothType: SmoothMethod = SmoothMethod.LINEAR;
@export var FFTSizeType: FFTSize = FFTSize.FFT_2048;
@export var FFTBufferSize = 3.0; # (float, 1, 30)

@export var MinimumHeight: float = 2.0: set = _set_bar_height
@export var BarWidth: float = 20.0: set = _set_bar_width

@export var BarColor: Color = Color("#b71f78"): set = _set_color

@export var targetFps: int = 30: set = _set_target_fps
@export var targetUps: int = 90: set = _set_target_ups

@export var legacy: bool = false;

@export var debug: bool = false: set = _set_debug
@export var debug_path: String = "/root/Root/Debug": set = _set_debug_path

var reset = true;
var min_mag = 0;
var max_mag = 0;

var range_label : Label;
var min_label : Label;
var max_label : Label;
var bar_label : Label;

var bars = [];

var spectrum : AudioEffectSpectrumAnalyzerInstance;

func _set_decibil(value):
	Decibil = value;
	reset = true;

func _set_debug(value):
	debug = value;
	if(!value):
		return;
	_find_labels();

func _set_debug_path(value):
	debug_path = value;
	if(!debug):
		return;
	_find_labels();

func _find_labels():
	var node = get_node_or_null(debug_path);
	if !node:
		return;
	range_label = node.get_node_or_null("Container/Range");
	min_label = node.get_node_or_null("Container/Min");
	max_label = node.get_node_or_null("Container/Max");
	bar_label = node.get_node_or_null("Container/Bar");

func _set_color(value):
	BarColor = value;

func _set_bar_width(value):
	BarWidth = value;
	_update_bars();

func _set_bar_height(value):
	MinimumHeight = value;
	_update_bars();

func _set_amount(value):
	Amount = value;
	_update_bars();

func _set_target_fps(value):
	targetFps = value;
	Engine.set_max_fps(value);

func _set_target_ups(value):
	targetUps = value;
	Engine.set_physics_ticks_per_second(value);
	
func _reset_magnitude():
	min_mag = 0;
	max_mag = 0;

func _update_bars():
	bars.resize(Amount);
	var space = (size.x - (Amount * BarWidth)) / (Amount - 1);
	var width = BarWidth;
	var height = 0;
	if Engine.is_editor_hint():
		height = size.y;
	for i in range(Amount):
		bars[i] = {
			"x": i * (width + space),
			"w": width,
			"h": height,
			"m": 1.0
		};

func _ready():
	_update_bars();
	Engine.set_max_fps(targetFps);
	Engine.set_physics_ticks_per_second(targetUps);

func _draw():
	var barx = bars.duplicate();
	for i in range(Amount):
		var bar = barx[i];
		var height = MinimumHeight + bar["h"];
		draw_rect(Rect2(bar["x"], size.y - height, bar["w"], height), BarColor);
		
func legacy_update_spectrum(delta):
	var _spec = get_spectrum();
	if !_spec:
		return;
	var nodeHeight = size.y - MinimumHeight;
	var prev_hz = MinimumFrequency;
	var freq = MaximumFrequency - MinimumFrequency;
	for i in range(1, Amount+1):
		var hz = (i * freq / Amount) + MinimumFrequency;
		var magnitude: float = _spec.get_magnitude_for_frequency_range(prev_hz, hz).length();
		var energy = clamp((LegacyMultiplier * LegacyDivider + linear_to_db(magnitude)) / LegacyDivider, 0, 1);
		bars[i - 1]["h"] = smooth(bars[i - 1]["h"], (energy * nodeHeight), delta * SmoothSpeed);
		bars[i - 1]["m"] = magnitude;
		prev_hz = hz;

func smooth(prev_height, height, delta):
	if prev_height == null:
		prev_height = 0;
	match (SmoothType):
		SmoothMethod.NONE:
			return height;
		SmoothMethod.LINEAR:
			return lerpf(prev_height, height, delta);

func update_spectrum(_delta):
	var _spec = get_spectrum();
	if !_spec:
		return;
	var tmp_reset = reset;
	if tmp_reset:
		min_mag = 0;
		max_mag = 0;
		reset = false;
	var nodeHeight = size.y - MinimumHeight;
	var prev_hz = MinimumFrequency;
	var freq = MaximumFrequency - MinimumFrequency;
	if is_inf(min_mag):
		min_mag = 0;
	if is_inf(max_mag):
		max_mag = 0;
	var mag_count = 0;
	for i in range(1, Amount+1):
		var hz = (i * freq / Amount) + MinimumFrequency;
		var magnitude : float = _spec.get_magnitude_for_frequency_range(prev_hz, hz).length();
		if(tmp_reset):
			bars[i - 1]["m"] = 0;
		if (Decibil):
			magnitude = linear_to_db(magnitude);
		if (Smoothing):
			magnitude = SmoothingScale * bars[i - 1]["m"] + ((1 - SmoothingScale) * magnitude);
		if is_inf(magnitude):
			magnitude = 0;
		bars[i - 1]["m"] = magnitude;
		if min_mag > magnitude:
			min_mag = magnitude;
		if max_mag < magnitude:
			max_mag = magnitude;
		if(abs(magnitude) <= abs(min_mag / 8)):
			mag_count += 1;
		prev_hz = hz;
	var range_mag = max_mag - min_mag;
	if is_inf(range_mag):
		range_mag = 0;
	var scale_mag = range_mag;
	if(scale_mag == 0):
		scale_mag = 0.00001;
	
	if(mag_count == Amount && Decibil):
		for i in range(0, Amount):
			bars[i]["m"] = 0;
			bars[i]["h"] = smooth(bars[i]["h"], 0, _delta * SmoothSpeed);
	else:
		for i in range(0, Amount):
			bars[i]["h"] = nodeHeight * max(((bars[i]["m"] - min_mag) / scale_mag), 0);
		
	if (debug):
		if (bar_label):
			var ranged = 0;
			if(range_mag != 0):
				ranged = (bars[0]["m"] - min_mag) / range_mag;
			bar_label.text = "Bar: " + str(bars[0]["m"]) + " / " + str(bars[0]["m"] - min_mag) + " / " + str((bars[0]["m"] - min_mag) / scale_mag) + " / " + str(ranged);
		if (range_label):
			range_label.text = "Range: (" + str(mag_count) + ") " + str(range_mag);
		if (min_label):
			min_label.text = "Min: " + str(min_mag);
		if (max_label):
			max_label.text = "Max: " + str(max_mag);

func get_spectrum():
	if spectrum:
		return spectrum;
	var effect : AudioEffectSpectrumAnalyzer = AudioServer.get_bus_effect(0, 0);
	effect.set_buffer_length(FFTBufferSize);
	match(FFTSizeType):
		FFTSize.FFT_256:
			effect.set_fft_size(AudioEffectSpectrumAnalyzer.FFT_SIZE_256);
		FFTSize.FFT_512:
			effect.set_fft_size(AudioEffectSpectrumAnalyzer.FFT_SIZE_512);
		FFTSize.FFT_1024:
			effect.set_fft_size(AudioEffectSpectrumAnalyzer.FFT_SIZE_1024);
		FFTSize.FFT_2048:
			effect.set_fft_size(AudioEffectSpectrumAnalyzer.FFT_SIZE_2048);
		FFTSize.FFT_4096:
			effect.set_fft_size(AudioEffectSpectrumAnalyzer.FFT_SIZE_4096);
	spectrum = AudioServer.get_bus_effect_instance(0, 0);
	return spectrum;

func _process(_delta):
	queue_redraw();
	if Engine.is_editor_hint():
		_set_amount(Amount);

func _physics_process(delta):
	if legacy:
		legacy_update_spectrum(delta);
		return;
	update_spectrum(delta);
