extends Node2D


enum State {
	NONE,
	CHARGING,
	FIRING,
	ENDED,
}

var charge_time := 4.0 # The time it takes for the laser to charge
var fire_time := 4.0
var flash := 0.0
var progress := 0.0
var state = State.NONE

onready var audio: AudioStreamPlayer = get_node("Audio")
onready var pre_audio: AudioStreamPlayer = get_node("PreAudio")
onready var post_audio: AudioStreamPlayer = get_node("PostAudio")
onready var effect: Sprite = get_node("LaserEffect")
onready var pre_effect: Particles2D = get_node("LaserPreEffect")
onready var post_effect: Particles2D = get_node("LaserPostEffect")
onready var collision: Area2D = get_node("Collision")


func _process(delta):
	if flash > 0:
		flash -= delta * 10
		update()

	if state == State.NONE:
		begin_charge()

	elif state == State.CHARGING:
		progress += delta / charge_time
		pre_effect.process_material.set_shader_param("intensity", 1 + progress)
		if progress > 1:
			fire()

	elif state == State.FIRING:
		progress += delta / fire_time
		effect.region_rect.position.y = effect.texture.get_height() * randf()
		if progress > 1:
			end_fire()


func _draw():
	if flash > 0:
		# Set Z very low to draw behind everything
		var old_z = z_index
		var old_rel = z_as_relative
		z_index = -4096
		z_as_relative = false
		
		# Draw the flash (seems to require a camera to properly work)
		draw_set_transform_matrix(get_viewport_transform().inverse() * global_transform.inverse())
		var rect := get_viewport_rect()
		if flash > 0.5:
			draw_rect(rect, Color.red.linear_interpolate(Color.white, flash * 2 - 1))
		else:
			draw_rect(rect, Color(1, 0, 0, flash * 2))
		
		# Set Z back
		z_index = old_z
		z_as_relative = old_rel


func begin_charge():
	audio.stop()
	pre_audio.pitch_scale = pre_audio.stream.get_length() / charge_time
	pre_audio.play()
	pre_effect.emitting = true
	pre_effect.restart()
	pre_effect.visible = true
	effect.visible = false
	progress = 0
	state = State.CHARGING


func fire():
	audio.play()
	pre_effect.emitting = false
	pre_effect.visible = false
	effect.visible = true
	flash = 1
	update()
	# PUT CAMERA SHAKE SOMEWHERE HERE
	progress = 0
	state = State.FIRING


func end_fire():
	audio.stop()
	post_audio.play()
	pre_effect.emitting = false
	pre_effect.visible = false
	effect.visible = false
	post_effect.emitting = true
	progress = 0
	state = State.NONE
