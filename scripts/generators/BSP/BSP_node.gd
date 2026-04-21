class_name BSPNode
extends Node

var rect: Rect2i
var left: BSPNode = null
var right: BSPNode = null
var room: Rect2i

func _init(rect: Rect2i) -> void:
	self.rect = rect
	
