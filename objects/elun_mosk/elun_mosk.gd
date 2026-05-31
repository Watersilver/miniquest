extends Node2D

@onready var dlg_tree: DlgTree = %DlgTree
@onready var yes: DlgTree = %Yes
@onready var no_money: DlgTree = %NoMoney
@onready var no: DlgTree = %No
@onready var final_no: DlgTree = %FinalNo
@onready var alt_intro: DlgTree = %AltIntro
@onready var alt_dlg: Node = %AltDlg
@onready var npc: Npc = %Npc
@onready var elun_face: AnimatedSprite2D = %ElunFace
@onready var elun_face_size_manager: Node2D = %ElunFaceSizeManager
@onready var grave: Sprite2D = %Grave

@export var deny_times := 3

var headsplosion := 0
var timer := 0.0


func _payday_for_elun() -> void:
	if Global.session.saved_data.money == 400:
		print("Down the drain")
	Global.session.saved_data.money = 0


func _elun_denied() -> void:
	Global.session.saved_data.elun_denied_times += 1


func _introduced() -> void:
	Global.session.saved_data.object_flags['elun_introduced'] = true
	_alter_dlg()


func _alter_dlg() -> void:
	dlg_tree.reparent(alt_dlg)
	for c in dlg_tree.get_children():
		c.reparent(alt_intro)
	alt_intro.reparent(npc)


func _elun_headsplode() -> void:
	Global.session.saved_data.object_flags['elun_headsplode'] = true
	elun_face.visible = true
	headsplosion = 1


func _ready() -> void:
	if npc.is_destroyed():
		if Global.session.saved_data.object_flags.has('elun_headsplode') and Global.session.saved_data.object_flags['elun_headsplode']:
			elun_face_size_manager.queue_free()
			grave.visible = true
		else:
			queue_free()
	else:
		grave.queue_free()
		dlg_tree.end.connect(_introduced)
		yes.end.connect(_payday_for_elun)
		no.end.connect(_elun_denied)
		final_no.end.connect(_elun_headsplode)
		if Global.session.saved_data.object_flags.has('elun_introduced') and Global.session.saved_data.object_flags['elun_introduced']:
			_alter_dlg()


func _process(delta: float) -> void:
	var d: DlgTree = alt_intro if Global.session.saved_data.object_flags.has('elun_introduced') and Global.session.saved_data.object_flags['elun_introduced'] else dlg_tree
	if is_instance_valid(d):
		if Global.session.saved_data.money < 1:
			d.accept_tree = no_money
		else:
			d.accept_tree = yes
		
		if Global.session.saved_data.elun_denied_times < deny_times - 1:
			d.decline_tree = no
		else:
			d.decline_tree = final_no
	
	#if is_instance_valid(npc):
		#elun_face.flip_h = true if npc.scale.x > 0 else false
	
	match headsplosion:
		1:
			elun_face_size_manager.scale += 4 * delta * (Vector2(1, 1) - elun_face_size_manager.scale)
			if timer > 2:
				headsplosion = 2
				elun_face.play()
			timer += delta
