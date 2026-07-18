extends Node2D
class_name AIController2D

enum ControlModes { INHERIT_FROM_SYNC, HUMAN, TRAINING, ONNX_INFERENCE, RECORD_EXPERT_DEMOS }
@export var control_mode: ControlModes = ControlModes.INHERIT_FROM_SYNC
@export var onnx_model_path := ""
@export var reset_after := 1000

@export_group("Record expert demos mode options")
@export var expert_demo_save_path: String
@export var remove_last_episode_key: InputEvent
@export var action_repeat: int = 1

@export_group("Multi-policy mode options")
@export var policy_name: String = "shared_policy"

var onnx_model: ONNXModel

var heuristic := "human"
var done := false
var reward := 0.0
var n_steps := 0
var needs_reset := false

var _player: Node2D

func _ready():
	add_to_group("AGENT")

func init(player: Node2D):
	_player = player

func get_obs() -> Dictionary:
	assert(false, "the get_obs method is not implemented when extending from ai_controller")
	return {"obs": []}

func get_reward() -> float:
	assert(false, "the get_reward method is not implemented when extending from ai_controller")
	return 0.0

func get_action_space() -> Dictionary:
	assert(
		false,
		"the get get_action_space method is not implemented when extending from ai_controller"
	)
	return {
		"example_actions_continous": {"size": 2, "action_type": "continuous"},
		"example_actions_discrete": {"size": 2, "action_type": "discrete"},
	}

func set_action(action) -> void:
	assert(false, "the set_action method is not implemented when extending from ai_controller")

func get_action() -> Array:
	assert(false, "the get_action method is not implemented in extended AIController but demo_recorder is used")
	return []

func _physics_process(_delta):
	n_steps += 1
	if reset_after > 0 and n_steps >= reset_after:
		done = true

func get_obs_space():
	var obs = get_obs()
	return {
		"obs": {"size": [len(obs["obs"])], "space": "box"},
	}

func reset():
	n_steps = 0
	needs_reset = false

func reset_if_done():
	if done:
		reset()

func set_heuristic(h):
	heuristic = h

func get_done():
	return done

func set_done_false():
	done = false

func zero_reward():
	reward = 0.0
