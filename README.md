# gLTF Hot Reloading

Hot reloading of GLTF scenes at runtime (even outside Godot project).

Supports `.glb`, `.gltf` and `.gltf + dependencies`.

## How to use:

Add a `SceneReloader` to your project, and fill in `target_nodes` with the nodes to swap when the file changes on disk.  
Also select a file to watch for in `file`.

## Installing:

Add the addon to your Godot Project's addon folder, with the same directory structure you see here on this repo.

## Known Issues:

> ! Godot 4.1 has a bug where exported nodes will lose their reference if they point to an inherited scene that was reimported on disk.
>
> For that, I added a `target_node_paths` which keep their reference even as the scene is reimported.
>
> When this bug is fixed on Godot, `target_node_paths` will become obsolete.
