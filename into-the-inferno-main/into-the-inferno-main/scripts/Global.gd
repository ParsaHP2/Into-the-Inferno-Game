extends Node

signal dialogue_Finished

const BOSS_MAX_HEALTH = 3000

var in_dialogue: bool = false
var entered_hub: bool = false
var selected_upgrade: int = -1
var num_upgrades_unlocked: int = 0
var bonus_monster_damage: int = 0
var max_score: int = 0 # Set when level is started
var current_score: int = 0 # Increased every time player kills enemies, fills based on thermometer amount

var scrolls_collected: Dictionary = {
	"Right": false,
	"Left": false,
	"Up": false,
}
var upgrades: Array[Dictionary] = [
	{"name": "Big", "unlocked": false},
	{"name": "Multi", "unlocked": false},
	{"name": "Beams", "unlocked": false},
]
