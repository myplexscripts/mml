extends RefCounted
const SAVE_PATH := "user://flutterbound_v1.json"
var camera_zoom: float=1.0
var health: int=100
var energy: float=100.0
var zenny: int=250
var scrap: int=0
var shards: int=0
var bottles: int=3
var score: int=0
var best_run: int=0
var repair: int=0
var parts: Array=[]
var quest_started: bool=false
var tron_defeated: bool=false
var completed: bool=false
var power: int=0
var rapid: int=0
var armour: int=0
var grenade: bool=false
var weapon_plans: bool=false
var relics: int=0
var claimed: Array=[]
var deepest: int=4
var music: bool=true
var sound: bool=true
var reduced_motion: bool=false

func max_health() -> int: return 100+armour*25
func save_exists() -> bool: return FileAccess.file_exists(SAVE_PATH)
func to_data() -> Dictionary:
 var data: Dictionary={"version":1}
 for key in ["camera_zoom","health","energy","zenny","scrap","shards","bottles","score","best_run","repair","parts","quest_started","tron_defeated","completed","power","rapid","armour","grenade","weapon_plans","relics","claimed","deepest","music","sound","reduced_motion"]:data[key]=get(key)
 return data
func save_game() -> bool:
 var file:=FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
 if not file:return false
 file.store_string(JSON.stringify(to_data()));file.close()
 return DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)==OK
func load_game() -> bool:
 var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
 if not file:return false
 var data=JSON.parse_string(file.get_as_text())
 if not data is Dictionary or int(data.get("version",0))!=1:return false
 for key in to_data():
  if key=="version" or not data.has(key):continue
  var current=get(key)
  if current is Array:
   if data[key] is Array:set(key,data[key])
  elif typeof(current)==TYPE_BOOL:
   if typeof(data[key])==TYPE_BOOL:set(key,data[key])
  elif typeof(data[key]) in [TYPE_INT,TYPE_FLOAT]:set(key,data[key])
 camera_zoom=clampf(camera_zoom,.8,1.6)
 repair=clampi(repair,0,3);power=clampi(power,0,3);rapid=clampi(rapid,0,3);armour=clampi(armour,0,3)
 health=clampi(health,1,max_health());energy=clampf(energy,0,100);zenny=maxi(0,zenny);scrap=maxi(0,scrap);shards=maxi(0,shards);bottles=maxi(0,bottles);deepest=clampi(deepest,4,15)
 return true
