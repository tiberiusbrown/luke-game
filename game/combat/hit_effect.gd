class_name HitEffect
extends Node2D

const DURATION: float = 0.32
const PARTICLE_AMOUNT_MIN: int = 10
const PARTICLE_AMOUNT_MAX: int = 20
const PARTICLE_LIFETIME: float = 0.24
const PARTICLE_COLOR: Color = Color("#e5484d")
const PARTICLE_TEXTURE: Texture2D = preload("res://game/combat/hit_particle.svg")
const EFFECT_Z_INDEX: int = 3

var damage_hearts: int = 1
var effect_color: Color = Color("#f2c879")
var particle_amount: int = 0

var _particles: CPUParticles2D = null
var _age: float = 0.0


func setup(new_damage_hearts: int, new_color: Color) -> void:
	damage_hearts = maxi(new_damage_hearts, 1)
	effect_color = new_color
	particle_amount = particle_amount_for_damage(damage_hearts)
	queue_redraw()


static func particle_amount_for_damage(new_damage_hearts: int) -> int:
	var safe_damage: int = maxi(new_damage_hearts, 1)
	return clampi(PARTICLE_AMOUNT_MIN + (safe_damage - 1) * 5, PARTICLE_AMOUNT_MIN, PARTICLE_AMOUNT_MAX)


func _ready() -> void:
	z_index = EFFECT_Z_INDEX
	_particles = CPUParticles2D.new()
	_particles.amount = particle_amount if particle_amount > 0 else particle_amount_for_damage(damage_hearts)
	_particles.texture = PARTICLE_TEXTURE
	_particles.lifetime = PARTICLE_LIFETIME
	_particles.one_shot = true
	_particles.explosiveness = 1.0
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	_particles.direction = Vector2.RIGHT
	_particles.spread = 180.0
	_particles.randomness = 1.0
	_particles.initial_velocity_min = 42.0
	_particles.initial_velocity_max = 72.0
	_particles.gravity = Vector2(0.0, 96.0)
	_particles.scale_amount_min = 0.55
	_particles.scale_amount_max = 0.9
	_particles.color = PARTICLE_COLOR
	_particles.color_ramp = _create_particle_fade_gradient()
	add_child(_particles)
	_particles.emitting = true

	var cleanup_tween: Tween = create_tween()
	cleanup_tween.tween_interval(DURATION)
	cleanup_tween.tween_callback(queue_free)
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	var progress: float = clampf(_age / DURATION, 0.0, 1.0)
	var ring_color: Color = effect_color
	ring_color.a = (1.0 - progress) * 0.7
	draw_arc(Vector2.ZERO, 4.0 + progress * (6.0 + damage_hearts * 1.5), 0.0, TAU, 18, ring_color, 1.5)


func _create_particle_fade_gradient() -> Gradient:
	var fade_gradient: Gradient = Gradient.new()
	fade_gradient.colors = PackedColorArray([
		Color.WHITE,
		Color(1.0, 1.0, 1.0, 0.0),
	])
	return fade_gradient
