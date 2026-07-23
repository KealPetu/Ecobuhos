class_name InventoryComponent
extends Node

## Manages Jimmy's waste bag (capacity-limited inventory)

signal item_added(waste_type: String, count: int)
signal item_removed(waste_type: String)
signal inventory_full()

@export var capacity: int = 5
var items: Array[String] = []

func add_item(waste_type: String) -> bool:
	if items.size() >= capacity:
		inventory_full.emit()
		return false
	items.append(waste_type)
	item_added.emit(waste_type, items.size())
	return true

func remove_item(waste_type: String) -> bool:
	var index = items.find(waste_type)
	if index != -1:
		items.remove_at(index)
		item_removed.emit(waste_type)
		return true
	return false

func get_count() -> int:
	return items.size()

func is_full() -> bool:
	return items.size() >= capacity

func has_item(waste_type: String) -> bool:
	return items.has(waste_type)

func clear() -> void:
	items.clear()

func peek_first() -> String:
	if items.is_empty():
		return ""
	return items[0]
