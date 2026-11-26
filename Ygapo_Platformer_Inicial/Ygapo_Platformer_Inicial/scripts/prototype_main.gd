extends Node2D

const FRONT: Texture2D = preload("res://assets/battle/frente_teatro.png")
const INTERIOR: Texture2D = preload("res://assets/scenery/interior_teatro.jpg")
const YGA_IDLE: Texture2D = preload("res://assets/battle/yga_idle.png")
const YGA_ATTACK: Texture2D = preload("res://assets/battle/yga_attack.png")
const YGA_LASER: Texture2D = preload("res://assets/battle/yga_laser.png")
const SLIME_IDLE: Texture2D = preload("res://assets/battle/slime.png")
const SLIME_ATTACK: Texture2D = preload("res://assets/battle/slime_attack.png")
const SLIME_FRONT: Texture2D = preload("res://assets/enemies/monstro_de_lodo/rastejar/frente_lodo.png")
const SLIME_MOVE_LEFT: Texture2D = preload("res://assets/enemies/monstro_de_lodo/rastejar/lodo_esquerda.png")
const SLIME_MOVE_RIGHT: Texture2D = preload("res://assets/enemies/monstro_de_lodo/rastejar/lodo_direita.png")
const HUD_YGA: Texture2D = preload("res://assets/battle/barra_mascote.png")
const HUD_SLIME: Texture2D = preload("res://assets/battle/barra_monstro.png")
const HUD_ITEMS: Texture2D = preload("res://assets/battle/barra_itens.png")
const ICON_CLAW: Texture2D = preload("res://assets/battle/habilidade_arranhao.png")
const ICON_LASER: Texture2D = preload("res://assets/battle/habilidade_laser.png")
const FX_CLAW: Texture2D = preload("res://assets/battle/claw.png")
const FX_LASER: Texture2D = preload("res://assets/battle/laser.png")
const ICON_HEAL: Texture2D = preload("res://assets/battle/item_heal.png")
const ICON_ENERGY: Texture2D = preload("res://assets/battle/item_energy.png")

const VIEW_SIZE := Vector2(1280.0, 720.0)
const FIGHTER_SIZE := Vector2(180.0, 180.0)
const ATTACK_FRAME_SIZE := Vector2(390.0, 390.0)
const BOSS_SIZE := Vector2(300.0, 300.0)
const GROUND_Y := 530.0
const WALK_SPEED := 390.0
const JUMP_SPEED := 980.0
const GRAVITY := 1500.0

var phase := "entrada"
var busy := false
var boss_busy := false
var boss_clock := 0.0
var boss_move_clock := 0.0
var claw_cooldown := 0.0
var laser_cooldown := 0.0
var player_vertical_speed := 0.0
var facing := 1.0
var walk_clock := 0.0
var walk_frame := 0
var walk_right_frames: Array[Texture2D] = []
var walk_left_frames: Array[Texture2D] = []
var claw_frames: Array[Texture2D] = []
var laser_frames: Array[Texture2D] = []
var slime_spawn_frames: Array[Texture2D] = []
var slime_attack_left_frames: Array[Texture2D] = []
var slime_attack_right_frames: Array[Texture2D] = []
var slime_bola_left_frames: Array[Texture2D] = []
var slime_bola_right_frames: Array[Texture2D] = []
var player_hp := 100.0
var player_mp := 100.0
var boss_hp := 260.0
var boss_mp := 100.0
var heal_count := 1
var left_touch := false
var right_touch := false
var jump_requested := false
var jump_in_progress := false
var boss_attack_cycle := 0
var slime_move_clock := 0.0

var background: TextureRect
var actors := Node2D.new()
var hud := CanvasLayer.new()
var yga: Sprite2D
var slime: Sprite2D
var status: Label
var hp_player: ProgressBar
var mp_player: ProgressBar
var hp_boss: ProgressBar
var mp_boss: ProgressBar
var heal_button: Button

func _ready() -> void:
	var back_layer := CanvasLayer.new()
	back_layer.layer = -1
	add_child(back_layer)
	background = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_layer.add_child(background)
	add_child(actors)
	hud.layer = 1
	add_child(hud)
	walk_right_frames = _load_walk_frames("movement_right", "yga_direita", 10)
	walk_left_frames = _load_walk_frames("movement_left", "yga_esquerda", 8)
	claw_frames = _load_named_frames("yga_arranhao", "yga_arranhao", 7)
	laser_frames = _load_named_frames("yga_laser", "yga_laser", 4)
	slime_spawn_frames = _load_enemy_frames("surgir", "surgir", 3)
	slime_attack_left_frames = _load_enemy_frames("ataques_lodo", "ataque_lodo_esq", 4)
	slime_attack_right_frames = _load_enemy_frames("ataques_lodo", "ataque_lodo", 4)
	slime_bola_left_frames = _load_enemy_frames("ataque_bola_lama", "bola_lama_esquerda", 4)
	slime_bola_right_frames = _load_enemy_frames("ataque_bola_lama", "bola_lama_direita", 4)
	_show_entrance()

