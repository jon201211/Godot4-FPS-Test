extends HBoxContainer

@onready var m_player_name_label = find_child("PlayerNameLabel")
@onready var m_score_label = find_child("ScoreLabel")
@onready var m_failed_label = find_child("FailedLabel")
@onready var m_state_label = find_child("StateLabel")


func set_row(player_name: String, score: String, failed :String, state: String):
	m_player_name_label.text = player_name
	m_score_label.text = score
	m_failed_label.text = failed
	m_state_label.text = state
