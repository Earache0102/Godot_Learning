extends Node2D

var dragging := false

func _input(event):
	# 检查是否点击到自身
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			if event.pressed and $Sprite2D.get_rect().has_point(to_local(mouse_pos)):
				dragging = true
			elif not event.pressed:
				dragging = false

func _process(delta):
	if dragging:
		position = get_global_mouse_position()
