extends Node2D

## Protótipo de raid: entrada na fachada do Teatro e combate em tela lateral.
const FRONT := preload("res://assets/battle/frente_teatro.png")
const INTERIOR := preload("res://assets/scenery/interior_teatro.jpg")
const YGA_IDLE := preload("res://assets/battle/yga_idle.png")
const YGA_ATTACK := preload("res://assets/battle/yga_attack.png")
const YGA_LASER := preload("res://assets/battle/yga_laser.png")
const SLIME := preload("res://assets/battle/slime.png")
const SLIME_ATTACK := preload("res://assets/battle/slime_attack.png")
const MASCOT_BAR := preload("res://assets/battle/barra_mascote.png")
const MONSTER_BAR := preload("res://assets/battle/barra_monstro.png")
const CLAW_ICON := preload("res://assets/battle/habilidade_arranhao.png")
const LASER_ICON := preload("res://assets/battle/habilidade_laser.png")
const ITEMS_BAR := preload("res://assets/battle/items_bar.png")
const ITEM_BAR_NEW := preload("res://assets/battle/barra_itens.png")
const ITEM_HEAL := preload("res://assets/battle/item_heal.png")
const ITEM_ENERGY := preload("res://assets/battle/item_energy.png")

const MAX_PLAYER_HP := 100.0
const MAX_PLAYER_MP := 100.0
const MAX_BOSS_HP := 260.0
const MAX_BOSS_MP := 100.0
var player_hp := MAX_PLAYER_HP
var player_mp := MAX_PLAYER_MP
var boss_hp := MAX_BOSS_HP
var boss_mp := MAX_BOSS_MP
var heal_charges := 1
var mode := "entrance"
var busy := false
var battle_time := 0.0
var crawl_cycle := 0

var screen_ui: Control
var scene_art: TextureRect
var hero_art: TextureRect
var slime_art: TextureRect
var player_hp_bar: ProgressBar
var player_mp_bar: ProgressBar
var boss_hp_bar: ProgressBar
var boss_mp_bar: ProgressBar
var status_label: Label
var enter_button: Button
var claw_button: TextureButton
var laser_button: TextureButton
var heal_button: Button

func _ready() -> void:
	_build_screen()
	_show_entrance()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if mode == "entrance" and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			_enter_raid()
		elif mode == "battle":
			if event.keycode == KEY_J:
				_attack_claw()
			elif event.keycode == KEY_K:
				_attack_laser()
			elif event.keycode == KEY_H:
				_use_heal()

func _process(delta: float) -> void:
	if mode != "battle" or busy:
		return
	battle_time += delta
	if battle_time >= 3.4 and boss_hp > 0.0:
		battle_time = 0.0
		_boss_attack()

func _build_screen() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	screen_ui = Control.new()
	screen_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(screen_ui)

	scene_art = TextureRect.new()
	scene_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_ui.add_child(scene_art)

func _show_entrance() -> void:
	mode = "entrance"
	_clear_screen_children()
	scene_art = _add_background(FRONT)
	_add_scrim(Color(0.04, 0.025, 0.01, 0.18))

	var eyebrow := _label("RAID • MANAUS", 26, Color("#f5d48a"))
	eyebrow.position = Vector2(48, 38)
	screen_ui.add_child(eyebrow)
	var title := _label("TEATRO AMAZONAS", 43, Color.WHITE)
	title.position = Vector2(46, 73)
	screen_ui.add_child(title)
	var subtitle := _label("Uma ameaça tomou o palco.", 21, Color("#f6e7cc"))
	subtitle.position = Vector2(50, 125)
	screen_ui.add_child(subtitle)

	var hero := _texture(YGA_IDLE, Rect2(535, 500, 30, 30))
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.pivot_offset = hero.size * 0.5
	var glow := _radial_glow(Rect2(520, 485, 60, 60))
	screen_ui.add_child(glow)
	screen_ui.add_child(hero)
	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "modulate:a", 0.68, 0.65).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "modulate:a", 0.28, 0.65).set_trans(Tween.TRANS_SINE)
	pulse.parallel().tween_property(hero, "scale", Vector2(1.06, 1.06), 0.65).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(hero, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_SINE)
	var hint := _panel(Rect2(385, 590, 510, 88), Color(0.12, 0.055, 0.025, 0.9), Color("#d4a95d"))
	screen_ui.add_child(hint)
	var mission := _label("RAID DO TEATRO", 22, Color("#ffe7a1"))
	mission.position = Vector2(411, 598)
	screen_ui.add_child(mission)
	var details := _label("Monstro de lodo • 1 jogador", 16, Color("#fff5df"))
	details.position = Vector2(412, 630)
	screen_ui.add_child(details)
	enter_button = _button("ACEITAR PRÓXIMA FASE  ·  ENTER", Rect2(900, 574, 330, 72), Color("#9b4e18"))
	enter_button.pressed.connect(_enter_raid)
	screen_ui.add_child(enter_button)