func _process(delta: float) -> void:
	if phase != "batalha":
		return
	_update_player_movement(delta)
	_update_boss_movement(delta)
	claw_cooldown = maxf(0.0, claw_cooldown - delta)
	laser_cooldown = maxf(0.0, laser_cooldown - delta)
	if boss_busy:
		return
	boss_clock += delta
	if boss_clock >= 3.6 and boss_hp > 0.0:
		boss_clock = 0.0
		_boss_attack()

func _load_walk_frames(folder: String, name_prefix: String, count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for frame_number in range(1, count + 1):
		var path := "res://assets/characters/YGA/%s/%s_%02d.png" % [folder, name_prefix, frame_number]
		if ResourceLoader.exists(path):
			var frame := load(path) as Texture2D
			if frame != null:
				frames.append(frame)
	return frames

func _load_named_frames(folder: String, name_prefix: String, count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for frame_number in range(1, count + 1):
		var path := "res://assets/characters/YGA/%s/%s_%02d.png" % [folder, name_prefix, frame_number]
		if ResourceLoader.exists(path):
			var frame := load(path) as Texture2D
			if frame != null:
				frames.append(frame)
	return frames

func _load_enemy_frames(folder: String, name_prefix: String, count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for frame_number in range(1, count + 1):
		var path := "res://assets/enemies/monstro_de_lodo/%s/%s_%02d.png" % [folder, name_prefix, frame_number]
		if ResourceLoader.exists(path):
			var frame := load(path) as Texture2D
			if frame != null:
				frames.append(frame)
	return frames

func _update_boss_movement(delta: float) -> void:
	if slime == null or not is_instance_valid(slime) or yga == null or boss_busy or boss_hp <= 0.0:
		return
	var gap := yga.position.x - slime.position.x
	var desired_x := yga.position.x + (275.0 if gap > 0.0 else -275.0)
	if absf(gap) > 310.0:
		slime.position.x = move_toward(slime.position.x, clampf(desired_x, 185.0, 1100.0), 62.0 * delta)
		slime.texture = SLIME_MOVE_LEFT if gap < 0.0 else SLIME_MOVE_RIGHT
		slime.scale = _sprite_scale(slime.texture, BOSS_SIZE)
		slime_move_clock += delta
		slime.position.y = GROUND_Y - BOSS_SIZE.y * 0.5 + sin(slime_move_clock * 13.0) * 4.0
	else:
		var idle_texture := SLIME_MOVE_LEFT if gap < 0.0 else SLIME_MOVE_RIGHT
		if slime.texture != idle_texture:
			slime.texture = idle_texture
			slime.scale = _sprite_scale(idle_texture, BOSS_SIZE)
		slime.position.y = GROUND_Y - BOSS_SIZE.y * 0.5

func _update_player_movement(delta: float) -> void:
	if yga == null or not is_instance_valid(yga):
		return
	var left_pressed := Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A) or left_touch
	var right_pressed := Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D) or right_touch
	var direction := float(right_pressed) - float(left_pressed)
	if absf(direction) > 0.01:
		facing = signf(direction)
		var next_x := clampf(yga.position.x + direction * WALK_SPEED * delta, 70.0, 1210.0)
		if slime != null and is_instance_valid(slime) and not jump_in_progress:
			var safe_gap := 245.0
			if direction > 0.0 and yga.position.x <= slime.position.x:
				next_x = minf(next_x, slime.position.x - safe_gap)
			elif direction < 0.0 and yga.position.x >= slime.position.x:
				next_x = maxf(next_x, slime.position.x + safe_gap)
		yga.position.x = next_x
	var floor_center := GROUND_Y - FIGHTER_SIZE.y * 0.5
	var on_ground := yga.position.y >= floor_center - 0.5
	if on_ground:
		yga.position.y = floor_center
		if jump_requested or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_UP):
			player_vertical_speed = -JUMP_SPEED
			jump_requested = false
			jump_in_progress = true
	else:
		player_vertical_speed += GRAVITY * delta
		yga.position.y += player_vertical_speed * delta
		if yga.position.y >= floor_center:
			yga.position.y = floor_center
			player_vertical_speed = 0.0
			jump_in_progress = false
			on_ground = true
	if busy:
		return
	if not on_ground:
		return
	if absf(direction) > 0.01:
		walk_clock += delta
		if walk_clock >= 0.09:
			walk_clock = 0.0
			var frames := walk_right_frames if facing > 0.0 else walk_left_frames
			if not frames.is_empty():
				yga.texture = frames[walk_frame % frames.size()]
				yga.scale = _sprite_scale(yga.texture)
				walk_frame += 1
	else:
		walk_clock = 0.0
		if yga.texture != YGA_IDLE:
			_set_sprite_texture(yga, YGA_IDLE)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if phase == "entrada" and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_enter_battle()
	elif phase == "batalha":
		if event.keycode in [KEY_SPACE, KEY_UP]:
			jump_requested = true
		elif event.keycode == KEY_J:
			_attack_claw()
		elif event.keycode == KEY_K:
			_attack_laser()
		elif event.keycode == KEY_H:
			_use_heal()

