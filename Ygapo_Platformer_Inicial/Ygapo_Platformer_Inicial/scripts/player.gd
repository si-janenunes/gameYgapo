extends CharacterBody2D

@export var move_speed: float = 340.0
@export var jump_velocity: float = -680.0
@export var gravity: float = 1800.0

## As ações também são usadas pelos botões virtuais da tela.
const MOVE_LEFT_ACTION := "move_left"
const MOVE_RIGHT_ACTION := "move_right"
const JUMP_ACTION := "jump"

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

    # Input.get_axis lê as ações dos botões virtuais e dos controles configurados.
    var direction := Input.get_axis(MOVE_LEFT_ACTION, MOVE_RIGHT_ACTION)

    # Também lê as teclas físicas diretamente para não depender de um mapeamento
    # de teclado antigo guardado pelo editor. Os botões de celular continuam usando
    # as ações acima.
    var keyboard_direction := float(
        Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
    ) - float(
        Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
    )
    if keyboard_direction != 0.0:
        direction = keyboard_direction
    velocity.x = direction * move_speed

    if Input.is_action_just_pressed(JUMP_ACTION) and is_on_floor():
        velocity.y = jump_velocity

    move_and_slide()
