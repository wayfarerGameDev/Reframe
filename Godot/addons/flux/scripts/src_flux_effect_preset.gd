class_name FluxEffectPreset extends Resource

# Properties
@export var name : StringName 
@export_group("Uniforms")
@export var uniforms : Array
@export_group("World")
@export var world_resolution : Vector2i = Vector2i(256,256)
@export var world_alpha: float = 1
@export_group("Code")
@export_multiline var functions : String = ""
@export_multiline var main : String = ""
@export_group("Settings")
@export var domain: FluxComputeShader.Domain
@export var target_compositor_mode : FluxEffectNode.TargetCompositorMode