func _sprite_scale(texture: Texture2D, wanted: Vector2 = FIGHTER_SIZE) -> Vector2:
	var texture_size := texture.get_size()
	var factor := minf(wanted.x / texture_size.x, wanted.y / texture_size.y)
	return Vector2.ONE * factor

func _make_sprite(texture: Texture2D, at: Vector2, wanted: Vector2 = FIGHTER_SIZE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = at
	sprite.scale = _sprite_scale(texture, wanted)
	sprite.centered = true
	return sprite

func _set_sprite_texture(sprite: Sprite2D, texture: Texture2D, wanted: Vector2 = FIGHTER_SIZE) -> void:
	sprite.texture = texture
	sprite.scale = _sprite_scale(texture, wanted)

func _reset_screen() -> void:
	for node in actors.get_children():
		node.queue_free()
	for node in hud.get_children():
		node.queue_free()
	yga = null
	slime = null
	status = null
	hp_player = null
	mp_player = null
	hp_boss = null
	mp_boss = null

func _show_entrance() -> void:
	phase = "entrada"
	busy = false
	_reset_screen()
	background.texture = FRONT
	var aura := _make_sprite(YGA_IDLE, Vector2(550, 480), Vector2(190, 190))
	aura.modulate = Color(1.0, 0.72, 0.12, 0.45)
	actors.add_child(aura)
	yga = _make_sprite(YGA_IDLE, Vector2(550, 480))
	actors.add_child(yga)
	var shine := create_tween().set_loops()
	shine.tween_property(aura, "modulate:a", 0.75, 0.6)
	shine.tween_property(aura, "modulate:a", 0.25, 0.6)
	shine.parallel().tween_property(aura, "scale", _sprite_scale(YGA_IDLE, Vector2(205, 205)), 0.6)
	shine.tween_property(aura, "scale", _sprite_scale(YGA_IDLE, Vector2(175, 175)), 0.6)
	_add_label("TEATRO AMAZONAS", Vector2(44, 44), 38, Color.WHITE)
	_add_label("Ygá encontrou o caminho para a próxima fase.", Vector2(48, 94), 19, Color("#fff1d4"))
	_add_panel(Rect2(36, 574, 1208, 110), Color(0.08, 0.035, 0.018, 0.88), Color("#d5a34c"))
	_add_label("RAID DO TEATRO", Vector2(60, 590), 23, Color("#ffe7a1"))
	_add_label("Monstro de lodo • Ygá vai lutar sozinho", Vector2(60, 626), 17, Color.WHITE)
	_add_button("ACEITAR PRÓXIMA FASE", Rect2(890, 594, 320, 66), _enter_battle)

func _enter_battle() -> void:
	_show_battle()

func _show_battle() -> void:
	phase = "batalha"
	busy = false
	boss_busy = false
	boss_clock = 0.0
	boss_attack_cycle = 0
	jump_requested = false
	claw_cooldown = 0.0
	laser_cooldown = 0.0
	player_vertical_speed = 0.0
	jump_in_progress = false
	jump_requested = false
	player_hp = 100.0
	player_mp = 100.0
	boss_hp = 260.0
	boss_mp = 100.0
	heal_count = 1
	_reset_screen()
	background.texture = INTERIOR
	var floor := ColorRect.new()
	floor.position = Vector2(0, GROUND_Y + 1)
	floor.size = Vector2(1280, 3)
	floor.color = Color("#d2a14f")
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(floor)
	_add_panel(Rect2(0, 0, 1280, 86), Color(0.08, 0.035, 0.015, 0.82), Color("#a8783c"))
	_add_label("TEATRO AMAZONAS  •  EMBATE", Vector2(32, 20), 24, Color("#fff0d0"))
	status = _add_label("Derrote o monstro de lodo!", Vector2(720, 27), 18, Color.WHITE)
	status.size = Vector2(520, 32)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	yga = _make_sprite(YGA_IDLE, Vector2(180, GROUND_Y - FIGHTER_SIZE.y * 0.5))
	slime = _make_sprite(SLIME_FRONT, Vector2(1030, GROUND_Y - BOSS_SIZE.y * 0.5), BOSS_SIZE)
	yga.z_index = 2
	slime.z_index = 1
	actors.add_child(yga)
	actors.add_child(slime)
	_add_hud(true)
	_add_hud(false)
	var mobile_ui := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	var attack_size := 90.0 if mobile_ui else 72.0
	var attack_gap := 14.0
	_add_attack_button(ICON_CLAW, Rect2(18, 708.0 - attack_size, attack_size, attack_size), "Arranhão • J", _attack_claw)
	_add_attack_button(ICON_LASER, Rect2(18.0 + attack_size + attack_gap, 708.0 - attack_size, attack_size, attack_size), "Laser • K", _attack_laser)
	_add_inventory()
	_add_touch_controls()
	_update_bars()
	_play_boss_spawn()

func _play_boss_spawn() -> void:
	if slime == null or not is_instance_valid(slime):
		return
	boss_busy = true
	status.text = "O monstro de lodo está surgindo!"
	await _play_enemy_frames(slime_spawn_frames, SLIME_FRONT, 0.75)
	if slime != null and is_instance_valid(slime):
		slime.texture = SLIME_MOVE_LEFT if yga.position.x < slime.position.x else SLIME_MOVE_RIGHT
		slime.scale = _sprite_scale(slime.texture, BOSS_SIZE)
	boss_busy = false
	boss_clock = 0.0
	status.text = "O monstro apareceu! Use as setas e os ataques."

func _add_hud(for_player: bool) -> void:
	var pos := Vector2(16, 89) if for_player else Vector2(865, 89)
	var art := _texture_control(HUD_YGA if for_player else HUD_SLIME, Rect2(pos.x, pos.y, 390, 125))
	hud.add_child(art)
	var x := pos.x + (178.0 if for_player else 108.0)
	var hpbar := _make_bar(Vector2(x, 143), 160, Color("#ed4b45"))
	var mpbar := _make_bar(Vector2(x, 170), 160, Color("#42aefa"))
	hud.add_child(hpbar)
	hud.add_child(mpbar)
	if for_player:
		hp_player = hpbar
		mp_player = mpbar
	else:
		hp_boss = hpbar
		mp_boss = mpbar

func _add_inventory() -> void:
	# Mantém a moldura do inventário e substitui os recursos recicláveis que
	# apareciam indevidamente por dois espaços demonstrativos de poção HP/MP.
	var bar_rect := Rect2(900, 620, 350, 88)
	hud.add_child(_texture_control(HUD_ITEMS, bar_rect))
	_add_potion_slot(Rect2(934, 638, 42, 48), "HP", Color("#df4141"), "Poção de HP • H", _use_heal)
	_add_potion_slot(Rect2(1000, 638, 42, 48), "MP", Color("#31a9ef"), "Poção de MP • M", _use_mana)
	_add_label("1", Vector2(970, 674), 13, Color.WHITE)
	_add_label("2", Vector2(1037, 674), 13, Color.WHITE)


func _add_potion_slot(rect: Rect2, kind: String, potion_color: Color, hint: String, callback: Callable) -> void:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.tooltip_text = hint
	button.pressed.connect(callback)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _style(potion_color.darkened(0.48), Color("#eac06b")))
	button.add_theme_stylebox_override("hover", _style(potion_color.darkened(0.22), Color("#fff0bd")))
	button.add_theme_stylebox_override("pressed", _style(potion_color.darkened(0.58), Color("#d69b42")))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.text = kind
	hud.add_child(button)

