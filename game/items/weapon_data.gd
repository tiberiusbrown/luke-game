class_name WeaponData
extends RefCounted

const MIN_ATTACK_DAMAGE: int = 2
const MAX_ATTACK_DAMAGE: int = 3

var weapon_name: String
var attack_damage: int


func _init(new_weapon_name: String = "Weapon", new_attack_damage: int = MIN_ATTACK_DAMAGE) -> void:
	weapon_name = new_weapon_name.strip_edges()
	if weapon_name.is_empty():
		weapon_name = "Weapon"
	attack_damage = clampi(new_attack_damage, MIN_ATTACK_DAMAGE, MAX_ATTACK_DAMAGE)
