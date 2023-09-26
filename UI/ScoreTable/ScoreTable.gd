extends PopupPanel

const MAX_SCORES_TO_SHOW = 20
#const SCORES_FILENAME = "res://scores.txt"

signal POPUP_SCORE_CLOSE

@onready var m_background = find_child("Background")
@onready var m_scores_vbox = find_child("ScoresVBox")
@onready var m_first_table_row = find_child("FirstTableRow")
@onready var m_no_scores_label = find_child("NoScoresLabel")


@onready var m_game = get_parent()
@onready var m_table_row_scene = preload("res://UI/ScoreTable/TableRow.tscn")


func _ready():
	#m_background.color = GameSettings.MENU_BACKGROUND_COLOR
	m_no_scores_label.set_text(tr("NO-SCORES"))
	m_first_table_row.set_row(tr("NAME"), tr("SCORE"),  tr("FAIL"), tr("STATE"))


	m_no_scores_label.visible = false

	var world = get_parent().get_node("Level").get_child(0)
	var playerList = {}
	if world != null:
		print("world valid")
		playerList = world.playerList

	# String array with the struct: [player_name, score, date].
	#var scores = Array()

	# Read each CSV score into memory.
	#var file = FileAccess.open(SCORES_FILENAME, FileAccess.READ)
	#var new_line = file.get_csv_line()
	#while new_line.size() > 1:
	#	scores.push_back(new_line)
	#	new_line = file.get_csv_line()
	#file.close()

	if playerList.is_empty():
		m_no_scores_label.visible = true
	else:
		# Take the scores into scene.
		for i in playerList:
			var player = playerList[i]
			var new_table_row = m_table_row_scene.instantiate()
			m_scores_vbox.add_child(new_table_row)
			new_table_row.set_row( player.peer_name, str(player.ShootCount),str(player.Deadcount),str(player.Health))

	Logger.log_debug("ScoreTable: Ready")


func _unhandled_input(event):

	if event.is_action_released("show_billboard"):
		#print("TAB release")
		emit_signal("POPUP_SCORE_CLOSE")