func _add_touch_controls() -> void:
	if not OS.has_feature("mobile") and not DisplayServer.is_touchscreen_available():
		return
	_add_touch_button("◀", Rect2(200, 620, 58, 58), func(pressed: bool): left_touch = pressed)
	_add_touch_button("▶", Rect2(264, 620, 58, 58), func(pressed: bool): right_touch = pressed)
	_add_touch_button("PULAR", Rect2(328, 620, 58, 58), func(pressed: bool):
		if pressed:
			jump_requested = true
	)

func _add_touch_button(text: String, rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#fff1d6"))
	button.add_theme_stylebox_override("normal", _style(Color(0.25, 0.12, 0.05, 0.82), Color("#e2ba76")))
	button.add_theme_stylebox_override("hover", _style(Color(0.42, 0.22, 0.08, 0.92), Color("#ffe1a0")))
	button.button_down.connect(func(): callback.call(true))
	button.button_up.connect(func(): callback.call(false))
	hud.add_child(button)

func _add_attack_button(texture: Texture2D, rect: Rect2, hint: String, callback: Callable) -> void:
	var button := TextureButton.new()
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.position = rect.position
	button.size = rect.size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.tooltip_text = hint
	button.pressed.connect(callback)
	hud.add_child(button)

func _attack_claw() -> void:
	if phase != "batalha" or busy or claw_cooldown > 0.0 or boss_hp <= 0.0:
		return
	claw_cooldown = 0.38
	busy = true
	status.text = "Ygá corre e salta para usar Arranhão!"
	_set_sprite_texture(yga, YGA_ATTACK, ATTACK_FRAME_SIZE)
	var leap_target_x := clampf(yga.position.x + facing * 105.0, 70.0, 1210.0)
	if slime != null and is_instance_valid(slime):
		leap_target_x = clampf(leap_target_x, 70.0, slime.position.x - 245.0)
	var leap := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	leap.tween_property(yga, "position", Vector2(leap_target_x, yga.position.y - 58.0), 0.16)
	await leap.finished
	await _play_attack_frames(claw_frames, YGA_ATTACK, 0.42, ATTACK_FRAME_SIZE)
	var return_leap := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	return_leap.tween_property(yga, "position", Vector2(yga.position.x, GROUND_Y - FIGHTER_SIZE.y * 0.5), 0.13)
	await return_leap.finished
	var gap := slime.position.x - yga.position.x
	var in_range := absf(gap) <= 290.0 and (absf(gap) < 70.0 or signf(gap) == facing)
	if in_range:
		boss_hp = maxf(0.0, boss_hp - 34.0)
		_update_bars()
	_set_sprite_texture(yga, YGA_IDLE)
	if boss_hp <= 0.0:
		_end_battle(true)
	elif in_range:
		status.text = "Arranhão acertou!"
		busy = false
	else:
		status.text = "Chegue mais perto e vire-se para o monstro para acertar."
		busy = false

func _attack_laser() -> void:
	if phase != "batalha" or busy or laser_cooldown > 0.0 or boss_hp <= 0.0:
		return
	if player_mp < 30.0:
		status.text = "MP insuficiente para o Laser."
		return
	laser_cooldown = 0.8
	busy = true
	player_mp -= 30.0
	_update_bars()
	status.text = "Ygá dispara o Laser!"
	_set_sprite_texture(yga, YGA_LASER, ATTACK_FRAME_SIZE)
	await _play_attack_frames(laser_frames, YGA_LASER, 0.48, ATTACK_FRAME_SIZE)
	var gap := slime.position.x - yga.position.x
	var hit_by_laser := signf(gap) == facing and absf(gap) <= 560.0
	if hit_by_laser:
		boss_hp = maxf(0.0, boss_hp - 62.0)
		_update_bars()
	_set_sprite_texture(yga, YGA_IDLE)
	if boss_hp <= 0.0:
		_end_battle(true)
	else:
		busy = false
		status.text = "Laser acertou!" if hit_by_laser else "O Laser passou longe; vire-se para o monstro."

func _play_attack_frames(frames: Array[Texture2D], fallback: Texture2D, total_time: float, frame_size: Vector2) -> void:
	if frames.is_empty():
		_set_sprite_texture(yga, fallback, frame_size)
		await get_tree().create_timer(total_time).timeout
		return
	var frame_delay := total_time / float(frames.size())
	for frame_texture in frames:
		if yga == null or not is_instance_valid(yga):
			return
		_set_sprite_texture(yga, frame_texture, frame_size)
		await get_tree().create_timer(frame_delay).timeout

func _play_enemy_frames(frames: Array[Texture2D], fallback: Texture2D, total_time: float) -> void:
	if slime == null or not is_instance_valid(slime):
		return
	if frames.is_empty():
		_set_sprite_texture(slime, fallback, BOSS_SIZE)
		await get_tree().create_timer(total_time).timeout
		return
	var frame_delay := total_time / float(frames.size())
	for frame_texture in frames:
		if slime == null or not is_instance_valid(slime):
			return
		_set_sprite_texture(slime, frame_texture, BOSS_SIZE)
		await get_tree().create_timer(frame_delay).timeout

func _use_mana() -> void:
	if busy or phase != "batalha" or player_mp >= 100.0:
		return
	player_mp = minf(100.0, player_mp + 35.0)
	_update_bars()
	status.text = "Poção de MP usada: +35 MP."

func _boss_attack() -> void:
	if boss_busy or phase != "batalha":
		return
	boss_busy = true
	var player_on_left := yga.position.x < slime.position.x
	var attack_reaches_player := false
	if boss_attack_cycle % 2 == 0:
		status.text = "O monstro prepara uma bola de lodo! Pule para desviar."
		var ball_frames := slime_bola_left_frames if player_on_left else slime_bola_right_frames
		await _play_enemy_frames(ball_frames, SLIME_ATTACK, 0.72)
		attack_reaches_player = absf(slime.position.x - yga.position.x) <= 600.0 and absf(slime.position.y - yga.position.y) <= 100.0
	else:
		status.text = "O monstro golpeia com lodo!"
		var melee_frames := slime_attack_left_frames if player_on_left else slime_attack_right_frames
		await _play_enemy_frames(melee_frames, SLIME_ATTACK, 0.72)
		attack_reaches_player = absf(slime.position.x - yga.position.x) <= 330.0 and absf(slime.position.y - yga.position.y) <= 100.0
	boss_attack_cycle += 1
	var idle_texture := SLIME_MOVE_LEFT if player_on_left else SLIME_MOVE_RIGHT
	_set_sprite_texture(slime, idle_texture, BOSS_SIZE)
	if attack_reaches_player:
		player_hp = maxf(0.0, player_hp - (15.0 if boss_attack_cycle % 2 == 1 else 12.0))
		player_mp = minf(100.0, player_mp + 6.0)
		_update_bars()
		if player_hp <= 0.0:
			_end_battle(false)
			return
	status.text = "O pulo desviou do ataque!" if not attack_reaches_player else "O monstro acertou! Continue se movendo e atacando."
	boss_busy = false

func _use_heal() -> void:
	if busy or phase != "batalha" or heal_count <= 0 or player_hp >= 100.0:
		return
	heal_count -= 1
	player_hp = minf(100.0, player_hp + 35.0)
	_update_bars()
	if is_instance_valid(heal_button):
		heal_button.text = "USAR H  (%d)" % heal_count
		heal_button.disabled = heal_count == 0
	status.text = "Poção usada: +35 HP."

func _end_battle(victory: bool) -> void:
	phase = "resultado"
	busy = true
	_add_panel(Rect2(330, 235, 620, 220), Color(0.09, 0.035, 0.015, 0.96), Color("#d5a34c"))
	_add_label("VITÓRIA!" if victory else "Ygá precisa recuar", Vector2(410, 275), 36, Color("#ffe7a1"))
	_add_button("VOLTAR AO TEATRO", Rect2(480, 360, 320, 62), _show_entrance)

func _update_bars() -> void:
	if is_instance_valid(hp_player):
		hp_player.value = player_hp
	if is_instance_valid(mp_player):
		mp_player.value = player_mp
	if is_instance_valid(hp_boss):
		hp_boss.value = boss_hp / 260.0 * 100.0
	if is_instance_valid(mp_boss):
		mp_boss.value = boss_mp

func _make_bar(at: Vector2, width: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = Vector2(width, 16)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color("#24140f"), Color("#f4d18e")))
	bar.add_theme_stylebox_override("fill", _style(fill, fill.lightened(0.15)))
	return bar

func _add_label(text: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("#211209"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(label)
	return label

func _add_panel(rect: Rect2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, border))
	hud.add_child(panel)
	return panel

func _add_button(text: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("#fff1d6"))
	button.add_theme_stylebox_override("normal", _style(Color("#914812"), Color("#e2ba76")))
	button.add_theme_stylebox_override("hover", _style(Color("#b66720"), Color("#ffe1a0")))
	button.pressed.connect(callback)
	hud.add_child(button)
	return button

func _texture_control(texture: Texture2D, rect: Rect2) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.position = rect.position
	view.size = rect.size
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style
