class_name WeaponData
extends RefCounted

const MIN_ATTACK_DAMAGE: int = 2
const MAX_ATTACK_DAMAGE: int = 3
const SILVER_MAX_HITS: int = 10
const GOLD_MAX_HITS: int = 7

var weapon_name: String
var attack_damage: int
var hits_remaining: int


func _init(new_weapon_name: String = "Weapon", new_attack_damage: int = MIN_ATTACK_DAMAGE) -> void:
	weapon_name = new_weapon_name.strip_edges()
	if weapon_name.is_empty():
		weapon_name = "Weapon"
	attack_damage = clampi(new_attack_damage, MIN_ATTACK_DAMAGE, MAX_ATTACK_DAMAGE)
	hits_remaining = get_max_hits()


func get_max_hits() -> int:
	return GOLD_MAX_HITS if attack_damage == MAX_ATTACK_DAMAGE else SILVER_MAX_HITS


func use_hit() -> bool:
	if hits_remaining <= 0:
		return true
	hits_remaining -= 1
	return hits_remaining <= 0


func duplicate_with_durability() -> WeaponData:
	var weapon_copy: WeaponData = WeaponData.new(weapon_name, attack_damage)
	weapon_copy.hits_remaining = hits_remaining
	return weapon_copy


func is_broken() -> bool:
	return hits_remaining <= 0


func get_material_name() -> String:
	return "gold" if attack_damage == MAX_ATTACK_DAMAGE else "silver"
