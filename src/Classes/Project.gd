class_name Project extends Reference
# A class for project properties.


var name := ""
var size : Vector2
var undo_redo : UndoRedo
var undos := 0 # The number of times we added undo properties
var has_changed := false
var frames := [] setget frames_changed # Array of Frames (that contain Cels)
var layers := [] setget layers_changed # Array of Layers
var current_frame := 0 setget frame_changed
var current_layer := 0 setget layer_changed
var animation_tags := [] setget animation_tags_changed # Array of AnimationTags
#var guides := [] # Array of Guides

var brushes := [] # Array of Images
var brush_images := [Image.new(), Image.new()]
var brush_textures := [ImageTexture.new(), ImageTexture.new()]

var selected_pixels := []


func _init(_name := tr("untitled"), _size := Vector2(64, 64)) -> void:
	name = _name
	size = _size
	layers.append(Layer.new())
	undo_redo = UndoRedo.new()


func frames_changed(value : Array) -> void:
	frames = value
	for container in Global.frames_container.get_children():
		for button in container.get_children():
			container.remove_child(button)
			button.queue_free()
		Global.frames_container.remove_child(container)

	for frame_id in Global.frame_ids.get_children():
		Global.frame_ids.remove_child(frame_id)
		frame_id.queue_free()

	for i in range(layers.size() - 1, -1, -1):
		Global.frames_container.add_child(layers[i].frame_container)

	for j in range(frames.size()):
		var label := Label.new()
		label.rect_min_size.x = 36
		label.align = Label.ALIGN_CENTER
		label.text = str(j + 1)
		Global.frame_ids.add_child(label)

		for i in range(layers.size() - 1, -1, -1):
			var cel_button = load("res://src/UI/Timeline/CelButton.tscn").instance()
			cel_button.frame = j
			cel_button.layer = i
			cel_button.get_child(0).texture = frames[j].cels[i].image_texture

			layers[i].frame_container.add_child(cel_button)

	# This is useful in case tagged frames get deleted DURING the animation is playing
	# otherwise, this code is useless in this context, since these values are being set
	# when the play buttons get pressed, anyway
	Global.animation_timeline.first_frame = 0
	Global.animation_timeline.last_frame = frames.size() - 1
	if Global.play_only_tags:
		for tag in animation_tags:
			if current_frame + 1 >= tag.from && current_frame + 1 <= tag.to:
				Global.animation_timeline.first_frame = tag.from - 1
				Global.animation_timeline.last_frame = min(frames.size() - 1, tag.to - 1)


func layers_changed(value : Array) -> void:
	layers = value
	if Global.layers_changed_skip:
		Global.layers_changed_skip = false
		return

	for container in Global.layers_container.get_children():
		container.queue_free()

	for container in Global.frames_container.get_children():
		for button in container.get_children():
			container.remove_child(button)
			button.queue_free()
		Global.frames_container.remove_child(container)

	for i in range(layers.size() - 1, -1, -1):
		var layer_container = load("res://src/UI/Timeline/LayerButton.tscn").instance()
		layer_container.i = i
		if layers[i].name == tr("Layer") + " 0":
			layers[i].name = tr("Layer") + " %s" % i

		Global.layers_container.add_child(layer_container)
		layer_container.label.text = layers[i].name
		layer_container.line_edit.text = layers[i].name

		Global.frames_container.add_child(layers[i].frame_container)
		for j in range(frames.size()):
			var cel_button = load("res://src/UI/Timeline/CelButton.tscn").instance()
			cel_button.frame = j
			cel_button.layer = i
			cel_button.get_child(0).texture = frames[j].cels[i].image_texture

			layers[i].frame_container.add_child(cel_button)

	var layer_button = Global.layers_container.get_child(Global.layers_container.get_child_count() - 1 - current_layer)
	layer_button.pressed = true
	self.current_frame = current_frame # Call frame_changed to update UI

	if layers[current_layer].locked:
		Global.disable_button(Global.remove_layer_button, true)

	if layers.size() == 1:
		Global.disable_button(Global.remove_layer_button, true)
		Global.disable_button(Global.move_up_layer_button, true)
		Global.disable_button(Global.move_down_layer_button, true)
		Global.disable_button(Global.merge_down_layer_button, true)
	elif !layers[current_layer].locked:
		Global.disable_button(Global.remove_layer_button, false)


