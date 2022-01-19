tool
extends Control
class_name AudioSpectrum

enum SmoothMethod { NONE, LINEAR }
enum FFTSize { FFT_256, FFT_512, FFT_1024, FFT_2048, FFT_4096}

export(float, 0, 48000) var MinimumFrequency = 100.0;
export(float, 0, 96000) var MaximumFrequency = 11050.0;

export(float, 1, 200) var Divider = 40.0;
export(float, 1, 10) var Multiplier = 1.2;
export(float, 0, 100) var Speed = 2.4;

export(int, 0, 2048) var Amount = 16 setget _set_amount;
export(SmoothMethod) var SmoothType = SmoothMethod.LINEAR;
export(FFTSize) var FFTSizeType = FFTSize.FFT_2048;
export(float, 1, 30) var FFTBufferSize = 3;

export(float) var MinimumHeight = 2.0 setget _set_bar_height;
export(float) var BarWidth = 20.0 setget _set_bar_width;

export(Color) var BarColor = Color("#b71f78") setget _set_color;

export(int) var targetFps = 30 setget _set_target_fps;
export(int) var targetUps = 90 setget _set_target_ups;


var bars = [];

var spectrum : AudioEffectSpectrumAnalyzerInstance;

func _set_color(var value):
	BarColor = value;
	_update_bars();

func _set_bar_width(var value):
	BarWidth = value;
	_update_bars();

func _set_bar_height(var value):
	MinimumHeight = value;
	_update_bars();

func _set_amount(var value):
	Amount = value;
	_update_bars();

func _set_target_fps(var value):
	targetFps = value;
	Engine.set_target_fps(value);

func _set_target_ups(var value):
	targetUps = value;
	Engine.set_iterations_per_second(value);

func _update_bars():
	bars.resize(Amount);
	var space = (rect_size.x - (Amount * BarWidth)) / (Amount - 1);
	var width = BarWidth;
	var height = 0;
	if Engine.editor_hint:
		height = rect_size.y;
	for i in range(Amount):
		bars[i] = {
			"x": i * (width + space),
			"w": width,
			"h": height
		};

func _ready():
	_update_bars();
	Engine.set_target_fps(targetFps);
	Engine.set_iterations_per_second(targetUps);

func _draw():
	var barx = bars.duplicate();
	for i in range(Amount):
		var bar = barx[i];
		var height = MinimumHeight + bar["h"];
		draw_rect(Rect2(bar["x"], rect_size.y - height, bar["w"], height), BarColor);

func update_spectrum(delta):
	var _spec = get_spectrum();
	if !_spec:
		return;
	var nodeHeight = rect_size.y - MinimumHeight;
	var prev_hz = MinimumFrequency;
	var freq = MaximumFrequency - MinimumFrequency;
	for i in range(1, Amount+1):
		var hz = (i * freq / Amount) + MinimumFrequency;
		var magnitude: float = _spec.get_magnitude_for_frequency_range(prev_hz, hz).length();
		var energy = clamp((Multiplier * Divider + linear2db(magnitude)) / Divider, 0, 1);
		bars[i - 1]["h"] = smooth(bars[i - 1]["h"], (energy * nodeHeight), delta * Speed);
		prev_hz = hz;

func smooth(var prev_height, var height, var delta):
	if prev_height == null:
		prev_height = 0;
	match (SmoothType):
		SmoothMethod.NONE:
			return height;
		SmoothMethod.LINEAR:
			return lerp(prev_height, height, delta);

func get_spectrum():
	if spectrum:
		return spectrum;
	var effect : AudioEffectSpectrumAnalyzer = AudioServer.get_bus_effect(0, 0);
	effect.set_buffer_length(FFTBufferSize);
	effect.set_fft_size(FFTSizeType);
	spectrum = AudioServer.get_bus_effect_instance(0, 0);
	return spectrum;

func _process(_delta):
	update();
	if Engine.editor_hint:
		_set_amount(Amount);

func _physics_process(delta):
	update_spectrum(delta);
