@tool
extends Node

var timer : Timer = Timer.new()

enum Weather {CLEAR,PARTLY_CLOUD,CLOUDY,DRIZZLE,RAIN,THUNDERSTORM,MIST,TORNADO,CYCLONE,SANDSTORM,ASHFALL}
var current_weather : Weather = Weather.CLEAR

enum Month {JANUARY=1,FEBRUARY=2,MARCH=3,APRIL=4,MAY=5,JUNE=6,JULY=7,AUGUST=8,SEPTEMBER=9,OCTOBER=10,NOVEMBER=11,DECEMBER=12}
enum Week {MONDAY=1,TUESDAY=2,WEDNESDAY=3,THURSDAY=4,FRIDAY=5,SATURDAY=6,SUNDAY=7}
var months_days : Array = [0,31,28,31,30,31,30,31,31,30,31,30,31]

@export var calendar : Dictionary = {
	"time_passed" : 0,
	"day":1,
	"day_of_the_week":Week.MONDAY,
	"month":Month.JANUARY,
	"year":1,
	"last_leap_year":1,}:
		get:
			calendar["day_of_the_week"] = wrap(calendar["day_of_the_week"],0,8)
			if calendar["day"] > months_days[calendar["month"]]:
				calendar["month"] += 1
				calendar["day"] = 1
			if calendar["month"] > 12:
				calendar["month"] = Month.JANUARY
				calendar["year"] += 1
			return calendar

enum {
	SUNRISE = 0600,
	SUNSET = 1700,
	MIDNIGHT = 0000,
	NOON = 1200,
}

var time_tween: Tween

signal on_minute_tick
signal in_pause_game(value:bool)

func _ready() -> void:
	add_child(timer)
	timer.timeout.connect(set_time_passed)

func start_playtime_counter() -> void:
	timer.start()

func stop_playtime_counter() -> void:
	timer.stop()

func set_time_passed() -> void:
	calendar["time_passed"] += 1

func pause_game(value:bool) -> void:
	emit_signal("in_pause_game",value)
	get_tree().paused = value

func print_time() -> void:
	print(get_time_string())

func get_time_string() -> String:
	var minutes : String = str(get_minutes())
	var hours : String = str(get_hours())
	if get_minutes() < 10:
		minutes = "0"+minutes
	if get_hours() < 10:
		hours = "0"+str(get_hours())
	if get_minutes() > 59:
		minutes = "00"
		if get_hours() < 10:
			hours = "0"+str(get_hours()+1)
		else:
			hours = str(get_hours()+1)
	var time : String = hours+":"+minutes
	return time

func get_sun() -> Node3D:
	return get_tree().get_first_node_in_group("sun")

func set_time(new_hours:int, new_minute:float,pass_day:bool=true) -> void:
	var sun := get_sun()
	if !sun:
		return
	var prev_time = get_time()
	var total_time: float = new_hours * 60.0 + new_minute
	var total_rotation: float = deg_to_rad(total_time / 4.0)
	var from := sun.rotation.x
	time_tween = create_tween()
	time_tween.tween_method(
		func(weight: float):
			sun.rotation.x = lerp_angle(from, total_rotation, weight),
		0.0,
		1.0,
		sun.waiting_time
	)
	await time_tween.finished
	if pass_day:
		if get_time() < prev_time:
			next_day()
	emit_signal("on_minute_tick")

func get_hours() -> int:
	var sun := get_sun()
	if !sun:
		return 0
	var angle := wrapf(sun.rotation_degrees.x, -180.0, 180.0)
	var total_minutes := int(round(angle * 4.0))
	if total_minutes < 0:
		total_minutes += 24 * 60
	return total_minutes / 60

func get_minutes() -> int:
	var sun := get_sun()
	if !sun:
		return 0
	var angle := wrapf(sun.rotation_degrees.x, -180.0, 180.0)
	var total_minutes := int(round(angle * 4.0))
	if total_minutes < 0:
		total_minutes += 24 * 60
	return total_minutes % 60


static func round_number(x) -> float:
	var xround = round(x * 1000) / 1000.0
	return xround

func next_day() -> void:
	calendar["day"] += 1
	calendar["day_of_the_week"]+= 1

func set_day_leap_february() -> void:
	if leap_year_day():
		months_days[2] = 29
	else:
		months_days[2] = 28

func convert_time(time:int) -> int:
	var hours = time/60
	var minutes = time % 60
	return int(str(hours)+str(minutes))

func is_time_between(start_hour:int, start_min:int, end_hour:int, end_min:int) -> bool:
	var after_start = GameTime.is_time_greater(start_hour, start_min)
	var before_end  = GameTime.is_time_less(end_hour, end_min)
	if !get_sun():
		return false
	if start_hour < end_hour || (start_hour == end_hour && start_min < end_min):
		return after_start && before_end
	else:
		return after_start || before_end

func is_time_greater(hour:int,minute:int) -> bool:
	return get_time() > time(hour,minute)

func is_time_less(hour:int,minute:int) -> bool:
	return get_time() < time(hour,minute)

func is_time(hour:int,minute:int) -> bool:
	return time(hour,minute) == get_time()

##########################################################################################################################
#GETTER
##########################################################################################################################

func get_time_passed() -> Vector2i:
	var hours = calendar["time_passed"] / 3600
	var minutes = (calendar["time_passed"] % 3600) / 60  
	return Vector2i(int(hours),int(minutes))

func get_time() -> int:
	return int(get_time_string().replace(":",""))

func time(hours:int,minutes:int) -> int:
	var minute : String = str(minutes)
	var hour : String = str(hours)
	var time : String = hour+minute
	if minutes <= 0:
		time = time+"0"
	return int(time)

func get_hour_hand_rotate() -> float:
	var hour = get_hours()
	var hand_hour = get_hours() % 12
	return -abs(hand_hour *30)

func get_minute_hand_rotate() -> float:
	return -abs(get_minutes() * 6)

func get_year() -> Month:
	return calendar["year"]

func get_month() -> Month:
	return calendar["month"]

func get_month_days() -> int:
	return months_days[calendar["month"]]

func get_day_of_the_week() -> int:
	return calendar["day_of_the_week"]

func get_day() -> int:
	return calendar["day"]

func leap_year_day() -> bool:
	if calendar["last_leap_year"] == calendar["year"]:
		return true
	var years_to_last_leap : int = abs(calendar["last_leap_year"] - calendar["year"])
	if years_to_last_leap % 4 == 0:
		return true
	return false


##########################################################################################################################
#PROCESS
##########################################################################################################################

func _process(delta:float) -> void:
	set_day_leap_february()
