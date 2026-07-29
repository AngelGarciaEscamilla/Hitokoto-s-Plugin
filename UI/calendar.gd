class_name Calendar extends Node

@export_range(1,31,1) var day : int 
@export var year : int = 1
@export var last_leap_year : int = 1
@export_enum("Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday") var day_of_the_week : String = "Monday"
@export_enum("January","February","March","April","May","June","July","August","September","October","November","December") var month : String = "January"

func _ready():
	Hitokoto.save(self)
	await update_calendar()
	queue_free()

func update_calendar() -> void:
	var calendar : Dictionary = {
	"time_passed":0,
	"day":day,
	"day_of_the_week":GameTime.Week[day_of_the_week.to_upper()],
	"month":GameTime.Month[month.to_upper()],
	"year":year,
	"last_leap_year":last_leap_year,}
	GameTime.calendar = calendar
