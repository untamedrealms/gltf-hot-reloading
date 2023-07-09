extends Node3D

func _init():
	print('Instanced!')
	print(is_inside_tree())

func _process(_delta):
	rotate(Vector3.UP, 1 * _delta)
