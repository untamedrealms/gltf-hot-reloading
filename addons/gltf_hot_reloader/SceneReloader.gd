extends Node
class_name SceneReloader

## Class for hot reloading a scene resource that changed on disk.

signal scene_changed_on_disk
signal scene_reloaded

## The nodes to replace when the scene file changes.
@export var target_nodes : Array[Node]
## The path to the file to watch for.
@export_global_file() var file : String

var _cooling_down : bool = false
var _waiting_to_reload : bool = false

var _dir_watcher

func _ready() -> void:
	process_priority = 1024

	# Disable hot reload functionality on Release to free memory.
	if (ProjectSettings.get_setting(&'editor_tools/hot_reload/enabled') or false) == false:
		queue_free()
		return

	start_watching(
		file
	)

func _print(m,n="",o="",p="",q=""):
	#print(m,n,o,p,q)
	pass

## Set the file this [SceneReloader] will be watching for changes.
func set_scene_file(file : String) -> void:
	self.file = file
	start_watching(file)
	reload()

func register_node_to_update(node : Node):
	target_nodes.push_back(node)

## Start watching for the file events in the directory.
func start_watching(file : String) -> void:
	_print('[DEBUG] Watching ', file, ' for hot reload.')

	stop_watching()

	_dir_watcher = DirectoryWatcher.new()
	_dir_watcher.add_scan_directory(file.get_base_dir())

	add_child(_dir_watcher)
	_dir_watcher.files_modified.connect(_dir_watcher_any_file_modified)
	_dir_watcher.files_created.connect(_dir_watcher_any_file_modified)
	_dir_watcher.files_deleted.connect(_dir_watcher_any_file_modified)

func stop_watching():
	if _dir_watcher:
		_dir_watcher.queue_free()

func _dir_watcher_any_file_modified(files : Array) -> void:
	if not file:
		push_warning('scene can\'t be hot reloaded as its not saved on disk.')

	for modified_file in files:
		if modified_file == file:
			_print('[DEBUG] scene modified: ', modified_file, '. Reloading!')
			scene_changed_on_disk.emit()
			reload()

func _dir_watcher_any_file_created(files : Array) -> void:
	for created_file in files:
		if created_file == file:
			scene_changed_on_disk.emit()
			reload()

func _dir_watcher_any_file_deleted(files : Array) -> void:
	for deleted_file in files:
		if deleted_file == file:
			scene_changed_on_disk.emit()
			push_error('File deleted on disk: ', file)

## Reloads the relevant data to update the target node.
func reload() -> void:
	## If cooling down, ask to reload when the cooldown finishes.
	if _cooling_down:
		_waiting_to_reload = true
		return

	if not target_nodes:
		push_error('No target nodes assigned for this hot reloader: {name}.'.format({
			"name": name
		}))
		return

	var new_scene = _get_new_scene()

	
	for index in target_nodes.size():
		apply_change_on_node(target_nodes[index], new_scene, index)
	
	## Cool down to avoid reloading a resource too much.
	## TODO: Decide whether to have special cooldowns or not.
	#cool_down(ProjectSettings.get_setting(&'editor_tools/hot_reload/rate_limiter_cooldown') or 1.0)
	
	if new_scene:
		scene_reloaded.emit()
	else:
		push_warning('Loaded resource was null: ', file, '.')

func _get_new_scene() -> Node:
	if file.get_extension() in ['glb', 'gltf']:
		return _get_new_scene_gLTF()
	
	push_error('Unrecognized extension for file ' + file + '.')
	return null

func _get_new_scene_gLTF() -> Node:
	var new_document = GLTFDocument.new()
	var new_state = GLTFState.new()

	var f := FileAccess.open(file, FileAccess.READ)
	if f == null:
		push_error('File could not be loaded: ' + file + ' because ' + str(f.get_open_error()) + '.')

	new_document.append_from_file(file, new_state, 0, file.get_base_dir())
	var new_node = new_document.generate_scene(new_state)

	return new_node

## Replaces the node with the newly loaded GLTF document.
func apply_change_on_node(node : Node3D, new_scene : Node3D, index : int):
	node.add_sibling(new_scene)
	new_scene.script = node.script
	new_scene.transform = node.transform
	node.queue_free()
	target_nodes[index] = new_scene
