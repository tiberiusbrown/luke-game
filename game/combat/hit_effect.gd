class_name HitEffect
extends Node2D

const DURATION: float = 0.32

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
	return 4 + maxi(new_damage_hearts, 1) * 4


func _ready() -> void:
	_particles = CPUParticles2D.new()
	_particles.amount = particle_amount if particle_amount > 0 else particle_amount_for_damage(damage_hearts)
	_particles.lifetime = DURATION * 0.8
	_particles.one_shot = true
	_particles.explosiveness = 1.0
	_particles.direction = Vector2.UP
	_particles.spread = 180.0
	_particles.initial_velocity_min = 24.0 + damage_hearts * 5.0
	_particles.initial_velocity_max = 44.0 + damage_hearts * 9.0
	_particles.gravity = Vector2(0.0, 36.0 + damage_hearts * 8.0)
	_particles.scale_amount_min = 0.8 + damage_hearts * 0.05
	_particles.scale_amount_max = 1.2 + damage_hearts * 0.1
	_particles.color = effect_color
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
