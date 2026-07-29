@tool
class_name DynamicMusic extends Component

var music_node : AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(music_node)

func play_music(music_:AudioStream,volume:float = 80.0,i:float = 1.0) -> void:
	if !music_:return
	music_node.stream = music_
	if "loop" in music_node.stream:
		music_node.stream.loop = true
	music_node.volume_db = -80.0
	var tween := create_tween()
	music_node.play()
	tween.tween_property(music_node,"volume_db",volume,i)

func stop_music() -> void:
	var tween := create_tween()
	tween.tween_property(music_node,"volume_db",-80.0,1.0)
	tween.tween_callback(music_node.stop)
