extends Button

@onready var m_button_sound = load("res://Assets/SFX/button.ogg")


# Sets wrapper up.
func _ready():
	self.connect("pressed", on_pressed)
	self.connect("mouse_entered", on_focused)


# Button pression handler.
func on_pressed():
	SfxManager.play_sfx(m_button_sound)
	
func on_focused():
	SfxManager.play_sfx(m_button_sound)
