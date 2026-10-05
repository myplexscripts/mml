extends RefCounted
## All persistent progress lives here. Transient combat never enters a save.
const Catalog = preload("res://scripts/catalog.gd")
const SAVE_PATH := "user://kattelox_days_v2.json"
const DEFAULT_ITEMS := {"scrap":0, "seeds":12, "turnips":0, "fish":0, "heal":2, "relic":0, "servo":0, "circuit":0, "refractor":0,"shard":0,"tomato_seeds":0,"sunflower_seeds":0,"tomatoes":0,"sunflowers":0}
var day: int = 1
var minutes: float = 480.0
var zenny: int = 300
var score: int = 0
var best_dig: int = 0
var repair: int = 0
var quest_started: bool = false
var tron_defeated: bool = false
var completed: bool = false
var power: int = 0
var rapid: int = 0
var armour: int = 0
var health: int = 100
var energy: float = 100.0
var items: Dictionary = DEFAULT_ITEMS.duplicate()
var friendship: Dictionary = {"Roll":2,"Data":3,"Barrell":1,"Amelia":0,"Tron":0,"Junk Shop Man":0}
var talked: Dictionary = {}
var crops: Array = []
var claimed: Array = []
var enemies_today: int = 0
var harvested: int = 0
var museum_donated: int = 0
var grenade_unlocked: bool = false
var blueprint: bool = false
var deep_depth: int = 4
var seed_kind: String = "turnip"
var gifts: Dictionary = {}
var music: bool = true
var sound: bool = true
var reduced_motion: bool = false

func _init() -> void:
	for i in range(12):
		crops.append({"tilled":false,"stage":-1,"watered":false,"kind":"turnip"})

func max_health() -> int:
	return 100 + armour * 25

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func to_data() -> Dictionary:
	var data: Dictionary = {"version":2}
	for key in ["day","minutes","zenny","score","best_dig","repair","quest_started","tron_defeated","completed","power","rapid","armour","health","energy","items","friendship","talked","crops","claimed","enemies_today","harvested","museum_donated","music","sound","reduced_motion","grenade_unlocked","blueprint","deep_depth","seed_kind","gifts"]:
		data[key] = get(key)
	return data

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_data()))
	file.close()
	return DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH) == OK

func load_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or int(data.get("version",0)) != 2:
		return false
	for key in to_data():
		if key != "version" and data.has(key) and typeof(data[key]) in [TYPE_INT,TYPE_FLOAT,TYPE_BOOL,TYPE_STRING,TYPE_DICTIONARY,TYPE_ARRAY]:
			if key in ["items","friendship","talked","gifts"] and not data[key] is Dictionary:
				continue
			if key in ["crops","claimed"] and not data[key] is Array:
				continue
			if key not in ["items","friendship","talked","gifts","crops","claimed"] and typeof(data[key]) in [TYPE_ARRAY,TYPE_DICTIONARY]:
				continue
			set(key,data[key])
	if not Catalog.CROPS.has(seed_kind): seed_kind="turnip"
	deep_depth=clampi(deep_depth,4,20)
	day = maxi(1,day)
	minutes = clampf(minutes,360.0,1440.0)
	zenny = maxi(0,zenny)
	repair = clampi(repair,0,3)
	power = clampi(power,0,3)
	rapid = clampi(rapid,0,3)
	armour = clampi(armour,0,3)
	health = clampi(health,1,max_health())
	energy = clampf(energy,0,100)
	for key in DEFAULT_ITEMS:
		items[key] = maxi(0,int(items.get(key,0)))
	if crops.size() != 12:
		crops.clear()
		for i in range(12): crops.append({"tilled":false,"stage":-1,"watered":false,"kind":"turnip"})
	for i in range(crops.size()):
		if not crops[i] is Dictionary: crops[i] = {}
		var kind: String=str(crops[i].get("kind","turnip"))
		if not Catalog.CROPS.has(kind): kind="turnip"
		crops[i] = {"tilled":bool(crops[i].get("tilled",false)),"stage":clampi(int(crops[i].get("stage",-1)),-1,int(Catalog.crop(kind).nights)),"watered":bool(crops[i].get("watered",false)),"kind":kind}
	return true

func next_day() -> Dictionary:
	var grown := 0
	for crop in crops:
		if int(crop.stage) >= 0 and int(crop.stage) < int(Catalog.crop(str(crop.get("kind","turnip"))).nights) and bool(crop.watered):
			crop.stage = int(crop.stage) + 1
			grown += 1
		crop.watered = false
	day += 1
	minutes = 480.0
	health = max_health()
	energy = 100.0
	talked.clear()
	gifts.clear()
	claimed.clear()
	enemies_today = 0
	harvested = 0
	if day % 4 == 0:
		for crop in crops:
			if int(crop.stage) >= 0: crop.watered = true
	return {"grown":grown,"rain":day % 4 == 0}

func greet(person: String) -> void:
	if not talked.has(person):
		talked[person] = true
		friendship[person] = mini(10,int(friendship.get(person,0))+1)