func _enter_raid() -> void:
	if mode != "entrance":
		return
	_show_battle()

func _show_battle() -> void:
	mode = "battle"
	player_hp = MAX_PLAYER_HP
	player_mp = MAX_PLAYER_MP
	boss_hp = MAX_BOSS_HP
	boss_mp = MAX_BOSS_MP
	heal_charges = 1
	battle_time = 0.0
	_clear_screen_children()
	scene_art = _add_background(INTERIOR)
	_add_scrim(Color(0.035, 0.016, 0.012, 0.36))
	_add_arena_floor()

	var header := _panel(Rect2(0, 0, 1280, 95), Color(0.10, 0.045, 0.02, 0.80), Color("#a8783c"))
	screen_ui.add_child(header)
	var raid_title := _label("TEATRO AMAZONAS", 25, Color("#fff1d3"))
	raid_title.position = Vector2(36, 19)
	screen_ui.add_child(raid_title)
	var raid_subtitle := _label("RAID 01  /  O PALCO CONTAMINADO", 14, Color("#e8c58a"))
	raid_subtitle.position = Vector2(38, 53)
	screen_ui.add_child(raid_subtitle)
	status_label = _label("Derrote o monstro de lodo!", 18, Color("#fff5df"))
	status_label.position = Vector2(870, 34)
	status_label.size = Vector2(370, 30)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_ui.add_child(status_label)

	hero_art = _texture(YGA_IDLE, Rect2(190, 510, 30, 30))
	hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen_ui.add_child(hero_art)
	slime_art = _texture(SLIME, Rect2(875, 510, 30, 30))
	slime_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen_ui.add_child(slime_art)

	_add_character_hud(true)
	_add_character_hud(false)
	_add_boss_inventory()
	_add_ability_buttons()

func _add_character_hud(is_player: bool) -> void:
	var x := 24.0 if is_player else 855.0
	var art := _texture(MASCOT_BAR if is_player else MONSTER_BAR, Rect2(x, 98, 400, 132))
	screen_ui.add_child(art)
	var hp_x := x + (181.0 if is_player else 112.0)
	var bar_width := 152.0 if is_player else 178.0
	var hp := _make_bar(Vector2(hp_x, 155), bar_width, Color("#ef4b45"))
	var mp := _make_bar(Vector2(hp_x, 182), bar_width, Color("#41aefa"))
	hp.size.y = 15
	mp.size.y = 15
	screen_ui.add_child(hp)
	screen_ui.add_child(mp)
	if is_player:
		player_hp_bar = hp
		player_mp_bar = mp
		_add_bar_caption(hp_x, 155, "HP")
		_add_bar_caption(hp_x, 182, "MP")
	else:
		boss_hp_bar = hp
		boss_mp_bar = mp
		_add_bar_caption(hp_x, 155, "HP")
		_add_bar_caption(hp_x, 182, "MP")
	_update_bars()

func _add_boss_inventory() -> void:
	var bar := _texture(ITEM_BAR_NEW, Rect2(815, 590, 445, 112))
	screen_ui.add_child(bar)
	var potion := _texture(ITEM_HEAL, Rect2(852, 615, 54, 54))
	screen_ui.add_child(potion)
	var energy := _texture(ITEM_ENERGY, Rect2(922, 615, 54, 54))
	screen_ui.add_child(energy)
	var label := _label("ITENS  •  1 / 2", 15, Color("#fff0cf"))
	label.position = Vector2(982, 624)
	screen_ui.add_child(label)
	heal_button = _button("USAR  H", Rect2(1082, 626, 110, 34), Color("#774018"))
	heal_button.add_theme_font_size_override("font_size", 15)
	heal_button.pressed.connect(_use_heal)
	screen_ui.add_child(heal_button)

