extends Node
class_name DlgTree


@export_multiline var text: Array[String] = []
@export var accept_txt := ""
@export var accept_tree: DlgTree = null
@export var decline_txt := ""
@export var decline_tree: DlgTree = null
@export var escapable := true
@export var cost := 0
@export var unaffordable_tree: DlgTree = null


enum Affected {
	NONE,
	CRIT,
	MONEY,
	VAMP_SPECIAL,
	KEY
}

@export var affected := Affected.NONE
@export var addition := 1.0

@export var destroy_on_end := false


func _should_destroy_on_end() -> bool:
	var n := self
	while n:
		if n.destroy_on_end:
			return true
		var p = n.get_parent()
		if not (p is DlgTree):
			return false
		n = p
	return false


func on_end():
	pass


func _on_text_end():
	var can_destroy := true
	if accept_txt != "" and decline_txt != "":
		can_destroy = false
		BinaryChoiceManager.prompt(
			accept_txt,
			decline_txt,
			accept_tree.activate if accept_tree else _empty,
			decline_tree.activate if decline_tree else _empty
		)
	else:
		for c in get_children():
			if c is DlgTree and c != accept_tree and c != decline_tree and c != unaffordable_tree:
				c.activate()
				can_destroy = false
				break
	match affected:
		Affected.CRIT:
			Global.session.upgrades.crit_chance += int(addition)
		Affected.MONEY:
			Global.session.saved_data.money += int(addition)
		Affected.KEY:
			Global.session.saved_data.keys += int(addition)
		Affected.VAMP_SPECIAL:
			Refs.level_manager.player._take_damage(1)
			Global.session.upgrades.set_weapon_upgrade(Global.Weapon.HALBERD)
			Global.session.upgrades.raise_dmg_die(1)
			if Refs.level_manager.player.health.value > 0:
				Global.session.upgrades.max_health -= 1
	on_end()
	if _should_destroy_on_end() and can_destroy:
		var n = self
		while n:
			var p := n.get_parent()
			if not p:
				Global.session.saved_data.object_flags.set(Refs.level_manager.get_unique_name(n), true)
				n.queue_free()
				break
			if not (p is DlgTree):
				Global.session.saved_data.object_flags.set(Refs.level_manager.get_unique_name(p), true)
				p.queue_free()
				break
			n = p


func _empty(): return


func activate():
	if cost > 0:
		if Global.session.saved_data.money >= cost:
			Global.session.saved_data.money -= cost
		else:
			if unaffordable_tree:
				unaffordable_tree.activate()
			return
	if text.size() > 0:
		MessageDisplayer.display(text, _on_text_end, escapable)
	else:
		_on_text_end()
