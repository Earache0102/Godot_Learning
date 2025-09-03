extends Node2D

var screen_rect : Rect2 


var A_boids = []
var A_num = 3
var B_boids = []
var B_num = 30
var D_boids = []
var D_num = 20
var max_D_boid_num = 30
var quadtree = null

var score = 0
var time = 0
var highest_score = 0
var is_game_start = false
var is_game_over = false

const BOID = preload("res://Scenes/boid.tscn")
const ALPHABOID = preload("res://Scenes/alpha_boid.tscn")
const BETABOID = preload("res://Scenes/beta_boid.tscn")
const DELTABOID = preload("res://Scenes/delta_boid.tscn")
const PLAYER = preload("res://Scenes/player.tscn")
const BACKGROUND = preload("res://Scenes/back_ground.tscn")

@export var score_timer : Timer
@export var D_boid_timer : Timer
@export var time_label : Label
@export var score_label : Label
@export var score_increas_label : Label
@export var game_label : Label
@export var start_label : Label
@export var game_over_label : Label
@export var signature_label : Label
@export var high_score_label : Label

func _ready() -> void:
	
	score = 0
	screen_rect = get_viewport_rect()
	quadtree = QuadTree.new(screen_rect, 10)
	
	quadtree.insert($Player)
	
	#生成boid，add_child,并入boids[],导入四叉树
	spawn_B_Boid(B_num)
	spawn_A_Boid(A_num)
	spawn_D_Boid(D_num)
	
		
func spawn_B_Boid(num : int):
	#生成普通boid
	for i in range(num):
		var B_boid_instance = BETABOID.instantiate()
		B_boid_instance.position = Vector2(randi() % int(screen_rect.size.x), randi() % int(screen_rect.size.y))
		add_child(B_boid_instance)
		B_boids.append(B_boid_instance)
		quadtree.insert(B_boid_instance)
		
func spawn_A_Boid(num : int):
	#生成alpha boid
	for i in range(num):
		var A_boid_instance = ALPHABOID.instantiate()
		A_boid_instance.position = Vector2(randi() % int(screen_rect.size.x), randi() % int(screen_rect.size.y))
		add_child(A_boid_instance)
		A_boids.append(A_boid_instance)
		quadtree.insert(A_boid_instance)
		
func spawn_D_Boid(num : int):
	#生成delta boid
	for i in range(num):
		if D_boids.size() >= max_D_boid_num:
			break
		var D_boid_instance = DELTABOID.instantiate()
		D_boid_instance.position = Vector2(randi() % int(screen_rect.size.x), randi() % int(screen_rect.size.y))
		add_child(D_boid_instance)
		D_boids.append(D_boid_instance)
		quadtree.insert(D_boid_instance)
		D_boid_instance.D_boid_die.connect(_on_D_boid_die)
		D_boid_instance.player_caught_D_boid.connect(_on_player_caught_D_boid)
		
#通过boids[]遍历所有boid，set target，apply behavios，并切换游戏状态
func _physics_process(delta: float) -> void:
	for B_boid in B_boids:
		B_boid.set_target(get_global_mouse_position())
		B_boid.apply_behaviors(delta, quadtree)
		
	for A_boid in A_boids:
		A_boid.set_target(get_global_mouse_position())
		A_boid.apply_behaviors(delta, quadtree)
		
	for D_boid in D_boids:
		D_boid.set_target(get_global_mouse_position())
		D_boid.apply_behaviors(delta, quadtree)
		
	if is_game_start and $Player.is_player_dead(quadtree):
		is_game_start = false
		is_game_over = true
		game_over()
		

#连接ScoreTimer信号
func _time_increase() -> void:
	time += 1
	time_label.text = "Time : " + str(time)

#连接StartButton信号
func _game_start() -> void:
	if is_game_start == false:
		is_game_start = true
		game_label.visible = false
		score_timer.start()
		D_boid_timer.start()
		
		
func game_over():
	game_over_label.visible = true
	score_timer.stop()
	D_boid_timer.stop()
	$GameOverSound.play()
	if score > highest_score:
		highest_score = score
		high_score_label.text = "New Record : " + str(highest_score) + " Score!!!"
		$CanvasLayer/GameOverLabel/FireworkUp.visible = true
		$CanvasLayer/GameOverLabel/FireworkBlast.visible = true
	else:
		high_score_label.text = "Highest Score : "+ str(highest_score)
		$CanvasLayer/GameOverLabel/FireworkUp.visible = false
		$CanvasLayer/GameOverLabel/FireworkBlast.visible = false

#连接RestartButton信号
func _restart_game() -> void:
	$Player.is_dead = false
	is_game_over = false
	is_game_start = true
	game_over_label.visible = false
	score = 0
	score_label.text = "Score : 0"
	time = 0
	time_label.text = "Time : 0"
	score_timer.start()
	#重新加载Delta Boid
	for D_boid in D_boids:
		D_boids.erase(D_boid)
		quadtree.remove(D_boid)
		D_boid.queue_free()
	spawn_D_Boid(D_num)
	D_boid_timer.start()

#连接D boid spawn Timer的timeout信号
func _on_dboid_spawn_timer_timeout() -> void:
	spawn_D_Boid(1)

#连接boid.gd中D_boid_die信号
func _on_D_boid_die(emitter:Node):
	D_boids.erase(emitter)

func _on_player_caught_D_boid():
	score += 1
	score_label.text = "Score : " + str(score)
	score_increas_label.visible = true
	await get_tree().create_timer(1).timeout
	score_increas_label.visible = false