func _add_ability_buttons() -> void:
	claw_button = _ability(CLAW_ICON, Rect2(258, 585, 112, 112), "Arranhão  •  J")
	claw_button.pressed.connect(_attack_claw)
	screen_ui.add_child(claw_button)
	laser_button = _ability(LASER_ICON, Rect2(384, 585, 112, 112), "Laser  •  K")
	laser_button.pressed.connect(_attack_laser)
	screen_ui.add_child(laser_button)
	var controls := _label("ESCOLHA UM GOLPE", 14, Color("#ffe6b4"))
	controls.position = Vector2(64, 637)
	screen_ui.add_child(controls)

func _attack_claw() -> void:
	if mode != "battle" or busy or boss_hp <= 0.0:
		return
	busy = true
	status_label.text = "Ygá corre e salta para atacar!"
	hero_art.texture = YGA_ATTACK
	var leap := create_tween()
	leap.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	leap.tween_property(hero_art, "position", Vector2(535, 425), 0.42)
	leap.tween_property(hero_art, "position", Vector2(690, 505), 0.30).set_ease(Tween.EASE_IN)
	await leap.finished
	_apply_damage(34.0)
	hero_art.texture = YGA_IDLE
	_finish_turn()

func _attack_laser() -> void:
	if mode != "battle" or busy or boss_hp <= 0.0:
		return
	if player_mp < 30.0:
		status_label.text = "MP insuficiente para o Laser."
		return
	busy = true
	player_mp = maxf(0.0, player_mp - 30.0)
	_update_bars()
	status_label.text = "Ygá dispara o Laser!"
	hero_art.texture = YGA_LASER
	var advance := create_tween()
	advance.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	advance.tween_property(hero_art, "position", Vector2(minf(hero_art.position.x + 85.0, 650.0), 480.0), 0.3)
	await advance.finished
	var beam := ColorRect.new()
	beam.color = Color(0.25, 0.9, 1.0, 0.82)
	beam.position = Vector2(hero_art.position.x + 165.0, 450)
	beam.size = Vector2(225, 10)
	screen_ui.add_child(beam)
	await get_tree().create_timer(0.3).timeout
	beam.queue_free()
	_apply_damage(67.0)
	hero_art.texture = YGA_IDLE
	_finish_turn()

func _boss_attack() -> void:
	if mode != "battle" or busy or player_hp <= 0.0:
		return
	busy = true
	crawl_cycle += 1
	status_label.text = "O monstro rasteja lentamente pelo palco..."
	var crawl := create_tween()
	crawl.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	crawl.tween_property(slime_art, "position:x", maxf(650.0, slime_art.position.x - 34.0), 1.15)
	await crawl.finished
	status_label.text = "O monstro para e prepara um ataque!"
	await get_tree().create_timer(0.65).timeout
	if boss_mp < 20.0:
		status_label.text = "O monstro absorve energia do palco..."
		await get_tree().create_timer(0.35).timeout
		boss_mp = minf(MAX_BOSS_MP, boss_mp + 24.0)
		_update_bars()
		status_label.text = "Sua vez! Arranhão ou Laser."
		busy = false
		return
	status_label.text = "O monstro lança uma onda de lodo!"
	boss_mp = maxf(0.0, boss_mp - 20.0)
	_update_bars()
	slime_art.texture = SLIME_ATTACK
	slime_art.position.x -= 16
	await get_tree().create_timer(0.35).timeout
	slime_art.position.x += 16
	slime_art.texture = SLIME
	player_hp = maxf(0.0, player_hp - 13.0)
	player_mp = minf(MAX_PLAYER_MP, player_mp + 8.0)
	_update_bars()
	if player_hp <= 0.0:
		_end_battle(false)
	else:
		status_label.text = "Sua vez! Arranhão ou Laser."
		busy = false

func _use_heal() -> void:
	if mode != "battle" or busy or player_hp <= 0.0:
		return
	if heal_charges <= 0:
		status_label.text = "A poção já foi usada."
		return
	if player_hp >= MAX_PLAYER_HP:
		status_label.text = "HP já está cheio."
		return
	heal_charges -= 1
	player_hp = minf(MAX_PLAYER_HP, player_hp + 32.0)
	_update_bars()
	heal_button.text = "ESGOTADA"
	heal_button.disabled = true
	status_label.text = "Poção usada: +32 HP."

func _apply_damage(amount: float) -> void:
	boss_hp = maxf(0.0, boss_hp - amount)
	_update_bars()
	if boss_hp <= 0.0:
		_end_battle(true)

func _finish_turn() -> void:
	if mode == "battle" and boss_hp > 0.0:
		status_label.text = "O monstro prepara o próximo ataque..."
	busy = false

