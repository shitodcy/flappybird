extends CanvasLayer

@onready var mute_button = $VBoxContainer/MuteButton
@onready var bgm_slider = $VBoxContainer/BGMSlider
@onready var sfx_slider = $VBoxContainer/SFXSlider
@onready var close_button = $VBoxContainer/CloseButton

# ID Bus Audio
var master_bus = AudioServer.get_bus_index("Master")
var bgm_bus = AudioServer.get_bus_index("BGM")
var sfx_bus = AudioServer.get_bus_index("SFX")

# Jalur penyimpanan file konfigurasi
const SETTINGS_PATH = "user://settings.cfg"

func _ready():
	# Sambungkan sinyal
	mute_button.toggled.connect(_on_mute_toggled)
	bgm_slider.value_changed.connect(_on_bgm_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	close_button.pressed.connect(_on_close_pressed)
	
	# Muat pengaturan saat game baru dibuka
	load_settings()

# --- FUNGSI SAVE & LOAD ---

func save_settings():
	var config = ConfigFile.new()
	
	# Simpan nilai dari UI ke dalam kategori "audio"
	config.set_value("audio", "mute", mute_button.button_pressed)
	config.set_value("audio", "bgm_volume", bgm_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	
	# Tulis ke file
	config.save(SETTINGS_PATH)

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err == OK:
		# Jika file ditemukan, terapkan nilai ke slider/tombol
		mute_button.button_pressed = config.get_value("audio", "mute", false)
		bgm_slider.value = config.get_value("audio", "bgm_volume", 1.0)
		sfx_slider.value = config.get_value("audio", "sfx_volume", 1.0)
		
		# Terapkan volume tersebut ke mesin suara Godot
		AudioServer.set_bus_mute(master_bus, mute_button.button_pressed)
		AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(bgm_slider.value))
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_slider.value))
	else:
		# Jika belum ada file save (baru pertama main), gunakan default bawaan editor
		bgm_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bgm_bus))
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))

# --- EVENT TOMBOL & SLIDER ---

func _on_mute_toggled(toggled_on: bool):
	AudioServer.set_bus_mute(master_bus, toggled_on)
	save_settings() # Simpan setiap kali ada perubahan

func _on_bgm_changed(value: float):
	AudioServer.set_bus_volume_db(bgm_bus, linear_to_db(value))
	save_settings() # Simpan setiap kali ada perubahan

func _on_sfx_changed(value: float):
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
	save_settings() # Simpan setiap kali ada perubahan

func _on_close_pressed():
	hide()
