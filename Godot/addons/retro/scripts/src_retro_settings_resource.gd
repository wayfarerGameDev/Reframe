class_name RetroSettingsResource extends Resource

enum ResolutionMode { Internal, Postprocessing }
enum ResolutionAspectMode { Keep, Expand }
enum VertexJitterMode { ClipSpace, ViewSapce }
enum FogMode { None, ObjectVertex, ObjectPixel, Postprocessing }
enum LightMode { None, ObjectVertex, ObjectPixel }
enum Mode { None, Object, Postprocessing }

@export_group("Shader")
@export var post_processing_shader: Shader = preload("res://addons/retro/shaders/sdr_retro_post_process.gdshader")
@export_group("Resolution")
@export var resolution_mode : ResolutionMode = ResolutionMode.Internal
@export var resolution_aspect_mode : ResolutionAspectMode = ResolutionAspectMode.Expand
@export var resolution : Vector2i = Vector2i(320, 240)
@export_group("Texture")
@export var texture_affine_mapping_strength : float = 1
@export var texture_masking_threshold : float = 0.5
@export_group("Color")
@export var color_quantization_mode : Mode = Mode.Object;
@export var color_quantization_depth : float = 31.0
@export var color_palette_texture : Texture2D = null
@export var color_palette_contrast : float = 1.0
@export var color_palette_brightness : float = 1.0
@export_group("Dithiring")
@export var dithering_mode : Mode = Mode.Object;
@export var dithering_matrix_texture: Texture2D = preload("res://addons/retro/textures/tex_retro_dither_matrix_ps1_normalized_4x4.png")
@export var dithering_strength : float = 1
@export_group("Vertex")
@export var vertex_jitter_mode : VertexJitterMode = VertexJitterMode.ClipSpace
@export var vertex_jitter_strength : float = 15
@export var vertex_z_fighting_reduction : float = 0
@export_group("Fog")
@export var fog_mode : FogMode = FogMode.None;
@export var fog_color : Color = Color.WHITE
@export var fog_start_end_distance : Vector2 = Vector2(1,30)
@export var fog_depth_precision : float = 2048.0
@export_group("Lighting")
@export var light_mode : LightMode = LightMode.ObjectVertex
@export var light_directional_direction : Vector3 = Vector3(-0.147,0.794,0.59);
@export var light_directional_intensity : float = 100000000.0;
@export var light_directional_color : Color = Color.BLACK;
