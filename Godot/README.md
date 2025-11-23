# PS1 Shader For Godot

By Acerola

This retro PSX shader is pretty much ready to use for Godot but contains comments explaining the shader code for those wanting to reference it. This shader lacks some conveniences of the Godot engine in favor of making it more easily usable, such as no global shader variables. For someone looking to make their own PSX shader in Godot consider making uniform variables like the dither, light, and fog settings global otherwise you're going to have a bad time constantly modifying a ton of different material values to make everything match. Alternatively these things could be done as a post processing effect rather than in the material shader.

For a deeper explanation of the shader please watch my [video](https://youtu.be/y84bG19sg6U) on the subject

## Features

- Affine Texture Mapping
- Integer Clip Space Coordinates (Pixel Snapping)
- Y-Axis Billboarding
- Texturing
- Flat Shading
- Gouraud Shading
- Optional Dynamic Light
- Linear Distance Fog
- 15-bit PSX Dither and Quantization

![example](./Examples/example.png)