func _end_battle(victory: bool) -> void:
	mode = "result"
	busy = true
	var veil := ColorRect.new()
	veil.color = Color(0.025, 0.012, 0.008, 0.78)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_ui.add_child(veil)
	var card := _panel(Rect2(338, 235, 604, 250), Color(0.13, 0.055, 0.025, 0.97), Color("#d3a24c"))
	screen_ui.add_child(card)
	var title := _label("VITÓRIA!" if victory else "Ygá precisa recuar", 38, Color("#ffe5a1") if victory else Color("#f5c4a1"))
	title.position = Vector2(390, 281)
	screen_ui.add_child(title)
	var detail := _label("O palco está livre!" if victory else "Tente novamente e proteja o Teatro.", 20, Color("#fff6e9"))
	detail.position = Vector2(392, 339)
	screen_ui.add_child(detail)
	var retry := _button("JOGAR NOVAMENTE", Rect2(508, 405, 264, 53), Color("#8e4b1c"))
	retry.pressed.connect(_show_entrance)
	screen_ui.add_child(retry)

func _update_bars() -> void:
	if is_instance_valid(player_hp_bar):
		player_hp_bar.value = player_hp / MAX_PLAYER_HP * 100.0
	if is_instance_valid(player_mp_bar):
		player_mp_bar.value = player_mp / MAX_PLAYER_MP * 100.0
	if is_instance_valid(boss_hp_bar):
		boss_hp_bar.value = boss_hp / MAX_BOSS_HP * 100.0
	if is_instance_valid(boss_mp_bar):
		boss_mp_bar.value = boss_mp / MAX_BOSS_MP * 100.0

func _add_background(texture: Texture2D) -> TextureRect:
	var bg := TextureRect.new()
	bg.texture = texture
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_ui.add_child(bg)
	screen_ui.move_child(bg, 0)
	return bg

func _add_scrim(color: Color) -> void:
	var scrim := ColorRect.new()
	scrim.color = color
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_ui.add_child(scrim)

func _add_arena_floor() -> void:
	var floor := ColorRect.new()
	floor.color = Color(0.08, 0.025, 0.012, 0.56)
	floor.position = Vector2(0, 595)
	floor.size = Vector2(1280, 125)
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_ui.add_child(floor)
	var edge := ColorRect.new()
	edge.color = Color("#d6a44e")
	edge.position = Vector2(0, 594)
	edge.size = Vector2(1280, 3)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_ui.add_child(edge)

func _clear_screen_children() -> void:
	for child in screen_ui.get_children():
		child.queue_free()
	player_hp_bar = null
	player_mp_bar = null
	boss_hp_bar = null
	boss_mp_bar = null

func _texture(texture: Texture2D, rect: Rect2) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.position = rect.position
	view.size = rect.size
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view

func _make_bar(at: Vector2, width: float, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = at
	bar.size = Vector2(width, 22)
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _style(Color(0.04, 0.025, 0.02, 0.96), Color("#e9c783"), 2, 8))
	bar.add_theme_stylebox_override("fill", _style(color, color.lightened(0.16), 2, 8))
	return bar

func _add_bar_caption(x: float, y: float, text: String) -> void:
	var label := _label(text, 11, Color.WHITE)
	label.position = Vector2(x + 10, y + 2)
	label.size = Vector2(28, 16)
	screen_ui.add_child(label)

func _ability(texture: Texture2D, rect: Rect2, tooltip: String) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.position = rect.position
	button.size = rect.size
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	return button

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.025, 0.01, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _panel(rect: Rect2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(fill, border, 2, 14))
	return panel

func _button(caption: String, rect: Rect2, base: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("#fff1d6"))
	button.add_theme_stylebox_override("normal", _style(base, Color("#e2ba76"), 2, 13))
	button.add_theme_stylebox_override("hover", _style(base.lightened(0.16), Color("#ffe1a0"), 2, 13))
	button.add_theme_stylebox_override("pressed", _style(base.darkened(0.14), Color("#ffe1a0"), 2, 13))
	return button

func _style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.03, 0.015, 0.008, 0.48)
	style.shadow_size = 5
	return style

func _radial_glow(rect: Rect2) -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.72, 0.18, 0.82))
	gradient.set_color(1, Color(1.0, 0.72, 0.18, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	var glow := TextureRect.new()
	glow.texture = texture
	glow.position = rect.position
	glow.size = rect.size
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return glow