func frame_changed(value : int) -> void:
	current_frame = value
	Global.current_frame_mark_label.text = "%s/%s" % [str(current_frame + 1), frames.size()]

	for i in frames.size(): # De-select all the other frames
		var text_color := Color.white
		if Global.theme_type == Global.Theme_Types.CARAMEL || Global.theme_type == Global.Theme_Types.LIGHT:
			text_color = Color.black
		Global.frame_ids.get_child(i).add_color_override("font_color", text_color)
		for layer in layers:
			if i < layer.frame_container.get_child_count():
				layer.frame_container.get_child(i).pressed = false

	# Select the new frame
	Global.frame_ids.get_child(current_frame).add_color_override("font_color", Global.control.theme.get_color("Selected Color", "Label"))
	if current_frame < layers[current_layer].frame_container.get_child_count():
		layers[current_layer].frame_container.get_child(current_frame).pressed = true

	if frames.size() == 1:
		Global.disable_button(Global.remove_frame_button, true)
	elif !layers[current_layer].locked:
		Global.disable_button(Global.remove_frame_button, false)

	Global.canvas.update()
	Global.transparent_checker._ready() # To update the rect size


func layer_changed(value : int) -> void:
	current_layer = value
	if current_frame < frames.size():
		Global.layer_opacity_slider.value = frames[current_frame].cels[current_layer].opacity * 100
		Global.layer_opacity_spinbox.value = frames[current_frame].cels[current_layer].opacity * 100

	for container in Global.layers_container.get_children():
		container.pressed = false

	if current_layer < Global.layers_container.get_child_count():
		var layer_button = Global.layers_container.get_child(Global.layers_container.get_child_count() - 1 - current_layer)
		layer_button.pressed = true

	if current_layer < layers.size() - 1:
		Global.disable_button(Global.move_up_layer_button, false)
	else:
		Global.disable_button(Global.move_up_layer_button, true)

	if current_layer > 0:
		Global.disable_button(Global.move_down_layer_button, false)
		Global.disable_button(Global.merge_down_layer_button, false)
	else:
		Global.disable_button(Global.move_down_layer_button, true)
		Global.disable_button(Global.merge_down_layer_button, true)

	if current_layer < layers.size():
		if layers[current_layer].locked:
			Global.disable_button(Global.remove_layer_button, true)
		else:
			if layers.size() > 1:
				Global.disable_button(Global.remove_layer_button, false)

	yield(Global.get_tree().create_timer(0.01), "timeout")
	self.current_frame = current_frame # Call frame_changed to update UI


func animation_tags_changed(value : Array) -> void:
	animation_tags = value
	for child in Global.tag_container.get_children():
		child.queue_free()

	for tag in animation_tags:
		var tag_c : Container = load("res://src/UI/Timeline/AnimationTag.tscn").instance()
		Global.tag_container.add_child(tag_c)
		var tag_position : int = Global.tag_container.get_child_count() - 1
		Global.tag_container.move_child(tag_c, tag_position)
		tag_c.get_node("Label").text = tag.name
		tag_c.get_node("Label").modulate = tag.color
		tag_c.get_node("Line2D").default_color = tag.color

		tag_c.rect_position.x = (tag.from - 1) * 39 + tag.from

		var size : int = tag.to - tag.from
		tag_c.rect_min_size.x = (size + 1) * 39
		tag_c.get_node("Line2D").points[2] = Vector2(tag_c.rect_min_size.x, 0)
		tag_c.get_node("Line2D").points[3] = Vector2(tag_c.rect_min_size.x, 32)

	# This is useful in case tags get modified DURING the animation is playing
	# otherwise, this code is useless in this context, since these values are being set
	# when the play buttons get pressed, anyway
	Global.animation_timeline.first_frame = 0
	Global.animation_timeline.last_frame = frames.size() - 1
	if Global.play_only_tags:
		for tag in animation_tags:
			if current_frame + 1 >= tag.from && current_frame + 1 <= tag.to:
				Global.animation_timeline.first_frame = tag.from - 1
				Global.animation_timeline.last_frame = min(frames.size() - 1, tag.to - 1)