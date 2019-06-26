# 3D Trail addon for Godot

![trail](https://thumbs.gfycat.com/DependentRaggedAmericancrocodile-small.gif)

## Notes

+ This addon is still a work in progress and not production ready, some things will change a lot
+ Initialy developped for my game (codenamed GlassMainframe, hence the "gm" prefix)
+ Feel free to fork it and reuse what you can.

## Overview

Add 3D trail custom node for Godot Engine
+ Dynamically created at runtime
+ Resolution can be changed (Lower value means higher vertex count)
+ It's just a mesh so you can apply your own materials on it

## How to use
+ Go to **Project settings > Plugins** and activate the **Trail** plugin
+ Add a **Trail** node to your scene
+ Add two Spatial nodes named **Top** and **Bottom** to your trail

You should have a setup similar to this :

![trail_setup_1](https://user-images.githubusercontent.com/52043844/59978520-56517200-95dd-11e9-9b4f-ab4428f811df.PNG)

+ The **Top** and **Bottom** nodes defines the width of the trail. When these nodes move through space, the trail is generated between them
+ The LifeTime parameter defines how long the trail is. Higher value means a longer trail

## Roadmap
+ Replace the **Top** / **Bottom** nodes by single 3D path node to be cleaner and more flexible
+ Add more parameters to change the trail shape over time
+ Fix issues
