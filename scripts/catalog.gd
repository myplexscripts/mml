extends RefCounted
## Shared crop rules keep shop descriptions, growth and shipping in agreement.
const CROPS := {
	"turnip":{"name":"Turnip","seed":"seeds","item":"turnips","nights":3,"price":80,"regrow":-1},
	"tomato":{"name":"Tomato","seed":"tomato_seeds","item":"tomatoes","nights":4,"price":65,"regrow":2},
	"sunflower":{"name":"Sunflower","seed":"sunflower_seeds","item":"sunflowers","nights":5,"price":160,"regrow":-1}
}
const GIFTS := {"Roll":"tomatoes","Data":"turnips","Barrell":"fish","Amelia":"sunflowers","Tron":"sunflowers","Junk Shop Man":"scrap"}

static func crop(kind: String) -> Dictionary:
	return CROPS.get(kind,CROPS.turnip)

static func visual_stage(data: Dictionary) -> int:
	var nights: int=crop(str(data.get("kind","turnip"))).nights
	return 3 if int(data.stage)>=nights else mini(2,int(float(data.stage)*3/nights))
