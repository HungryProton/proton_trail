# ProtonTrail - 3D Trail addon for Godot

![trail](https://thumbs.gfycat.com/DependentRaggedAmericancrocodile-small.gif)


## Overview

+ 3D trail custom node for Godot Engine
+ Generated at runtime
+ Adjustable resolution
+ It's just a mesh so you can apply your own materials on it

## How to use
+ Clone the repository to your `addons` folder
+ Go to `Project settings > Plugins` and activate the **ProtonTrail** plugin
+ Add a **ProtonTrail** node to your scene
  - It should automatically create two new child nodes `Top` and `Bottom`
+ You should have a setup similar to this :

![trail_setup_1](https://user-images.githubusercontent.com/52043844/59978520-56517200-95dd-11e9-9b4f-ab4428f811df.PNG)

+ The `Top` and `Bottom` nodes define the width of the trail. When these nodes move through space, the trail is generated between them.

### Parameters
+ `Resolution`
  - Defines the geometry density.
  - Higher values means more vertices generated when the emitter moves.
  - Reasonable values are roughly between 6 and 15.
+ `LifeTime`
  - Defines how long the trail is.
  - Higher values means a longer trail.
+ `Smooth`
  - How much smoothing to apply to the trail.
  - Set it to 0 to disable it.
  - This is especially usefull on fast moving objects.
+ `Invert UV X`
  - Flip the UV coordinates on the X axis.
  - By default, the left side of the texture is where the trail emitter is.
+ `Invert UV Y`
  - Flip the UV coordinates on the Y axis.
+ `Emit`
  - Generates a trail when the emitter moves.
  - If disabled, all previously generated trails will still be rendered, but no new geometry will be generated

